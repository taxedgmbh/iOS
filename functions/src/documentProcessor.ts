/**
 * Document processor using OpenAI GPT-4 Vision
 *
 * Analyzes Swiss tax documents and classifies them into categories
 */

import OpenAI from "openai";
import { Bucket } from "@google-cloud/storage";

// Initialize OpenAI client
// API key must be set in environment: firebase functions:config:set openai.key="sk-..."
const openaiApiKey = process.env.OPENAI_API_KEY || "";

if (!openaiApiKey) {
  console.warn("⚠️  OPENAI_API_KEY not set - document processing will fail!");
}

const openai = new OpenAI({
  apiKey: openaiApiKey,
});

export interface ProcessingResult {
  category: string;
  subcategory: string;
  confidence: number;
  extractedText: string;
  summary: string;
  amount?: number;
}

/**
 * Process a tax document using OpenAI GPT-4 Vision
 * @param bucket Firebase Storage bucket
 * @param filePath Path to file in storage (e.g., documents/userId/file.jpg)
 * @returns Processing results with category, confidence, etc.
 */
export async function processDocument(
  bucket: Bucket,
  filePath: string
): Promise<ProcessingResult> {
  console.log(`📥 Downloading document: ${filePath}`);

  // Download image from Firebase Storage
  const file = bucket.file(filePath);
  const [fileBuffer] = await file.download();
  const base64Image = fileBuffer.toString("base64");
  const fileSizeKB = (fileBuffer.length / 1024).toFixed(2);

  console.log(`✅ Downloaded ${fileSizeKB} KB`);
  console.log(`🤖 Sending to OpenAI GPT-4 Vision...`);

  // Send to OpenAI GPT-4 Vision
  const response = await openai.chat.completions.create({
    model: "gpt-4-vision-preview",
    messages: [
      {
        role: "system",
        content: `Du bist ein Schweizer Steuerexperte. Analysiere Steuerdokumente und klassifiziere sie in Kategorien.

WICHTIG: Antworte NUR mit einem gültigen JSON-Objekt, keine zusätzlichen Erklärungen.

Kategorien:
- income: Lohnausweis, Honorarnoten, Kapitalerträge, Dividenden
- deduction: Berufsauslagen, Spenden, Krankheitskosten, Weiterbildung
- pillar: Säule 2 (BVG), Säule 3a/3b Einzahlungen
- wealth: Vermögensverzeichnis, Bankkonten, Wertschriften, Immobilien

Unterkategorien:
- salary, freelance, investment, dividend (für income)
- professional, charitable, medical, education (für deduction)
- pillar2, pillar3a, pillar3b (für pillar)
- property, securities, bank_account (für wealth)

Antworte mit JSON:
{
  "category": "income|deduction|pillar|wealth",
  "subcategory": "salary|freelance|etc",
  "confidence": 0.95,
  "extractedText": "Vollständiger Text aus dem Dokument",
  "summary": "Kurze Zusammenfassung auf Deutsch (max 100 Wörter)",
  "amount": 85000 (Betrag falls vorhanden, sonst null)
}`,
      },
      {
        role: "user",
        content: [
          {
            type: "image_url",
            image_url: {
              url: `data:image/jpeg;base64,${base64Image}`,
              detail: "high",
            },
          },
          {
            type: "text",
            text: "Klassifiziere dieses Schweizer Steuerdokument. Antworte NUR mit JSON.",
          },
        ],
      },
    ],
    max_tokens: 1500,
    temperature: 0.2, // Lower temperature for more consistent categorization
  });

  const content = response.choices[0].message.content || "{}";

  console.log(`✅ OpenAI response received`);
  console.log(`📝 Response: ${content.substring(0, 200)}...`);

  // Parse JSON response
  let result: ProcessingResult;

  try {
    // Remove markdown code blocks if present
    const jsonMatch = content.match(/```json\s*([\s\S]*?)\s*```/) ||
                      content.match(/```\s*([\s\S]*?)\s*```/);
    const jsonString = jsonMatch ? jsonMatch[1] : content;

    result = JSON.parse(jsonString.trim());

    // Validate required fields
    if (!result.category || !result.confidence || !result.summary) {
      throw new Error("Missing required fields in AI response");
    }

    console.log(`✅ Successfully parsed AI response`);

  } catch (parseError) {
    console.error("❌ Failed to parse OpenAI response:", parseError);
    console.error("Raw content:", content);

    // Fallback: return uncategorized with low confidence
    result = {
      category: "uncategorized",
      subcategory: "unknown",
      confidence: 0.3,
      extractedText: content,
      summary: "Dokument konnte nicht automatisch klassifiziert werden. Bitte manuell überprüfen.",
    };
  }

  return result;
}
