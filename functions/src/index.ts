/**
 * Firebase Cloud Functions for Taxed GmbH
 *
 * Automatically processes uploaded tax documents using OpenAI GPT-4 Vision
 * for OCR and classification.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { processDocument } from "./documentProcessor";

admin.initializeApp();

/**
 * Triggered when a document is uploaded to Firebase Storage
 * Path: documents/{customerId}/{fileName}
 *
 * Flow:
 * 1. Document uploaded to Storage → this function triggers
 * 2. Downloads document from Storage
 * 3. Sends to OpenAI GPT-4 Vision for OCR + classification
 * 4. Updates Firestore with AI results
 */
export const onDocumentUpload = functions.storage
  .object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;

    // Only process files in documents/ folder
    if (!filePath || !filePath.startsWith("documents/")) {
      console.log(`⏭️  Skipping file (not in documents/): ${filePath}`);
      return;
    }

    // Only process images
    if (!contentType || !contentType.startsWith("image/")) {
      console.log(`⏭️  Skipping non-image file: ${filePath}`);
      return;
    }

    const fileName = filePath.split("/").pop();
    if (!fileName) {
      console.log("⚠️  Invalid file path: no filename");
      return;
    }

    console.log(`🔥 New document uploaded: ${filePath}`);
    console.log(`📄 File: ${fileName}, Type: ${contentType}`);

    try {
      // Find corresponding Firestore document
      const documentsRef = admin.firestore().collection("documents");
      const snapshot = await documentsRef
        .where("name", "==", fileName)
        .where("status", "==", "processing")
        .limit(1)
        .get();

      if (snapshot.empty) {
        console.log("⚠️  No matching Firestore document found");
        console.log(`   Looking for: name=${fileName}, status=processing`);
        return;
      }

      const docRef = snapshot.docs[0].ref;
      const docId = snapshot.docs[0].id;

      console.log(`✅ Found Firestore document: ${docId}`);

      // Get Storage URL
      const bucket = admin.storage().bucket(object.bucket);
      const storageUrl = `gs://${object.bucket}/${filePath}`;

      console.log(`🤖 Starting AI processing...`);

      // Process document with OpenAI
      const result = await processDocument(bucket, filePath);

      console.log(`✅ AI processing complete:`);
      console.log(`   Category: ${result.category}`);
      console.log(`   Subcategory: ${result.subcategory}`);
      console.log(`   Confidence: ${(result.confidence * 100).toFixed(1)}%`);
      console.log(`   Amount: ${result.amount ? `CHF ${result.amount}` : "N/A"}`);

      // Update Firestore with AI results
      await docRef.update({
        category: result.category,
        subcategory: result.subcategory || null,
        aiConfidence: result.confidence,
        extractedText: result.extractedText || null,
        aiSummary: result.summary,
        amount: result.amount || null,
        status: "pending", // Ready for expert review
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Firestore updated successfully`);
      console.log(`📊 Document ready for expert review`);

    } catch (error) {
      console.error("❌ Processing failed:", error);

      // Try to update document status to error if possible
      try {
        const documentsRef = admin.firestore().collection("documents");
        const snapshot = await documentsRef
          .where("name", "==", fileName)
          .limit(1)
          .get();

        if (!snapshot.empty) {
          await snapshot.docs[0].ref.update({
            status: "pending", // Still mark as pending so expert can review
            expertNotes: `AI processing failed: ${error instanceof Error ? error.message : "Unknown error"}`,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      } catch (updateError) {
        console.error("❌ Failed to update error status:", updateError);
      }
    }
  });
