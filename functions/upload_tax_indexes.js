#!/usr/bin/env node

/**
 * Script to upload tax index data from CSV to Firestore
 * This uploads the canton-specific tax index mappings used by the app
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const csv = require('csv-parse/sync');

// Initialize Firebase Admin SDK
const serviceAccount = require('/Users/emanuelflury/Downloads/taxedn8n-68fb68c972c9.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
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

    // Prepare batch write
    let batch = db.batch();
    let count = 0;

    for (const record of soRecords) {
      // Skip header/invalid rows
      if (record.Index === 'Index No.') continue;

      // Create document ID: Canton_Index
      const docId = `${record.Canton}_${record.Index}`;
      const docRef = db.collection('taxIndexes').doc(docId);

      // Prepare document data
      const docData = {
        canton: record.Canton,
        index: record.Index,
        mainCategory: record.Main_Category || '',
        subcategory: record.Sub_Category || '',
        person: record.Person || '',
        descriptionDE: record.Description_DE || '',
        descriptionFR: record.Description_FR || '',
        descriptionEN: record.Description_EN || '',
        field1NameDE: record.Field1_Name_DE || '',
        field1Type: record.Field1_Type || '',
        field1Required: record.Field1_Required === 'Yes',
        field2NameDE: record.Field2_Name_DE || '',
        field2Type: record.Field2_Type || '',
        field2Required: record.Field2_Required === 'Yes',
        field3NameDE: record.Field3_Name_DE || '',
        field3Type: record.Field3_Type || '',
        field3Required: record.Field3_Required === 'Yes',
        field4NameDE: record.Field4_Name_DE || '',
        field4Type: record.Field4_Type || '',
        field4Required: record.Field4_Required === 'Yes',
        field5NameDE: record.Field5_Name_DE || '',
        field5Type: record.Field5_Type || '',
        field5Required: record.Field5_Required === 'Yes',
        currencyRequired: record.Currency_Required === 'Yes',
        fxRequired: record.FX_Required === 'Yes',
        displayFormula: record.Display_Formula || '',
        notes: record.Notes || '',
        validationRules: record.Validation_Rules || '',
        // Keep original field names for compatibility
        Canton: record.Canton,
        Index: record.Index,
        Main_Category: record.Main_Category || '',
        Sub_Category: record.Sub_Category || '',
        Person: record.Person || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Add to batch
      batch.set(docRef, docData, { merge: true });
      count++;

      // Firestore has a limit of 500 operations per batch
      if (count % 500 === 0) {
        await batch.commit();
        console.log(`✅ Uploaded ${count} records...`);
        // Start new batch
        batch = db.batch();
      }
    }

    // Commit remaining records
    if (count % 500 !== 0) {
      await batch.commit();
    }

    console.log(`✅ Successfully uploaded ${count} SO canton tax index records to Firestore!`);

    // Also upload AG canton records for testing
    const agRecords = records.filter(record => record.Canton === 'AG');
    console.log(`\n🎯 Found ${agRecords.length} AG canton records`);

    let agBatch = db.batch();
    let agCount = 0;

    for (const record of agRecords) {
      // Skip header/invalid rows
      if (record.Index === 'Index No.') continue;

      // Create document ID: Canton_Index
      const docId = `${record.Canton}_${record.Index}`;
      const docRef = db.collection('taxIndexes').doc(docId);

      // Prepare document data (same structure as SO)
      const docData = {
        canton: record.Canton,
        index: record.Index,
        mainCategory: record.Main_Category || '',
        subcategory: record.Sub_Category || '',
        person: record.Person || '',
        descriptionDE: record.Description_DE || '',
        descriptionFR: record.Description_FR || '',
        descriptionEN: record.Description_EN || '',
        field1NameDE: record.Field1_Name_DE || '',
        field1Type: record.Field1_Type || '',
        field1Required: record.Field1_Required === 'Yes',
        field2NameDE: record.Field2_Name_DE || '',
        field2Type: record.Field2_Type || '',
        field2Required: record.Field2_Required === 'Yes',
        field3NameDE: record.Field3_Name_DE || '',
        field3Type: record.Field3_Type || '',
        field3Required: record.Field3_Required === 'Yes',
        field4NameDE: record.Field4_Name_DE || '',
        field4Type: record.Field4_Type || '',
        field4Required: record.Field4_Required === 'Yes',
        field5NameDE: record.Field5_Name_DE || '',
        field5Type: record.Field5_Type || '',
        field5Required: record.Field5_Required === 'Yes',
        currencyRequired: record.Currency_Required === 'Yes',
        fxRequired: record.FX_Required === 'Yes',
        displayFormula: record.Display_Formula || '',
        notes: record.Notes || '',
        validationRules: record.Validation_Rules || '',
        // Keep original field names for compatibility
        Canton: record.Canton,
        Index: record.Index,
        Main_Category: record.Main_Category || '',
        Sub_Category: record.Sub_Category || '',
        Person: record.Person || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Add to batch
      agBatch.set(docRef, docData, { merge: true });
      agCount++;

      // Firestore has a limit of 500 operations per batch
      if (agCount % 500 === 0) {
        await agBatch.commit();
        console.log(`✅ Uploaded ${agCount} AG records...`);
        // Start new batch
        agBatch = db.batch();
      }
    }

    // Commit remaining AG records
    if (agCount % 500 !== 0) {
      await agBatch.commit();
    }

    console.log(`✅ Successfully uploaded ${agCount} AG canton tax index records to Firestore!`);
    console.log(`\n🎉 Total uploaded: ${count + agCount} tax index records`);

  } catch (error) {
    console.error('❌ Error uploading tax index data:', error);
  } finally {
    process.exit();
  }
}

// Run the upload
uploadTaxIndexData();