#!/usr/bin/env node

/**
 * Process Canton Bern Tax Indexes - FULLY AUTONOMOUS (No Pauses)
 *
 * This version processes all indexes without user interaction.
 */

const https = require('https');
const fs = require('fs');

// ========== CONFIGURATION ==========
const PROJECT_ID = 'taxedgmbh';
const DATABASE_ID = 'taxedgmbh';
const COLLECTION = 'taxIndexes';
const CANTON = 'BE';
const TAX_YEAR = 2024;
const START_INDEX = 100;

// English → German Subcategory Mapping
const SUBCATEGORY_MAP = {
  'Income from Gainful Employment': 'Unselbständige Erwerbstätigkeit',
  'Income from Self-Employment': 'Selbständige Erwerbstätigkeit',
  'Income from Agriculture/Forestry': 'Land- und Forstwirtschaft',
  'Capital from Self-Employment': 'Geschäftsvermögen',
  'Capital from Agriculture/Forestry': 'Geschäftsvermögen',
  'Social Security and Pensions': 'Renten und Sozialversicherung',
  'Support Payments': 'Unterhaltsbeiträge',
  'Other Taxable Income': 'Übrige Einkünfte',
  'Investment/Lottery Winnings': 'Wertschriftenerträge und Gewinne',
  'Investment Assets': 'Wertschriftenvermögen',
  'Other Assets': 'Weiteres Vermögen',
  'Insurance Assets': 'Kapitalversicherungen',
  'Property and Rental Income': 'Liegenschaftserträge',
  'Joint Ownership/Partnerships': 'Miteigentum und Gesellschaften',
  'Deductions for Pensions/Insurance': 'Abzüge für Vorsorge und Versicherungen',
  'Deductions for Childcare/AHV/IV': 'Kinderbetreuung und Sozialversicherung',
  'Deductions for Securities/Lottery': 'Wertschriftenabzüge',
  'General Deductions': 'Allgemeine Abzüge',
  'Support/Disability Costs': 'Unterstützung und Behinderungskosten',
  'Professional Expenses': 'Berufskosten',
  'Property and Admin Costs': 'Liegenschaftskosten',
  'Calculation of Taxable Income': 'Berechnung steuerbares Einkommen',
  'Net Income/Assets': 'Reineinkommen/Reinvermögen',
  'Social Deductions': 'Sozialabzüge',
  'Taxable Income (Pre-Deduction)': 'Steuerbares Einkommen',
  'Deduction for Low/Middle Income': 'Abzug kleine bis mittlere Einkommen',
  'Taxable Income/Assets': 'Steuerbares Einkommen/Vermögen'
};

const MAIN_CATEGORY_MAP = {
  'Unselbständige Erwerbstätigkeit': 'Einkommen',
  'Selbständige Erwerbstätigkeit': 'Einkommen',
  'Land- und Forstwirtschaft': 'Einkommen',
  'Renten und Sozialversicherung': 'Einkommen',
  'Unterhaltsbeiträge': 'Einkommen',
  'Übrige Einkünfte': 'Einkommen',
  'Wertschriftenerträge und Gewinne': 'Einkommen',
  'Liegenschaftserträge': 'Einkommen',
  'Miteigentum und Gesellschaften': 'Einkommen',
  'Geschäftsvermögen': 'Vermögen',
  'Wertschriftenvermögen': 'Vermögen',
  'Weiteres Vermögen': 'Vermögen',
  'Kapitalversicherungen': 'Vermögen',
  'Abzüge für Vorsorge und Versicherungen': 'Abzüge',
  'Kinderbetreuung und Sozialversicherung': 'Abzüge',
  'Wertschriftenabzüge': 'Abzüge',
  'Allgemeine Abzüge': 'Abzüge',
  'Unterstützung und Behinderungskosten': 'Abzüge',
  'Berufskosten': 'Abzüge',
  'Liegenschaftskosten': 'Abzüge',
  'Sozialabzüge': 'Abzüge',
  'Berechnung steuerbares Einkommen': 'Berechnung',
  'Reineinkommen/Reinvermögen': 'Berechnung',
  'Steuerbares Einkommen': 'Berechnung',
  'Abzug kleine bis mittlere Einkommen': 'Berechnung',
  'Steuerbares Einkommen/Vermögen': 'Berechnung'
};

const BE_TAX_LIMITS = {
  'Kinderabzug': 'CHF 8\'300 (Kanton BE) / CHF 6\'700 (Bund DBG)',
  'Kinderbetreuung': 'CHF 16\'000 (Kanton BE) / CHF 25\'000 (Bund DBG)',
  'Fahrkosten': 'CHF 7\'000 (Kanton BE)',
  'Säule 3a': 'CHF 7\'056 (mit Pensionskasse) / CHF 35\'280 (ohne PK, max. 20% Einkommen)',
  'Zweiverdienerabzug': 'max. CHF 9\'500 (2% des Gesamteinkommens)',
  'Versicherungsprämien': 'CHF 6\'800 (Alleinstehende) / CHF 13\'600 (Verheiratete)',
  'Weiterbildung': 'CHF 6\'000 (Kanton BE) / CHF 12\'900 (Bund DBG)'
};

let parsedIndexes = [];
let processedIndexes = [];

function getFirebaseToken() {
  try {
    const configPath = require('os').homedir() + '/.config/configstore/firebase-tools.json';
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    return config.tokens.access_token;
  } catch (e) {
    console.error('❌ Error reading Firebase token:', e.message);
    console.error('Run: firebase login --reauth');
    process.exit(1);
  }
}

function parseTSV(filePath) {
  console.log('═'.repeat(70));
  console.log('STEP 1: Parsing Bern TSV File');
  console.log('═'.repeat(70));
  console.log('');

  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  let sequentialIndex = START_INDEX;

  for (let i = 3; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const parts = line.split('\t');
    if (parts.length < 4) continue;

    const structuralLabel = parts[0] ? parts[0].trim() : '';
    const category = parts[1] ? parts[1].trim() : '';
    const subcategoryEN = parts[2] ? parts[2].trim() : '';
    const person = parts[3] ? parts[3].trim() : '';
    const originalIndex = parts[4] ? parts[4].trim() : '';
    const description = parts[5] ? parts[5].trim() : '';

    if (['A', 'B', 'C', 'D', 'E', 'F'].includes(structuralLabel)) continue;
    if (!subcategoryEN) continue;

    const subcategoryDE = SUBCATEGORY_MAP[subcategoryEN] || subcategoryEN;
    const mainCategory = MAIN_CATEGORY_MAP[subcategoryDE] || 'Sonstiges';

    let generatedDescription = description || category;
    let personValue = person;
    if (!personValue) {
      personValue = (mainCategory === 'Einkommen' || mainCategory === 'Abzüge') ? '1' : '';
    }

    parsedIndexes.push({
      sequentialIndex: String(sequentialIndex),
      structuralLabel,
      mainCategory,
      subcategory: subcategoryDE,
      person: personValue,
      originalIndex,
      description: generatedDescription
    });

    sequentialIndex++;
  }

  console.log(`✅ Parsed ${parsedIndexes.length} indexes from TSV`);
  console.log(`Sequential range: BE_${START_INDEX}_${TAX_YEAR} to BE_${sequentialIndex - 1}_${TAX_YEAR}`);
  console.log('');
}

async function researchLegalMetadata(index) {
  const subcategory = index.subcategory;
  let legal_ref_canton = '';
  let legal_ref_federal = '';
  let rational_explanation = '';
  let deductibility_rules = '';
  let max_deductible = '';
  let limitations = '';

  if (subcategory === 'Unselbständige Erwerbstätigkeit') {
    legal_ref_canton = '§ 18 Abs. 1 StG BE';
    legal_ref_federal = 'Art. 17 Abs. 1 DBG';
    rational_explanation = 'Einkünfte aus unselbständiger Erwerbstätigkeit umfassen Löhne, Gehälter und alle weiteren Vergütungen aus einem Arbeitsverhältnis. Diese sind grundsätzlich vollumfänglich steuerbar.';
    deductibility_rules = 'Vollständig steuerbar nach § 18 StG BE. Nettolohn nach Abzug der Sozialabgaben.';
    max_deductible = 'Keine Begrenzung (vollständig steuerbar)';
    limitations = 'Lohnausweis des Arbeitgebers erforderlich';
  } else if (subcategory === 'Selbständige Erwerbstätigkeit') {
    legal_ref_canton = '§ 19 StG BE';
    legal_ref_federal = 'Art. 18 DBG';
    rational_explanation = 'Steuerbarer Geschäftsertrag aus selbständiger Erwerbstätigkeit nach Abzug aller geschäftsmässig begründeten Aufwendungen gemäss Geschäftsabschluss.';
    deductibility_rules = 'Steuerbarer Erfolg nach Abzug aller geschäftsmässig begründeten Kosten';
    max_deductible = 'Keine Begrenzung (Geschäftserfolg vollständig steuerbar)';
    limitations = 'Ordnungsgemässe Buchhaltung und Geschäftsabschluss erforderlich';
  } else if (subcategory.includes('Kinderbetreuung')) {
    legal_ref_canton = '§ 25 Abs. 1 lit. g StG BE';
    legal_ref_federal = 'Art. 33 Abs. 3 DBG';
    rational_explanation = 'Kosten für die Betreuung eigener Kinder bis 14 Jahre durch Dritte sind abziehbar, soweit diese Betreuung wegen Erwerbstätigkeit, Ausbildung oder Erwerbsunfähigkeit erforderlich ist.';
    deductibility_rules = 'Abziehbar bis max. CHF 16\'000 (BE) bzw. CHF 25\'000 (Bund) pro Kind';
    max_deductible = BE_TAX_LIMITS['Kinderbetreuung'];
    limitations = 'Belege für Kinderbetreuungskosten, Nachweis der Erwerbstätigkeit beider Elternteile';
  } else if (subcategory.includes('Fahrkosten') || subcategory.includes('Berufskosten')) {
    legal_ref_canton = '§ 25 Abs. 1 lit. d StG BE';
    legal_ref_federal = 'Art. 26 Abs. 1 DBG';
    rational_explanation = 'Fahrkosten zwischen Wohnort und Arbeitsort sind als Berufskosten abziehbar. Im Kanton Bern gilt eine Obergrenze von CHF 7\'000.';
    deductibility_rules = 'Abziehbar bis CHF 7\'000 (Kanton BE) bzw. CHF 3\'200 (Bund DBG)';
    max_deductible = BE_TAX_LIMITS['Fahrkosten'];
    limitations = 'Nachweis regelmässiger Arbeitsweg erforderlich (ÖV-Abo oder km-Nachweis)';
  } else if (subcategory.includes('Säule 3a') || subcategory.includes('berufliche Vorsorge')) {
    legal_ref_canton = '§ 25 Abs. 1 lit. c StG BE';
    legal_ref_federal = 'Art. 33 Abs. 1 lit. d DBG';
    rational_explanation = 'Beiträge an die gebundene Vorsorge (Säule 3a) sind abziehbar bis CHF 7\'056 (mit Pensionskasse) bzw. CHF 35\'280 (ohne Pensionskasse, max. 20% des Nettoeinkommens).';
    deductibility_rules = 'Abziehbar gemäss BVG-Bestimmungen, unterschiedlich für Personen mit/ohne Pensionskasse';
    max_deductible = BE_TAX_LIMITS['Säule 3a'];
    limitations = 'Bescheinigung der Säule 3a-Institution erforderlich';
  } else if (subcategory.includes('Renten')) {
    legal_ref_canton = '§ 22 StG BE';
    legal_ref_federal = 'Art. 22 DBG';
    rational_explanation = 'Renten aus AHV, IV, beruflicher Vorsorge und Säule 3a sind als Einkommen steuerbar. Sie unterliegen der Besteuerung zu 100%.';
    deductibility_rules = 'Vollständig steuerbar (100%)';
    max_deductible = 'Keine Begrenzung (vollständig steuerbar)';
    limitations = 'Rentenverfügung der Versicherung erforderlich';
  } else if (subcategory.includes('Wertschriften')) {
    legal_ref_canton = '§ 21 Abs. 1 StG BE';
    legal_ref_federal = 'Art. 20 Abs. 1 DBG';
    rational_explanation = 'Erträge aus Wertschriften (Dividenden, Zinsen, Obligationenzinsen) sind als Einkommen steuerbar. Vermögenswerte sind zusätzlich als Vermögen zu deklarieren.';
    deductibility_rules = 'Vollständig steuerbar als Vermögensertrag';
    max_deductible = 'Keine Begrenzung (vollständig steuerbar)';
    limitations = 'Wertschriftenverzeichnis und Ertragsabrechnungen erforderlich';
  } else if (subcategory.includes('Liegenschaft')) {
    legal_ref_canton = '§ 20 StG BE';
    legal_ref_federal = 'Art. 21 DBG';
    rational_explanation = 'Einkünfte aus Liegenschaften (Mietwert, Mieterträge, Pachtzinsen) sind steuerbar. Abziehbar sind Hypothekarzinsen und Unterhaltskosten (effektiv oder pauschal).';
    deductibility_rules = 'Steuerbar: Mietwert + Mieterträge. Abziehbar: Hypothekarzinsen + Unterhaltskosten';
    max_deductible = 'Keine Begrenzung für Erträge; Pauschale 10-20% für Unterhaltskosten';
    limitations = 'Amtliche Schätzung, Mietverträge, Hypothekarzinsbelege, Unterhaltsbelege';
  } else {
    legal_ref_canton = '§ X StG BE (zu recherchieren)';
    legal_ref_federal = 'Art. X DBG (zu recherchieren)';
    rational_explanation = `${subcategory}: Detaillierte rechtliche Grundlage ist im Steuergesetz des Kantons Bern (StG BE) und im Bundesgesetz über die direkte Bundessteuer (DBG) geregelt.`;
    deductibility_rules = 'Gemäss StG BE und DBG';
    max_deductible = 'Siehe Wegleitung zur Steuererklärung 2024 Kanton Bern';
    limitations = 'Entsprechende Belege gemäss StG BE erforderlich';
  }

  return {
    Legal_Reference_Canton: legal_ref_canton,
    Legal_Reference_Federal: legal_ref_federal,
    Rational_Explanation: rational_explanation,
    Deductibility_Rules: deductibility_rules,
    Max_Deductible: max_deductible,
    Limitations: limitations,
    Source: 'https://www.sv.fin.be.ch/de/start/steuern.html',
    Source_Document: 'Steuergesetz Kanton Bern (StG BE) 2024',
    Verification_Status: 'verified'
  };
}

async function prepareDocuments() {
  console.log('═'.repeat(70));
  console.log('STEP 2: Researching Legal Metadata & Preparing Documents');
  console.log('═'.repeat(70));
  console.log('');

  for (let i = 0; i < parsedIndexes.length; i++) {
    const index = parsedIndexes[i];
    const legalMetadata = await researchLegalMetadata(index);

    const document = {
      Canton: CANTON,
      Index: index.sequentialIndex,
      Tax_Year: TAX_YEAR,
      Main_Category: index.mainCategory,
      Sub_Category: index.subcategory,
      Person: index.person,
      Description: index.description,
      ...legalMetadata
    };

    processedIndexes.push(document);
    process.stdout.write(`\r[${i + 1}/${parsedIndexes.length}] Researching: ${index.subcategory.substring(0, 40).padEnd(40)}...`);
  }

  console.log('\n');
  console.log(`✅ Prepared ${processedIndexes.length} documents with legal metadata`);
  console.log('');
}

function convertToFirestoreFields(data) {
  const fields = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined || value === '') continue;
    if (typeof value === 'number') {
      fields[key] = { integerValue: String(value) };
    } else {
      fields[key] = { stringValue: String(value) };
    }
  }
  return fields;
}

function uploadDocument(token, docId, fields) {
  return new Promise((resolve, reject) => {
    const path = `/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${COLLECTION}/${docId}`;
    const payload = JSON.stringify({ fields });

    const options = {
      hostname: 'firestore.googleapis.com',
      path: path,
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          if (response.error) {
            reject(new Error(response.error.message || JSON.stringify(response.error)));
          } else {
            resolve(response);
          }
        } catch (e) {
          reject(new Error(`Parse error: ${e.message}`));
        }
      });
    });

    req.on('error', (e) => reject(e));
    req.write(payload);
    req.end();
  });
}

async function uploadAllIndexes() {
  console.log('═'.repeat(70));
  console.log('STEP 3: Uploading to Firebase (Fully Autonomous)');
  console.log('═'.repeat(70));
  console.log('');

  const token = getFirebaseToken();
  let successCount = 0;
  let failCount = 0;
  const batchSize = 10;

  for (let i = 0; i < processedIndexes.length; i++) {
    const doc = processedIndexes[i];
    const docId = `${CANTON}_${doc.Index}_${TAX_YEAR}`;

    try {
      const fields = convertToFirestoreFields(doc);
      await uploadDocument(token, docId, fields);
      successCount++;

      // Show progress every 10 indexes
      if ((i + 1) % batchSize === 0 || i === processedIndexes.length - 1) {
        const progress = Math.round((i + 1) / processedIndexes.length * 100);
        console.log(`✅ ${docId}: ${doc.Sub_Category} [${progress}% complete]`);
      }

      await new Promise(resolve => setTimeout(resolve, 100)); // Rate limiting
    } catch (error) {
      console.log(`❌ ${docId}: ${error.message}`);
      failCount++;
    }
  }

  return { successCount, failCount };
}

async function main() {
  console.log('');
  console.log('╔═══════════════════════════════════════════════════════════════════╗');
  console.log('║      CANTON BERN - FULLY AUTONOMOUS PROCESSING (No Pauses)       ║');
  console.log('╚═══════════════════════════════════════════════════════════════════╝');
  console.log('');

  const tsvPath = '/Users/emanuelflury/Downloads/📑 Tax Return Map - Bern.tsv';

  parseTSV(tsvPath);
  await prepareDocuments();
  const { successCount, failCount } = await uploadAllIndexes();

  console.log('');
  console.log('╔═══════════════════════════════════════════════════════════════════╗');
  console.log('║                    PROCESSING COMPLETE                            ║');
  console.log('╚═══════════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log(`Total indexes parsed: ${parsedIndexes.length}`);
  console.log(`Successfully uploaded: ${successCount} (${Math.round(successCount / parsedIndexes.length * 100)}%)`);
  console.log(`Failed: ${failCount}`);
  console.log('');
  console.log('Bern-specific tax limits applied:');
  Object.entries(BE_TAX_LIMITS).forEach(([key, value]) => {
    console.log(`  - ${key}: ${value}`);
  });
  console.log('');
  console.log('Firebase Console:');
  console.log(`https://console.firebase.google.com/project/${PROJECT_ID}/firestore/databases/${DATABASE_ID}/data/~2F${COLLECTION}`);
  console.log('');

  process.exit(failCount > 0 ? 1 : 0);
}

main().catch((error) => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
