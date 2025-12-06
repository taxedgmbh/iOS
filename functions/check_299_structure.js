const https = require('https');
const fs = require('fs');

// Get Firebase token
const configPath = require('os').homedir() + '/.config/configstore/firebase-tools.json';
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const token = config.tokens.access_token;

const options = {
  hostname: 'firestore.googleapis.com',
  path: '/v1/projects/taxedgmbh/databases/taxedgmbh/documents/taxIndexes/ZH_299_2024',
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    const doc = JSON.parse(data);
    if (doc.error) {
      console.log('❌ Error:', doc.error.message);
      return;
    }

    const fields = doc.fields || {};
    console.log('✅ ZH_299_2024 Field Structure:');
    console.log('');

    // List all fields
    const fieldNames = Object.keys(fields).sort();
    console.log(`Total fields: ${fieldNames.length}`);
    console.log('');

    fieldNames.forEach((fieldName, idx) => {
      const fieldValue = fields[fieldName];
      const valueType = Object.keys(fieldValue)[0];
      const value = fieldValue[valueType];

      console.log(`${idx + 1}. ${fieldName}: "${value}"`);
    });
  });
});

req.on('error', (e) => {
  console.error('❌ Request error:', e.message);
});

req.end();
