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
const serviceAccount = require('./taxedgmbh-firebase-adminsdk.json');

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
    const batch = db.batch();
    let count = 0;

    for (const record of soRecords) {
      // Skip header/invalid rows
      if (record.Index === 'Index No.') continue;

      // Create document ID: Canton_Index
      const docId = `${record.Canton}_${record.Index}`;
      const docRef = db.collection('taxIndexes').doc(docId);

      // Prepare document data
      const docData = {
        Canton: record.Canton,
        Index: record.Index,
        Main_Category: record.Main_Category || '',
        Sub_Category: record.Sub_Category || '',
        Person: record.Person || '',
        Description_DE: record.Description_DE || '',
        Description_FR: record.Description_FR || '',
        Description_EN: record.Description_EN || '',
        Field1_Name_DE: record.Field1_Name_DE || '',
        Field1_Type: record.Field1_Type || '',
        Field1_Required: record.Field1_Required === 'Yes',
        Field2_Name_DE: record.Field2_Name_DE || '',
        Field2_Type: record.Field2_Type || '',
        Field2_Required: record.Field2_Required === 'Yes',
        Field3_Name_DE: record.Field3_Name_DE || '',
        Field3_Type: record.Field3_Type || '',
        Field3_Required: record.Field3_Required === 'Yes',
        Field4_Name_DE: record.Field4_Name_DE || '',
        Field4_Type: record.Field4_Type || '',
        Field4_Required: record.Field4_Required === 'Yes',
        Field5_Name_DE: record.Field5_Name_DE || '',
        Field5_Type: record.Field5_Type || '',
        Field5_Required: record.Field5_Required === 'Yes',
        Currency_Required: record.Currency_Required === 'Yes',
        FX_Required: record.FX_Required === 'Yes',
        Display_Formula: record.Display_Formula || '',
        Notes: record.Notes || '',
        Validation_Rules: record.Validation_Rules || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Add to batch
      batch.set(docRef, docData);
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

    const agBatch = db.batch();
    let agCount = 0;

    for (const record of agRecords) {
      // Skip header/invalid rows
      if (record.Index === 'Index No.') continue;

      // Create document ID: Canton_Index
      const docId = `${record.Canton}_${record.Index}`;
      const docRef = db.collection('taxIndexes').doc(docId);

      // Prepare document data (same structure as SO)
      const docData = {
        Canton: record.Canton,
        Index: record.Index,
        Main_Category: record.Main_Category || '',
        Sub_Category: record.Sub_Category || '',
        Person: record.Person || '',
        Description_DE: record.Description_DE || '',
        Description_FR: record.Description_FR || '',
        Description_EN: record.Description_EN || '',
        Field1_Name_DE: record.Field1_Name_DE || '',
        Field1_Type: record.Field1_Type || '',
        Field1_Required: record.Field1_Required === 'Yes',
        Field2_Name_DE: record.Field2_Name_DE || '',
        Field2_Type: record.Field2_Type || '',
        Field2_Required: record.Field2_Required === 'Yes',
        Field3_Name_DE: record.Field3_Name_DE || '',
        Field3_Type: record.Field3_Type || '',
        Field3_Required: record.Field3_Required === 'Yes',
        Field4_Name_DE: record.Field4_Name_DE || '',
        Field4_Type: record.Field4_Type || '',
        Field4_Required: record.Field4_Required === 'Yes',
        Field5_Name_DE: record.Field5_Name_DE || '',
        Field5_Type: record.Field5_Type || '',
        Field5_Required: record.Field5_Required === 'Yes',
        Currency_Required: record.Currency_Required === 'Yes',
        FX_Required: record.FX_Required === 'Yes',
        Display_Formula: record.Display_Formula || '',
        Notes: record.Notes || '',
        Validation_Rules: record.Validation_Rules || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Add to batch
      agBatch.set(docRef, docData);
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