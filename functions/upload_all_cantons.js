const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parse/sync');

// Initialize Firebase Admin with service account
const serviceAccount = require('/Users/emanuelflury/Downloads/taxedn8n-68fb68c972c9.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'taxedgmbh',
  databaseURL: 'https://taxedgmbh.firebaseio.com'
});

const db = admin.firestore();
db.settings({ databaseId: 'taxedgmbh' });

async function uploadAllCantons() {
  try {
    console.log('🚀 UPLOADING ALL CANTON TAX INDEXES TO FIRESTORE');
    console.log('='.repeat(60));
    console.log('Project: taxedgmbh');
    console.log('Database: taxedgmbh');
    console.log('Collection: taxIndexes\n');

    const csvPath = '/Users/emanuelflury/Downloads/MASTER_TAX_INDEX_DB.csv';
    const fileContent = fs.readFileSync(csvPath, 'utf-8');
    const records = csv.parse(fileContent, {
      columns: true,
      skip_empty_lines: true
    });

    // Get all unique cantons
    const cantons = [...new Set(records.map(r => r.Canton))].filter(c => c && c !== 'Canton');
    console.log(`📍 Found ${cantons.length} cantons: ${cantons.join(', ')}\n`);

    const stats = {
      total: 0,
      success: 0,
      failed: 0,
      cantonCounts: {}
    };

    // Process each canton
    for (const canton of cantons) {
      console.log(`\n📂 Processing canton: ${canton}`);
      console.log('-'.repeat(40));

      const cantonRecords = records.filter(r => r.Canton === canton && r.Index !== 'Index No.');
      stats.cantonCounts[canton] = { total: cantonRecords.length, success: 0, failed: 0 };

      for (const record of cantonRecords) {
        const docId = `${record.Canton}_${record.Index}`;
        stats.total++;

        try {
          const docData = {
            // === CORE FIELDS FOR QUERYING (EXACT MATCH WITH TaxIndexService) ===
            Canton: record.Canton,
            Index: record.Index,
            Main_Category: record.Main_Category || '',
            Sub_Category: record.Sub_Category || '',
            Person: record.Person || '',

            // === CAMELCASE VERSIONS FOR COMPATIBILITY ===
            canton: record.Canton,
            index: record.Index,
            mainCategory: record.Main_Category || '',
            subcategory: record.Sub_Category || '',
            person: record.Person || '',

            // === DESCRIPTIONS (MULTILINGUAL) ===
            Description_DE: record.Description_DE || '',
            Description_FR: record.Description_FR || '',
            Description_EN: record.Description_EN || '',
            descriptionDE: record.Description_DE || '',
            descriptionFR: record.Description_FR || '',
            descriptionEN: record.Description_EN || '',

            // === FIELD DEFINITIONS (UP TO 5 FIELDS) ===
            Field1_Name_DE: record.Field1_Name_DE || '',
            Field1_Type: record.Field1_Type || '',
            Field1_Required: record.Field1_Required === 'Yes',
            field1NameDE: record.Field1_Name_DE || '',
            field1Type: record.Field1_Type || '',
            field1Required: record.Field1_Required === 'Yes',

            Field2_Name_DE: record.Field2_Name_DE || '',
            Field2_Type: record.Field2_Type || '',
            Field2_Required: record.Field2_Required === 'Yes',
            field2NameDE: record.Field2_Name_DE || '',
            field2Type: record.Field2_Type || '',
            field2Required: record.Field2_Required === 'Yes',

            Field3_Name_DE: record.Field3_Name_DE || '',
            Field3_Type: record.Field3_Type || '',
            Field3_Required: record.Field3_Required === 'Yes',
            field3NameDE: record.Field3_Name_DE || '',
            field3Type: record.Field3_Type || '',
            field3Required: record.Field3_Required === 'Yes',

            Field4_Name_DE: record.Field4_Name_DE || '',
            Field4_Type: record.Field4_Type || '',
            Field4_Required: record.Field4_Required === 'Yes',
            field4NameDE: record.Field4_Name_DE || '',
            field4Type: record.Field4_Type || '',
            field4Required: record.Field4_Required === 'Yes',

            Field5_Name_DE: record.Field5_Name_DE || '',
            Field5_Type: record.Field5_Type || '',
            Field5_Required: record.Field5_Required === 'Yes',
            field5NameDE: record.Field5_Name_DE || '',
            field5Type: record.Field5_Type || '',
            field5Required: record.Field5_Required === 'Yes',

            // === CURRENCY AND FORMULA FIELDS ===
            Currency_Required: record.Currency_Required === 'Yes',
            FX_Required: record.FX_Required === 'Yes',
            currencyRequired: record.Currency_Required === 'Yes',
            fxRequired: record.FX_Required === 'Yes',

            Display_Formula: record.Display_Formula || '',
            displayFormula: record.Display_Formula || '',

            // === METADATA ===
            Notes: record.Notes || '',
            notes: record.Notes || '',
            Validation_Rules: record.Validation_Rules || '',
            validationRules: record.Validation_Rules || '',

            // === TIMESTAMPS ===
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          };

          await db.collection('taxIndexes').doc(docId).set(docData, { merge: true });
          stats.success++;
          stats.cantonCounts[canton].success++;

          // Log key documents for each canton
          if (['100', '101', '300', '500', '900'].includes(record.Index)) {
            console.log(`  ✅ ${docId}: ${record.Sub_Category || record.Main_Category}`);
          }

        } catch (docError) {
          stats.failed++;
          stats.cantonCounts[canton].failed++;
          console.error(`  ❌ Failed ${docId}: ${docError.message}`);
        }
      }

      console.log(`  📊 ${canton}: ${stats.cantonCounts[canton].success}/${stats.cantonCounts[canton].total} uploaded`);
    }

    // === FINAL SUMMARY ===
    console.log('\n' + '='.repeat(60));
    console.log('📊 UPLOAD COMPLETE - SUMMARY:');
    console.log('='.repeat(60));
    console.log(`Total Documents: ${stats.total}`);
    console.log(`✅ Successful: ${stats.success}`);
    console.log(`❌ Failed: ${stats.failed}\n`);

    console.log('Canton Breakdown:');
    for (const [canton, counts] of Object.entries(stats.cantonCounts)) {
      const percentage = ((counts.success / counts.total) * 100).toFixed(1);
      console.log(`  ${canton}: ${counts.success}/${counts.total} (${percentage}%)`);
    }

    // === MAPPING VERIFICATION ===
    console.log('\n' + '='.repeat(60));
    console.log('🔍 CATEGORY MAPPING VERIFICATION:');
    console.log('='.repeat(60));

    // Check key mappings for cover page generation
    const keyMappings = [
      { category: 'salary', canton: 'SO', expectedIndex: '100', description: 'Main employment P1' },
      { category: 'salary', canton: 'AG', expectedIndex: '010', description: 'Main employment P1' },
      { category: 'securities', canton: 'SO', expectedIndex: '300', description: 'Securities income' },
      { category: 'securities', canton: 'AG', expectedIndex: '240', description: 'Securities income' },
      { category: 'pillar3a', canton: 'SO', expectedIndex: '540', description: 'Pillar 3a P1' },
      { category: 'pillar3a', canton: 'AG', expectedIndex: '381', description: 'Pillar 3a P1' }
    ];

    console.log('\nKey mappings for cover page generation:');
    for (const mapping of keyMappings) {
      const docId = `${mapping.canton}_${mapping.expectedIndex}`;
      try {
        const doc = await db.collection('taxIndexes').doc(docId).get();
        if (doc.exists) {
          console.log(`  ✅ ${mapping.canton} - ${mapping.category} → Index ${mapping.expectedIndex} (${mapping.description})`);
        } else {
          console.log(`  ⚠️  ${mapping.canton} - ${mapping.category} → Missing index ${mapping.expectedIndex}`);
        }
      } catch (err) {
        console.log(`  ❌ ${mapping.canton} - Error checking ${docId}`);
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('✨ NEXT STEPS:');
    console.log('='.repeat(60));
    console.log('1. Test in your iOS app:');
    console.log('   - Change user canton in profile (SO, AG, etc.)');
    console.log('   - Upload documents with different categories');
    console.log('   - Verify correct index appears on cover sheet\n');

    console.log('2. Cover Page Dynamic Connection:');
    console.log('   - CoverSheetService uses TaxIndexService.getIndexMapping()');
    console.log('   - Queries by: canton + category + person (if specified)');
    console.log('   - Falls back to main category if subcategory not found\n');

    console.log('3. Available Categories in App:');
    console.log('   Income: salary, bonus, freelance, investment, rental');
    console.log('   Deductions: mortgage_interest, donations, medical, childcare');
    console.log('   Assets: property, bank_accounts, stocks, savings');
    console.log('   Liabilities: mortgage, personal_loan, credit_card');
    console.log('   Swiss: pillar2, pillar3a, military_service\n');

  } catch (error) {
    console.error('\n❌ FATAL ERROR:', error);
    console.error('Error details:', error.message);
    console.error('Error code:', error.code);
  }

  process.exit();
}

// Run the upload
uploadAllCantons();