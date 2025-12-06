const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parse/sync');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'taxedgmbh'
});

const db = admin.firestore();

async function uploadSOIndexes() {
  try {
    console.log('📊 Starting SO canton upload to Firestore...\n');

    const csvPath = '/Users/emanuelflury/Downloads/MASTER_TAX_INDEX_DB.csv';
    const fileContent = fs.readFileSync(csvPath, 'utf-8');
    const records = csv.parse(fileContent, {
      columns: true,
      skip_empty_lines: true
    });

    const soRecords = records.filter(r => r.Canton === 'SO' && r.Index !== 'Index No.');
    console.log(`Found ${soRecords.length} SO canton records\n`);

    let count = 0;
    const batch = db.batch();

    for (const record of soRecords) {
      const docId = `${record.Canton}_${record.Index}`;
      const docRef = db.collection('taxIndexes').doc(docId);

      const docData = {
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
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      batch.set(docRef, docData);
      count++;

      // Commit every 500 documents (Firestore limit)
      if (count % 500 === 0) {
        await batch.commit();
        console.log(`✅ Batch uploaded: ${count} documents`);
        batch = db.batch();
      }
    }

    // Commit remaining documents
    if (count % 500 !== 0) {
      await batch.commit();
    }

    console.log(`\n🎉 Success! Uploaded ${count} SO canton records to Firestore`);
    console.log('\n📱 Test in your app:');
    console.log('1. Set canton to "SO" in user profile');
    console.log('2. Upload a document with category "salary"');
    console.log('3. It should show Index: 100');

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.code === 7) {
      console.log('\n⚠️  Authentication issue. Will try with service account next.');
    }
  }
  process.exit();
}

uploadSOIndexes();