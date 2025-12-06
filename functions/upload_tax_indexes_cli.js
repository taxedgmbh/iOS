#!/usr/bin/env node

/**
 * Script to upload tax index data from CSV to Firestore using Firebase CLI authentication
 * This uploads the canton-specific tax index mappings used by the app
 */

const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parse/sync');

// Initialize Firebase Admin SDK with application default credentials
// This will use the Firebase CLI authentication
admin.initializeApp({
  projectId: 'taxedgmbh'
});

const db = admin.firestore();

// Function to parse and upload CSV data
async function uploadTaxIndexData() {
  try {
    // Read CSV file
    const csvPath = '/Users/emanuelflury/Downloads/MASTER_TAX_INDEX_DB.csv';
    const fileContent = fs.readFileSync(csvPath, 'utf-8');

    // Parse CSV
    const records = csv.parse(fileContent, {
      columns: true,
      skip_empty_lines: true
    });

    console.log(`📊 Found ${records.length} total records in CSV`);

    // Filter for SO canton records
    const soRecords = records.filter(record => record.Canton === 'SO');
    console.log(`🎯 Found ${soRecords.length} SO canton records`);

    // Upload in smaller batches to avoid timeouts
    let successCount = 0;

    for (const record of soRecords) {
      // Skip header/invalid rows
      if (record.Index === 'Index No.') continue;

      try {
        // Create document ID: Canton_Index
        const docId = `${record.Canton}_${record.Index}`;
        const docRef = db.collection('taxIndexes').doc(docId);

        // Prepare document data - matching the structure expected by TaxIndexService
        const docData = {
          // Fields for query matching (camelCase)
          canton: record.Canton,
          index: record.Index,
          mainCategory: record.Main_Category || '',
          subcategory: record.Sub_Category || '',
          person: record.Person || '',

          // Keep original field names for compatibility
          Canton: record.Canton,
          Index: record.Index,
          Main_Category: record.Main_Category || '',
          Sub_Category: record.Sub_Category || '',
          Person: record.Person || '',

          // Descriptions
          descriptionDE: record.Description_DE || '',
          descriptionFR: record.Description_FR || '',
          descriptionEN: record.Description_EN || '',
          Description_DE: record.Description_DE || '',
          Description_FR: record.Description_FR || '',
          Description_EN: record.Description_EN || '',

          // Field definitions
          field1NameDE: record.Field1_Name_DE || '',
          field1Type: record.Field1_Type || '',
          field1Required: record.Field1_Required === 'Yes',
          Field1_Name_DE: record.Field1_Name_DE || '',
          Field1_Type: record.Field1_Type || '',
          Field1_Required: record.Field1_Required === 'Yes',

          field2NameDE: record.Field2_Name_DE || '',
          field2Type: record.Field2_Type || '',
          field2Required: record.Field2_Required === 'Yes',
          Field2_Name_DE: record.Field2_Name_DE || '',
          Field2_Type: record.Field2_Type || '',
          Field2_Required: record.Field2_Required === 'Yes',

          field3NameDE: record.Field3_Name_DE || '',
          field3Type: record.Field3_Type || '',
          field3Required: record.Field3_Required === 'Yes',
          Field3_Name_DE: record.Field3_Name_DE || '',
          Field3_Type: record.Field3_Type || '',
          Field3_Required: record.Field3_Required === 'Yes',

          field4NameDE: record.Field4_Name_DE || '',
          field4Type: record.Field4_Type || '',
          field4Required: record.Field4_Required === 'Yes',
          Field4_Name_DE: record.Field4_Name_DE || '',
          Field4_Type: record.Field4_Type || '',
          Field4_Required: record.Field4_Required === 'Yes',

          field5NameDE: record.Field5_Name_DE || '',
          field5Type: record.Field5_Type || '',
          field5Required: record.Field5_Required === 'Yes',
          Field5_Name_DE: record.Field5_Name_DE || '',
          Field5_Type: record.Field5_Type || '',
          Field5_Required: record.Field5_Required === 'Yes',

          // Other fields
          currencyRequired: record.Currency_Required === 'Yes',
          fxRequired: record.FX_Required === 'Yes',
          Currency_Required: record.Currency_Required === 'Yes',
          FX_Required: record.FX_Required === 'Yes',

          displayFormula: record.Display_Formula || '',
          Display_Formula: record.Display_Formula || '',

          notes: record.Notes || '',
          Notes: record.Notes || '',

          validationRules: record.Validation_Rules || '',
          Validation_Rules: record.Validation_Rules || '',

          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Upload document
        await docRef.set(docData, { merge: true });
        successCount++;
        console.log(`✅ Uploaded: ${docId} - ${record.Sub_Category || record.Main_Category}`);
      } catch (err) {
        console.error(`❌ Failed to upload ${record.Canton}_${record.Index}:`, err.message);
      }
    }

    console.log(`\n✅ Successfully uploaded ${successCount} SO canton tax index records to Firestore!`);

    // Also show some example queries for testing
    console.log('\n📝 Example documents uploaded:');
    console.log('   - SO_100: Main employment (Person 1)');
    console.log('   - SO_101: Main employment (Person 2)');
    console.log('   - SO_300: Securities Income');
    console.log('   - SO_310: Maintenance contributions from divorced/separated spouse');
    console.log('\n🔍 These can now be queried by the TaxIndexService in the app!');

  } catch (error) {
    console.error('❌ Error uploading tax index data:', error);
  } finally {
    process.exit();
  }
}

// Run the upload
console.log('🚀 Starting tax index upload to Firestore (taxedgmbh project)...\n');
uploadTaxIndexData();