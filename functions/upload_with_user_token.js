#!/usr/bin/env node

/**
 * Upload Zürich Tax Indexes using Firebase CLI user token
 * This script uses the user's Firebase authentication instead of a service account
 */

const fs = require('fs');
const https = require('https');
const os = require('os');
const path = require('path');

// Project configuration
const PROJECT_ID = 'taxedgmbh';
const DATABASE_ID = 'taxedgmbh';
const COLLECTION = 'taxIndexes';

// Get Firebase access token from CLI config
function getAccessToken() {
  try {
    const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

    if (!config.tokens || !config.tokens.access_token) {
      throw new Error('No access token found in Firebase CLI config');
    }

    return config.tokens.access_token;
  } catch (error) {
    console.error('❌ Error reading Firebase token:', error.message);
    console.error('\nPlease ensure you are logged in with: firebase login');
    process.exit(1);
  }
}

// Upload a single document via Firestore REST API
function uploadDocument(accessToken, docId, fields) {
  return new Promise((resolve, reject) => {
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${COLLECTION}/${docId}`;

    // Properly format the payload with clean JSON serialization
    const payload = { fields };
    const data = JSON.stringify(payload);

    const options = {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json; charset=utf-8',
        'Content-Length': Buffer.byteLength(data, 'utf8')
      }
    };

    const req = https.request(url, options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ success: true, docId });
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(data, 'utf8');
    req.end();
  });
}

// Convert JavaScript object to Firestore field format
function toFirestoreFields(obj) {
  const fields = {};

  for (const [key, value] of Object.entries(obj)) {
    if (value === null || value === undefined) continue;

    if (typeof value === 'string') {
      fields[key] = { stringValue: value };
    } else if (typeof value === 'number') {
      if (Number.isInteger(value)) {
        fields[key] = { integerValue: value.toString() };
      } else {
        fields[key] = { doubleValue: value };
      }
    } else if (typeof value === 'boolean') {
      fields[key] = { booleanValue: value };
    } else if (value instanceof Date) {
      fields[key] = { timestampValue: value.toISOString() };
    }
  }

  return fields;
}

// Zürich tax index data (10 pilot entries with fact-based legal references)
const taxIndexes = [
  {
    Canton: "ZH",
    Index: "100",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus unselbständiger Erwerbstätigkeit",
    Sub_Category: "Haupterwerb",
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
    Canton: "ZH",
    Index: "101",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus unselbständiger Erwerbstätigkeit",
    Sub_Category: "Haupterwerb",
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
  {
    Canton: "ZH",
    Index: "102",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus unselbständiger Erwerbstätigkeit",
    Sub_Category: "Nebenerwerb",
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
    Canton: "ZH",
    Index: "103",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus unselbständiger Erwerbstätigkeit",
    Sub_Category: "Nebenerwerb",
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
  {
    Canton: "ZH",
    Index: "120",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus selbständiger Erwerbstätigkeit",
    Sub_Category: "Selbständigerwerbend",
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
    Canton: "ZH",
    Index: "121",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus selbständiger Erwerbstätigkeit",
    Sub_Category: "Selbständigerwerbend",
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
  {
    Canton: "ZH",
    Index: "130",
    Tax_Year: 2024,
    Main_Category: "Übrige Einkünfte",
    Sub_Category: "Renten und Pensionen (AHV/IV)",
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
    Canton: "ZH",
    Index: "131",
    Tax_Year: 2024,
    Main_Category: "Übrige Einkünfte",
    Sub_Category: "Renten und Pensionen (AHV/IV)",
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
  {
    Canton: "ZH",
    Index: "140",
    Tax_Year: 2024,
    Main_Category: "Übrige Einkünfte",
    Sub_Category: "Arbeitslosenentschädigung",
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
    Canton: "ZH",
    Index: "141",
    Tax_Year: 2024,
    Main_Category: "Übrige Einkünfte",
    Sub_Category: "Arbeitslosenentschädigung",
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

// Main upload function
async function uploadAllIndexes() {
  console.log('==========================================');
  console.log('Uploading Zürich Tax Indexes to Firebase');
  console.log('==========================================\n');

  const accessToken = getAccessToken();
  console.log('✅ Firebase access token retrieved\n');

  let successCount = 0;
  let failCount = 0;

  for (const index of taxIndexes) {
    const docId = `${index.Canton}_${index.Index}_${index.Tax_Year}`;
    const fields = toFirestoreFields(index);

    try {
      process.stdout.write(`[Uploading] ${docId}... `);
      await uploadDocument(accessToken, docId, fields);
      console.log('✅ Success');
      successCount++;
    } catch (error) {
      console.log(`❌ Failed: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n==========================================');
  console.log(`Upload Complete: ${successCount} succeeded, ${failCount} failed`);
  console.log('==========================================\n');

  if (successCount > 0) {
    console.log('Verify at:');
    console.log(`https://console.firebase.google.com/project/${PROJECT_ID}/firestore/databases/${DATABASE_ID}/data/~2F${COLLECTION}\n`);
  }

  process.exit(failCount > 0 ? 1 : 0);
}

// Run the upload
uploadAllIndexes().catch(error => {
  console.error('\n❌ Fatal error:', error.message);
  process.exit(1);
});
