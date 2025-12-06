#!/usr/bin/env node

/**
 * Update 77 Tax Indexes with Complete Legal Metadata
 * Updates existing Firebase documents with legal references and explanations
 */

const https = require('https');
const fs = require('fs');
const legalMetadata = require('./legal_metadata_77_indexes.js');

// Configuration
const PROJECT_ID = 'taxedgmbh';
const DATABASE_ID = 'taxedgmbh';
const COLLECTION = 'taxIndexes';

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
      continue; // Skip empty fields
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
function updateFirestoreDocument(token, docId, fields) {
  return new Promise((resolve, reject) => {
    const path = `/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${COLLECTION}/${docId}`;

    const payload = JSON.stringify({ fields });

    const options = {
      hostname: 'firestore.googleapis.com',
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
        try {
          const response = JSON.parse(data);
          if (response.error) {
            reject(new Error(response.error.message || JSON.stringify(response.error)));
          } else {
            resolve(response);
          }
        } catch (e) {
          reject(new Error(`Parse error: ${e.message}`));
        }
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    req.write(payload);
    req.end();
  });
}

// Main upload function
async function main() {
  console.log('='.repeat(70));
  console.log('Updating 77 Tax Indexes with Complete Legal Metadata');
  console.log('='.repeat(70));
  console.log('');

  const token = getFirebaseToken();
  console.log('✅ Firebase token retrieved');
  console.log('');

  const indexes = Object.values(legalMetadata);
  console.log(`📊 Total indexes to update: ${indexes.length}`);
  console.log('');

  let successCount = 0;
  let failCount = 0;
  let skippedCount = 0;

  for (const indexData of indexes) {
    const docId = `ZH_${indexData.Index}_${indexData.Tax_Year}`;

    try {
      process.stdout.write(`[Updating] ${docId} (${indexData.Sub_Category})... `);

      const fields = convertToFirestoreFields(indexData);
      await updateFirestoreDocument(token, docId, fields);

      console.log('✅');
      successCount++;

    } catch (error) {
      const errorMsg = error.message || String(error);
      if (errorMsg.includes('NOT_FOUND') || errorMsg.includes('not found')) {
        console.log('⚠️  (document not found)');
        skippedCount++;
      } else {
        console.log(`❌ ${errorMsg.substring(0, 50)}`);
        failCount++;
      }
    }

    // Small delay to avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  console.log('');
  console.log('='.repeat(70));
  console.log(`✅ Successfully updated: ${successCount} indexes`);
  if (skippedCount > 0) {
    console.log(`⚠️  Skipped (not found): ${skippedCount} indexes`);
  }
  if (failCount > 0) {
    console.log(`❌ Failed: ${failCount} indexes`);
  }
  console.log('='.repeat(70));
  console.log('');
  console.log('Verify at:');
  console.log(`https://console.firebase.google.com/project/${PROJECT_ID}/firestore/databases/${DATABASE_ID}/data/~2F${COLLECTION}`);
  console.log('');

  process.exit(failCount > 0 ? 1 : 0);
}

main().catch((error) => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
