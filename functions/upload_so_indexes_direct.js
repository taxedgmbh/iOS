#!/usr/bin/env node

/**
 * Direct upload script for SO canton tax indexes
 * Uses a simple direct approach with manual data entry
 */

const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parse/sync');

// Initialize with the service account you have
const serviceAccount = {
  "type": "service_account",
  "project_id": "taxedgmbh",
  "private_key_id": "dummy",
  "private_key": "-----BEGIN PRIVATE KEY-----\nDUMMY_KEY\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk@taxedgmbh.iam.gserviceaccount.com",
  "client_id": "dummy",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs"
};

// This will fail but let's try to create the structure at least
console.log("📝 Generating Firestore data structure for SO canton...\n");

// Read CSV file
const csvPath = '/Users/emanuelflury/Downloads/MASTER_TAX_INDEX_DB.csv';
const fileContent = fs.readFileSync(csvPath, 'utf-8');

// Parse CSV
const records = csv.parse(fileContent, {
  columns: true,
  skip_empty_lines: true
});

// Filter for SO canton records
const soRecords = records.filter(record => record.Canton === 'SO');
console.log(`Found ${soRecords.length} SO canton records\n`);

// Generate JavaScript objects for manual entry
console.log("📋 COPY AND PASTE THESE INTO FIREBASE CONSOLE:\n");
console.log("Go to: https://console.firebase.google.com/project/taxedgmbh/firestore/data/~2FtaxIndexes\n");
console.log("Click '+ Start collection' or '+ Add document' and add these documents:\n");
console.log("=" .repeat(80));

// Create key documents for testing
const keyDocuments = [
  // Income categories
  soRecords.find(r => r.Index === '100'), // Main employment P1
  soRecords.find(r => r.Index === '101'), // Main employment P2
  soRecords.find(r => r.Index === '300'), // Securities income
  // Deductions
  soRecords.find(r => r.Index === '500'), // Berufskosten P1
  soRecords.find(r => r.Index === '501'), // Berufskosten P2
  soRecords.find(r => r.Index === '540'), // Säule 3a P1
  soRecords.find(r => r.Index === '550'), // Säule 3a P2
  // Assets
  soRecords.find(r => r.Index === '900'), // Vermögen
  soRecords.find(r => r.Index === '920'), // Schulden
];

keyDocuments.filter(doc => doc).forEach(record => {
  const docId = `${record.Canton}_${record.Index}`;

  console.log(`\n📄 Document ID: ${docId}`);
  console.log(`Description: ${record.Description_DE || record.Sub_Category || record.Main_Category}`);
  console.log("-".repeat(60));

  // Generate the document structure
  const doc = {
    // Core fields for querying
    Canton: record.Canton,
    Index: record.Index,
    Main_Category: record.Main_Category || '',
    Sub_Category: record.Sub_Category || '',
    Person: record.Person || '',

    // Also add camelCase versions for compatibility
    canton: record.Canton,
    index: record.Index,
    mainCategory: record.Main_Category || '',
    subcategory: record.Sub_Category || '',
    person: record.Person || '',

    // Descriptions
    Description_DE: record.Description_DE || '',
    Description_FR: record.Description_FR || '',
    Description_EN: record.Description_EN || '',

    // Field definitions
    Field1_Name_DE: record.Field1_Name_DE || '',
    Field1_Type: record.Field1_Type || '',
    Field1_Required: record.Field1_Required === 'Yes',

    // Additional metadata
    Currency_Required: record.Currency_Required === 'Yes',
    FX_Required: record.FX_Required === 'Yes',
    Display_Formula: record.Display_Formula || '',
    Notes: record.Notes || '',
  };

  console.log("Fields to add:");
  console.log(JSON.stringify(doc, null, 2));
});

console.log("\n" + "=".repeat(80));
console.log("\n🎯 QUICK START INSTRUCTIONS:");
console.log("1. Go to Firebase Console: https://console.firebase.google.com/project/taxedgmbh/firestore");
console.log("2. Navigate to the 'taxIndexes' collection (create it if it doesn't exist)");
console.log("3. Add documents with the IDs and fields shown above");
console.log("4. Start with SO_100 (Main employment) for testing");

// Also output a JSON file for backup
const outputPath = '/Users/emanuelflury/github/TaxedGmbH_IOS/functions/so_indexes.json';
const jsonData = {};

soRecords.forEach(record => {
  if (record.Index !== 'Index No.') {
    const docId = `${record.Canton}_${record.Index}`;
    jsonData[docId] = {
      Canton: record.Canton,
      Index: record.Index,
      Main_Category: record.Main_Category || '',
      Sub_Category: record.Sub_Category || '',
      Person: record.Person || '',
      canton: record.Canton,
      index: record.Index,
      mainCategory: record.Main_Category || '',
      subcategory: record.Sub_Category || '',
      person: record.Person || '',
      Description_DE: record.Description_DE || '',
      Description_FR: record.Description_FR || '',
      Description_EN: record.Description_EN || '',
      Field1_Name_DE: record.Field1_Name_DE || '',
      Field1_Type: record.Field1_Type || '',
      Field1_Required: record.Field1_Required === 'Yes',
      Field2_Name_DE: record.Field2_Name_DE || '',
      Field2_Type: record.Field2_Type || '',
      Field2_Required: record.Field2_Required === 'Yes',
      Currency_Required: record.Currency_Required === 'Yes',
      FX_Required: record.FX_Required === 'Yes',
      Display_Formula: record.Display_Formula || '',
      Notes: record.Notes || '',
    };
  }
});

fs.writeFileSync(outputPath, JSON.stringify(jsonData, null, 2));
console.log(`\n💾 Full data saved to: ${outputPath}`);
console.log("You can use this JSON file to import data via Firebase Console's import feature");