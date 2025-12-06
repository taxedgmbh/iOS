#!/usr/bin/env node
/**
 * Update Bern (BE) Tax Indexes with Legal Metadata
 * Updates existing BE indexes in Firebase with complete legal research
 */

const https = require('https');
const fs = require('fs');
const legalMetadataBern = require('./legal_metadata_bern_indexes.js');

// Configuration
const PROJECT_ID = 'taxedgmbh';
const DATABASE_ID = 'taxedgmbh';
const COLLECTION = 'taxIndexes';
const TAX_YEAR = 2024;
const CANTON = 'BE';

// Get Firebase token
function getFirebaseToken() {
  try {
    const configPath = require('os').homedir() + '/.config/configstore/firebase-tools.json';
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    return config.tokens.access_token;
  } catch (e) {
    console.error('❌ Error reading Firebase token:', e.message);
    console.error('Run: firebase login --reauth');
    process.exit(1);
  }
}

// Convert to Firestore fields format
function convertToFirestoreFields(data) {
  const fields = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined || value === '') {
      continue;
    }
    if (typeof value === 'number') {
      fields[key] = { integerValue: String(value) };
    } else {
      fields[key] = { stringValue: String(value) };
    }
  }
  return fields;
}

// Update document in Firestore via HTTPS
function updateFirestoreDocument(token, docId, updateFields) {
  return new Promise((resolve, reject) => {
    const path = `/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${COLLECTION}/${docId}`;

    const fields = convertToFirestoreFields(updateFields);
    const payload = JSON.stringify({ fields });

    const options = {
      hostname: 'firestore.googleapis.com',
      port: 443,
      path: path,
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function updateBernLegalMetadata() {
  console.log('='.repeat(70));
  console.log('Updating Bern (BE) Tax Indexes with Legal Metadata');
  console.log('='.repeat(70));
  console.log();

  const token = getFirebaseToken();
  console.log('✅ Firebase token retrieved');
  console.log();

  const indexes = Object.keys(legalMetadataBern);
  console.log(`📋 Found ${indexes.length} indexes with legal metadata`);
  console.log();

  let successCount = 0;
  let errorCount = 0;

  for (const indexNo of indexes) {
    const metadata = legalMetadataBern[indexNo];
    const docId = `${CANTON}_${indexNo}_${TAX_YEAR}`;

    try {
      process.stdout.write(`[Updating] ${docId}... `);

      // Update document with legal metadata
      const updateFields = {
        Legal_Reference_Canton: metadata.Legal_Reference_Canton,
        Legal_Reference_Federal: metadata.Legal_Reference_Federal,
        Rational_Explanation: metadata.Rational_Explanation,
        Deductibility_Rules: metadata.Deductibility_Rules,
        Max_Deductible: metadata.Max_Deductible,
        Limitations: metadata.Limitations,
        Source: metadata.Source,
        Source_Document: metadata.Source_Document,
        Verification_Status: metadata.Verification_Status
      };

      await updateFirestoreDocument(token, docId, updateFields);

      console.log('✅');
      successCount++;

    } catch (error) {
      console.log(`❌ ${error.message.substring(0, 50)}`);
      errorCount++;
    }
  }

  console.log();
  console.log('='.repeat(70));
  console.log(`✅ Successfully updated ${successCount} indexes`);
  if (errorCount > 0) {
    console.log(`❌ Errors: ${errorCount}`);
  }
  console.log('='.repeat(70));
  console.log();
  console.log('Verify at:');
  console.log('https://console.firebase.google.com/project/taxedgmbh/firestore/databases/taxedgmbh/data/~2FtaxIndexes');
  console.log();

  process.exit(errorCount > 0 ? 1 : 0);
}

// Run the update
updateBernLegalMetadata()
  .catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
