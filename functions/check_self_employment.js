const https = require('https');
const fs = require('fs');

const configPath = require('os').homedir() + '/.config/configstore/firebase-tools.json';
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const token = config.tokens.access_token;

// Check ZH_120_2024 and ZH_121_2024
['120', '121'].forEach(index => {
  const options = {
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/taxedgmbh/databases/taxedgmbh/documents/taxIndexes/ZH_${index}_2024`,
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
        console.log(`❌ ZH_${index}_2024: ${doc.error.message}`);
        return;
      }

      const fields = doc.fields || {};
      const canton = fields.Canton ? fields.Canton.stringValue : 'missing';
      const indexNum = fields.Index ? fields.Index.stringValue : 'missing';
      const subCat = fields.Sub_Category ? fields.Sub_Category.stringValue : 'missing';
      const mainCat = fields.Main_Category ? fields.Main_Category.stringValue : 'missing';

      console.log(`✅ ZH_${index}_2024:`);
      console.log(`   Canton: ${canton}`);
      console.log(`   Index: ${indexNum}`);
      console.log(`   Sub_Category: "${subCat}"`);
      console.log(`   Main_Category: ${mainCat}`);
      console.log('');
    });
  });

  req.on('error', (e) => {
    console.error(`❌ Request error for ${index}:`, e.message);
  });

  req.end();
});
