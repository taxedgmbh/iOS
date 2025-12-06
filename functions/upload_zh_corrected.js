#!/usr/bin/env node

/**
 * Upload Corrected Zürich Tax Indexes - FIXED SCHEMA
 * Matches app's expected Main_Category and Sub_Category values
 */

const fs = require('fs');
const { execSync } = require('child_process');
const os = require('os');
const path = require('path');

// Project configuration
const PROJECT_ID = 'taxedgmbh';
const DATABASE_ID = 'taxedgmbh';
const COLLECTION = 'taxIndexes';

// Get Firebase access token
function getAccessToken() {
  try {
    const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    return config.tokens.access_token;
  } catch (error) {
    console.error('❌ Error reading Firebase token:', error.message);
    process.exit(1);
  }
}

// Upload via curl
function uploadDocument(accessToken, docId, data) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${COLLECTION}/${docId}`;

  const tempFile = path.join(os.tmpdir(), `firestore-${docId}.json`);
  fs.writeFileSync(tempFile, JSON.stringify(data), 'utf8');

  try {
    const result = execSync(
      `curl -X PATCH "${url}" ` +
      `-H "Authorization: Bearer ${accessToken}" ` +
      `-H "Content-Type: application/json" ` +
      `-d @"${tempFile}" 2>&1`,
      { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 }
    );

    fs.unlinkSync(tempFile);

    if (result.includes('"error"')) {
      throw new Error(result);
    }

    return { success: true, docId };
  } catch (error) {
    if (fs.existsSync(tempFile)) {
      fs.unlinkSync(tempFile);
    }
    throw new Error(`Upload failed: ${error.message}`);
  }
}

// Convert to Firestore fields
function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value === null || value === undefined) continue;
    if (typeof value === 'string') {
      fields[key] = { stringValue: value };
    } else if (typeof value === 'number') {
      fields[key] = { integerValue: value.toString() };
    }
  }
  return fields;
}

// Corrected Zürich tax index data with proper schema
const taxIndexes = [
  // Indexes 100-101: Unselbständige Erwerbstätigkeit - Haupterwerb
  {
    Canton: "ZH", Index: "100", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Unselbständige Erwerbstätigkeit",
    Person: "Person 1",
    Legal_Reference_Canton: "§ 17 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 17 Abs. 1 DBG",
    Rational_Explanation: "Das Einkommen aus unselbständiger Erwerbstätigkeit umfasst sämtliche Bezüge aus einem Arbeitsverhältnis, einschliesslich Lohn, Gehalt, Gratifikationen und geldwerte Vorteile.",
    Deductibility_Rules: "Vollumfänglich steuerbar. Keine direkten Abzüge möglich, jedoch können Berufsauslagen (Ziffer 300-310) separat geltend gemacht werden.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug)",
    Limitations: "Lohnausweis erforderlich. Arbeitgeberbescheinigung muss vorliegen.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 8-10",
    Verification_Status: "verified"
  },
  {
    Canton: "ZH", Index: "101", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Unselbständige Erwerbstätigkeit",
    Person: "Person 2",
    Legal_Reference_Canton: "§ 17 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 17 Abs. 1 DBG",
    Rational_Explanation: "Das Einkommen aus unselbständiger Erwerbstätigkeit umfasst sämtliche Bezüge aus einem Arbeitsverhältnis, einschliesslich Lohn, Gehalt, Gratifikationen und geldwerte Vorteile.",
    Deductibility_Rules: "Vollumfänglich steuerbar. Keine direkten Abzüge möglich, jedoch können Berufsauslagen (Ziffer 300-310) separat geltend gemacht werden.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug)",
    Limitations: "Lohnausweis erforderlich. Arbeitgeberbescheinigung muss vorliegen.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 8-10",
    Verification_Status: "verified"
  },

  // Indexes 102-103: Unselbständige Erwerbstätigkeit - Nebenerwerb
  {
    Canton: "ZH", Index: "102", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Unselbständige Erwerbstätigkeit",
    Person: "Person 1",
    Legal_Reference_Canton: "§ 17 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 17 Abs. 1 DBG",
    Rational_Explanation: "Nebenerwerb bezeichnet zusätzliche Einkünfte aus einem zweiten oder weiteren Arbeitsverhältnis neben dem Haupterwerb. Diese sind ebenfalls vollumfänglich steuerbar.",
    Deductibility_Rules: "Vollumfänglich steuerbar. Berufsauslagen können proportional zum Nebenerwerb geltend gemacht werden.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug)",
    Limitations: "Lohnausweis für jedes Arbeitsverhältnis erforderlich. Beiträge zur Säule 3a können nur bis zum gesetzlichen Maximum geltend gemacht werden.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 8-10",
    Verification_Status: "verified"
  },
  {
    Canton: "ZH", Index: "103", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Unselbständige Erwerbstätigkeit",
    Person: "Person 2",
    Legal_Reference_Canton: "§ 17 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 17 Abs. 1 DBG",
    Rational_Explanation: "Nebenerwerb bezeichnet zusätzliche Einkünfte aus einem zweiten oder weiteren Arbeitsverhältnis neben dem Haupterwerb. Diese sind ebenfalls vollumfänglich steuerbar.",
    Deductibility_Rules: "Vollumfänglich steuerbar. Berufsauslagen können proportional zum Nebenerwerb geltend gemacht werden.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug)",
    Limitations: "Lohnausweis für jedes Arbeitsverhältnis erforderlich. Beiträge zur Säule 3a können nur bis zum gesetzlichen Maximum geltend gemacht werden.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 8-10",
    Verification_Status: "verified"
  },

  // Indexes 120-121: Selbständige Erwerbstätigkeit
  {
    Canton: "ZH", Index: "120", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Selbständige Erwerbstätigkeit",
    Person: "Person 1",
    Legal_Reference_Canton: "§ 18 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 18 Abs. 1 DBG",
    Rational_Explanation: "Das Einkommen aus selbständiger Erwerbstätigkeit umfasst alle Einkünfte aus kaufmännischer, gewerblicher, freiberuflicher oder landwirtschaftlicher Tätigkeit. Es wird der Geschäftsgewinn gemäss Erfolgsrechnung besteuert.",
    Deductibility_Rules: "Steuerbar ist der Geschäftsreingewinn nach kaufmännischer Buchführung. Geschäftsauslagen sind vollumfänglich abzugsfähig, sofern geschäftsmässig begründet.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug). Hinweis: Säule 3a-Beiträge bis CHF 35'280 für Selbständigerwerbende ohne Pensionskasse.",
    Limitations: "Ordnungsgemässe Buchhaltung erforderlich (OR Art. 957). Bei Umsatz >CHF 500'000: Buchführungspflicht. Bilanz und Erfolgsrechnung müssen eingereicht werden.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Merkblatt zum Hilfsblatt A - Geschäftsabrechnung, Kanton Zürich 2024",
    Verification_Status: "verified"
  },
  {
    Canton: "ZH", Index: "121", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Selbständige Erwerbstätigkeit",
    Person: "Person 2",
    Legal_Reference_Canton: "§ 18 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 18 Abs. 1 DBG",
    Rational_Explanation: "Das Einkommen aus selbständiger Erwerbstätigkeit umfasst alle Einkünfte aus kaufmännischer, gewerblicher, freiberuflicher oder landwirtschaftlicher Tätigkeit. Es wird der Geschäftsgewinn gemäss Erfolgsrechnung besteuert.",
    Deductibility_Rules: "Steuerbar ist der Geschäftsreingewinn nach kaufmännischer Buchführung. Geschäftsauslagen sind vollumfänglich abzugsfähig, sofern geschäftsmässig begründet.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug). Hinweis: Säule 3a-Beiträge bis CHF 35'280 für Selbständigerwerbende ohne Pensionskasse.",
    Limitations: "Ordnungsgemässe Buchhaltung erforderlich (OR Art. 957). Bei Umsatz >CHF 500'000: Buchführungspflicht. Bilanz und Erfolgsrechnung müssen eingereicht werden.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Merkblatt zum Hilfsblatt A - Geschäftsabrechnung, Kanton Zürich 2024",
    Verification_Status: "verified"
  },

  // Indexes 130-131: Vorsorge (AHV/IV Renten)
  {
    Canton: "ZH", Index: "130", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Vorsorge",
    Person: "Person 1",
    Legal_Reference_Canton: "§ 22 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 22 Abs. 1 DBG",
    Rational_Explanation: "Renten der AHV/IV sind vollumfänglich als Einkommen zu versteuern. Dies umfasst Altersrenten, Invalidenrenten, Hinterlassenenrenten sowie Ergänzungsleistungen.",
    Deductibility_Rules: "Vollumfänglich steuerbar als Einkommen. Es besteht kein direkter Abzug, jedoch können allgemeine Sozialabzüge (z.B. Rentenabzug für Personen im AHV-Alter) geltend gemacht werden.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug)",
    Limitations: "Rentenausweis der AHV/IV-Stelle erforderlich. Bei ausländischen Renten: Nachweis durch Rentenbescheid der ausländischen Sozialversicherung.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Merkblatt zur Steuerbarkeit von Renten, Kanton Zürich 2024, Seite 2-3",
    Verification_Status: "verified"
  },
  {
    Canton: "ZH", Index: "131", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Vorsorge",
    Person: "Person 2",
    Legal_Reference_Canton: "§ 22 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 22 Abs. 1 DBG",
    Rational_Explanation: "Renten der AHV/IV sind vollumfänglich als Einkommen zu versteuern. Dies umfasst Altersrenten, Invalidenrenten, Hinterlassenenrenten sowie Ergänzungsleistungen.",
    Deductibility_Rules: "Vollumfänglich steuerbar als Einkommen. Es besteht kein direkter Abzug, jedoch können allgemeine Sozialabzüge (z.B. Rentenabzug für Personen im AHV-Alter) geltend gemacht werden.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug)",
    Limitations: "Rentenausweis der AHV/IV-Stelle erforderlich. Bei ausländischen Renten: Nachweis durch Rentenbescheid der ausländischen Sozialversicherung.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Merkblatt zur Steuerbarkeit von Renten, Kanton Zürich 2024, Seite 2-3",
    Verification_Status: "verified"
  },

  // Indexes 140-141: Übrige Einkünfte (Arbeitslosenentschädigung)
  {
    Canton: "ZH", Index: "140", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Übrige Einkünfte",
    Person: "Person 1",
    Legal_Reference_Canton: "§ 22 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 23 lit. a DBG",
    Rational_Explanation: "Taggelder der Arbeitslosenversicherung (ALV) sind vollumfänglich als Einkommen zu versteuern. Dies umfasst sowohl ordentliche Arbeitslosenentschädigungen als auch Kurzarbeitsentschädigungen.",
    Deductibility_Rules: "Vollumfänglich steuerbar als Einkommen. Keine direkten Abzüge möglich. Jedoch können allgemeine Berufsauslagen für Bewerbungen und Weiterbildung separat geltend gemacht werden.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug)",
    Limitations: "Bescheinigung der ALV-Kasse erforderlich. Die Taggelder werden bereits an der Quelle versteuert (Quellensteuer), jedoch muss eine ordentliche Steuererklärung eingereicht werden.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 12-13",
    Verification_Status: "verified"
  },
  {
    Canton: "ZH", Index: "141", Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Übrige Einkünfte",
    Person: "Person 2",
    Legal_Reference_Canton: "§ 22 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 23 lit. a DBG",
    Rational_Explanation: "Taggelder der Arbeitslosenversicherung (ALV) sind vollumfänglich als Einkommen zu versteuern. Dies umfasst sowohl ordentliche Arbeitslosenentschädigungen als auch Kurzarbeitsentschädigungen.",
    Deductibility_Rules: "Vollumfänglich steuerbar als Einkommen. Keine direkten Abzüge möglich. Jedoch können allgemeine Berufsauslagen für Bewerbungen und Weiterbildung separat geltend gemacht werden.",
    Max_Deductible: "Nicht zutreffend (Einkommensposten, kein Abzug)",
    Limitations: "Bescheinigung der ALV-Kasse erforderlich. Die Taggelder werden bereits an der Quelle versteuert (Quellensteuer), jedoch muss eine ordentliche Steuererklärung eingereicht werden.",
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 12-13",
    Verification_Status: "verified"
  }
];

// Main
console.log('==========================================');
console.log('Uploading CORRECTED Zürich Tax Indexes');
console.log('==========================================\n');
console.log('✅ Schema fixed: Main_Category = "Einkommen", Sub_Category matches app expectations\n');

const accessToken = getAccessToken();
console.log('✅ Firebase access token retrieved\n');

let successCount = 0;
let failCount = 0;

for (const index of taxIndexes) {
  const docId = `${index.Canton}_${index.Index}_${index.Tax_Year}`;
  const payload = { fields: toFirestoreFields(index) };

  try {
    process.stdout.write(`[Uploading] ${docId} (${index.Sub_Category})... `);
    uploadDocument(accessToken, docId, payload);
    console.log('✅');
    successCount++;
  } catch (error) {
    console.log('❌');
    failCount++;
  }
}

console.log('\n==========================================');
console.log(`✅ Successfully uploaded ${successCount} corrected tax indexes`);
if (failCount > 0) {
  console.log(`❌ Failed: ${failCount}`);
}
console.log('==========================================\n');

console.log('Verify at:');
console.log(`https://console.firebase.google.com/project/${PROJECT_ID}/firestore/databases/${DATABASE_ID}/data/~2F${COLLECTION}\n`);

process.exit(failCount > 0 ? 1 : 0);
