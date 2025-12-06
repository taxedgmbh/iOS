/**
 * Call the migration Cloud Function
 * This is a simple wrapper to call the migrateAllUserClaims function
 */

const https = require('https');

const options = {
  hostname: 'us-central1-taxedgmbh.cloudfunctions.net',
  path: '/migrateAllUserClaims',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }
};

console.log('🚀 Calling migration function...');
console.log('   URL: https://us-central1-taxedgmbh.cloudfunctions.net/migrateAllUserClaims');

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('\n📊 Response Status:', res.statusCode);
    console.log('📄 Response Body:');

    try {
      const jsonData = JSON.parse(data);
      console.log(JSON.stringify(jsonData, null, 2));

      if (jsonData.result) {
        const result = jsonData.result;
        console.log('\n✅ Migration Summary:');
        console.log(`   Total users: ${result.totalUsers}`);
        console.log(`   Successfully updated: ${result.successCount}`);
        console.log(`   No workspaces: ${result.noWorkspacesCount}`);
        console.log(`   Failed: ${result.failedCount}`);
      }
    } catch (e) {
      console.log(data);
    }
  });
});

req.on('error', (e) => {
  console.error('❌ Error:', e.message);
});

// Send empty data object
req.write(JSON.stringify({ data: {} }));
req.end();
