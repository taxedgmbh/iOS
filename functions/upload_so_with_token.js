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

async function uploadSOIndexes() {
  try {
    console.log('📊 Starting SO canton upload to Firestore...\n');
    console.log('Project: taxedgmbh');
    console.log('Database: taxedgmbh\n');

    const csvPath = '/Users/emanuelflury/Downloads/MASTER_TAX_INDEX_DB.csv';
    const fileContent = fs.readFileSync(csvPath, 'utf-8');
    const records = csv.parse(fileContent, {
      columns: true,
      skip_empty_lines: true
    });

    const soRecords = records.filter(r => r.Canton === 'SO' && r.Index !== 'Index No.');
    console.log(`Found ${soRecords.length} SO canton records\n`);

    let successCount = 0;
    let errorCount = 0;

    // Upload documents one by one to better handle errors
    for (const record of soRecords) {
      const docId = `${record.Canton}_${record.Index}`;

      try {
        const docData = {
          // Core fields for querying
          Canton: record.Canton,
          Index: record.Index,
          Main_Category: record.Main_Category || '',
          Sub_Category: record.Sub_Category || '',
          Person: record.Person || '',

          // Camelcase versions for compatibility
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

          // Additional fields
          Currency_Required: record.Currency_Required === 'Yes',
          FX_Required: record.FX_Required === 'Yes',
          Display_Formula: record.Display_Formula || '',
          Notes: record.Notes || '',

          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        await db.collection('taxIndexes').doc(docId).set(docData);
        successCount++;
        console.log(`✅ ${docId}: ${record.Sub_Category || record.Main_Category}`);

      } catch (docError) {
        errorCount++;
        console.error(`❌ Failed ${docId}: ${docError.message}`);
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log(`📊 Upload Summary:`);
    console.log(`   ✅ Successful: ${successCount} documents`);
    console.log(`   ❌ Failed: ${errorCount} documents`);

    if (successCount > 0) {
      console.log('\n🎉 SO canton tax indexes are now available in Firestore!');
      console.log('\n📱 Test in your app:');
      console.log('1. Set canton to "SO" in user profile');
      console.log('2. Upload a document with category like:');
      console.log('   - "salary" → Should show Index: 100');
      console.log('   - "securities" → Should show Index: 300');
      console.log('3. Check the cover sheet PDF for the correct index number');
    }

  } catch (error) {
    console.error('\n❌ Fatal Error:', error);
    console.error('Error details:', error.message);
    console.error('Error code:', error.code);
  }

  process.exit();
}

uploadSOIndexes();