#!/usr/bin/env python3
"""
Upload Zürich Tax Indexes from New TSV (with German subcategories)
Converts German subcategory names to app-expected format
"""

import csv
import json
import os
import subprocess
import sys
from pathlib import Path

# Configuration
PROJECT_ID = 'taxedgmbh'
DATABASE_ID = 'taxedgmbh'
COLLECTION = 'taxIndexes'
TAX_YEAR = 2024
TSV_FILE = '/Users/emanuelflury/Downloads/📑 Tax Return Map - Zurich  (1).tsv'

# Mapping from German subcategory names (in TSV) to app-expected names
SUBCATEGORY_CONVERSION = {
    # Income - Employment
    'Haupterwerb (Main Employment)': 'Unselbständige Erwerbstätigkeit',
    'Nebenerwerb (Secondary Employment)': 'Unselbständige Erwerbstätigkeit',

    # Income - Self-Employment
    'Haupterwerb (Main Self-Employment)': 'Selbständige Erwerbstätigkeit',
    'Nebenerwerb (Secondary Self-Employment)': 'Selbständige Erwerbstätigkeit',

    # Income - Pensions
    'AHV- / IV-Renten (100%) (OASI / DI Pensions)': 'Vorsorge',
    'Renten / Pensionen (1. Eintrag) (Other Pensions/Annuities)': 'Vorsorge',
    'Renten / Pensionen (2. Eintrag) (Other Pensions/Annuities)': 'Vorsorge',

    # Income - Other
    'Erwerbsausfallentschädigungen aus Arbeitslosenversicherung (Loss-of-Earnings from UI)': 'Übrige Einkünfte',
    'Kinder- und Familienzulagen, Mutterschaftsentschädigungen, Taggelder (Allowances/Daily Benefits)': 'Übrige Einkünfte',
    'Ertrag aus Wertschriften, Guthaben und Lotterien': 'Wertschriften und Guthaben',
    'Davon aus qualifizierten Beteiligungen': 'Wertschriften und Guthaben',
    'Unterhaltsbeiträge vom geschiedenen/getrennten Ehegatten/Partn.': 'Übrige Einkünfte',
    'Unterhaltsbeiträge für minderjährige Kinder': 'Übrige Einkünfte',
    'Ertrag aus Geschäfts- und Korporationsanteilen': 'Übrige Einkünfte',
    'Weitere Einkünfte, nähere Bezeichnung:': 'Übrige Einkünfte',
    'Kapitalabfindungen: wiederkehrende Leistungen für [1641] Monate': 'Übrige Einkünfte',
    'Nettoertrag aus Liegenschaften': 'Liegenschaften',
    'Total der Einkünfte, zu übertragen auf Seite 3, Ziffer 19': 'Total der Einkünfte',

    # Deductions
    'Person 1': 'Berufsauslagen',
    'Person 2': 'Berufsauslagen',
    'Schuldzinsen (soweit nicht schon unter Ziff. 2 abgezogen)': 'Schuldzinsen',
    'Unterhaltsbeiträge an die geschiedenen oder getrennt lebenden Ehegatten/Partn.': 'Unterhaltsbeiträge',
    'Unterhaltsbeiträge für minderjährige Kinder (bis zum Monat der Volljährigkeit)': 'Unterhaltsbeiträge',
    'Rentenleistungen CHF 2561 = [Box] abzugsfähig: 40%': 'Unterhaltsbeiträge',
    'Person 1 eff.CHF 262': 'Versicherungen und Zinsen',
    'Person 2 eff.CHF 263': 'Versicherungen und Zinsen',
    'Versicherungsprämien, Zinsen von Sparkapitalien': 'Versicherungen und Zinsen',
    'Beiträge an die AHV, IV und 2. Säule, sofern nicht unter Ziff. 1 und 2 abgezogen': 'Versicherungen und Zinsen',
    'Berufsorientierte Aus- und Weiterbildungskosten': 'Weiterbildung',
    'Kosten für die Verwaltung des beweglichen Privatvermögens': 'Versicherungen und Zinsen',
    'Behinderungsbedingte Kosten': 'Versicherungen und Zinsen',
    'Weitere Abzüge (z.B. Beiträge an politische Parteien)': 'Spenden',
    "Abzug für fremdbetreuete Kinder (Jahrg. 2010-2024) max. 25'000 / 25'500": 'Kinderbetreuung',
    'Siehe Wegleitung zur Steuererklärung Erhebliche Mitarbeit im Beruf, Geschäft / Gewerbe des anderen Ehegatten': 'Berufsauslagen',
    'zu übertragen in Ziffer 20': 'Total der Abzüge',
    'Total der Einkünfte Übertrag von Seite 2, Ziffer 7': 'Total der Einkünfte',
    'Total der Abzüge Übertrag von Ziffer 18': 'Total der Abzüge',
    'Nettoeinkommen': 'Nettoeinkommen',
    'Krankheits- und Unfallkosten': 'Versicherungen und Zinsen',
    'Gemeinnützige Zuwendungen': 'Spenden',
    'Reineinkommen (Ziffer 21 abzüglich Ziffern 22.1 und 22.2)': 'Reineinkommen',
    'Abzug für Kinder in Ihrem Haushalt (gemäss Seite 1) 9\'300 / 6\'700': 'Kinderabzug',
    'Abzug für Kinder ausserhalb Ihres Haushaltes (gem. S. 1) 9\'300 / 6\'700': 'Kinderabzug',
    'Abzug für unterstützte Personen 2\'800 / 6\'700': 'Unterstützungsabzug',
    'Abzug für Ehegatten / Partn. — / 2\'800': 'Ehegattenabzug',

    # Wealth
    'Wertschriften und Guthaben': 'Wertschriften und Guthaben',
    'Bargeld, Gold und andere Edelmetalle': 'Bargeld und Edelmetalle',
    'Lebens- und Rentenversicherungen (Steuerwert gem. Bescheinigung der Versicherungsges.) Total': 'Versicherungen',
    'Motorfahrzeuge: Kaufpreis: Jahrgang: (Kaufjahr)': 'Fahrzeuge',
    'Geschäfts-/Korporationsanteile': 'Beteiligungen',
    'Übrige Vermögenswerte; nähere Bezeichnung:': 'Übrige Vermögenswerte',
    'Liegenschaften': 'Immobilien',
    'Zum Verkehrswert besteuert': 'Immobilien',
    'Zum Ertragswert besteuert (Land- oder Forstwirtschaft)': 'Immobilien',
    'Eigenkapital Selbständigerwerbender ohne Geschäftswertschriften': 'Geschäftsvermögen',
    'Total der Vermögenswerte': 'Total Vermögen',

    # Liabilities
    'Schulden': 'Schulden',
    'Steuerbares Vermögen gesamt': 'Steuerbares Vermögen',

    # Special
    'Kapitalleistungen aus AHV/IV, aus Freizügigkeitskonto/-police, aus Einrichtung der beruflichen Vorsorge (2. Säule), aus anerkannter Form der geb. Selbstvorsorge (3. Säule a), infolge Tod oder für bleibende körperliche oder gesundheitliche Nachteile': 'Kapitalleistungen',
    'Am [Box] 2024 erhalten von [Box] Wert:': 'Schenkungen erhalten',
    'Am [Box] 2024 ausgerichtet an [Box] Wert:': 'Schenkungen ausgerichtet',
}

# Main category mapping
SUB_TO_MAIN_CATEGORY = {
    'Unselbständige Erwerbstätigkeit': 'Einkommen',
    'Selbständige Erwerbstätigkeit': 'Einkommen',
    'Vorsorge': 'Einkommen',
    'Übrige Einkünfte': 'Einkommen',
    'Wertschriften und Guthaben': 'Einkommen',
    'Liegenschaften': 'Einkommen',
    'Total der Einkünfte': 'Einkommen',
    'Berufsauslagen': 'Abzüge',
    'Versicherungen und Zinsen': 'Abzüge',
    'Weiterbildung': 'Abzüge',
    'Unterhaltsbeiträge': 'Abzüge',
    'Spenden': 'Abzüge',
    'Kinderbetreuung': 'Abzüge',
    'Schuldzinsen': 'Abzüge',
    'Kinderabzug': 'Abzüge',
    'Unterstützungsabzug': 'Abzüge',
    'Ehegattenabzug': 'Abzüge',
    'Total der Abzüge': 'Abzüge',
    'Nettoeinkommen': 'Einkommen',
    'Reineinkommen': 'Einkommen',
    'Bargeld und Edelmetalle': 'Vermögen',
    'Versicherungen': 'Vermögen',
    'Fahrzeuge': 'Vermögen',
    'Beteiligungen': 'Vermögen',
    'Übrige Vermögenswerte': 'Vermögen',
    'Immobilien': 'Vermögen',
    'Geschäftsvermögen': 'Vermögen',
    'Total Vermögen': 'Vermögen',
    'Schulden': 'Schulden',
    'Steuerbares Vermögen': 'Vermögen',
    'Kapitalleistungen': 'Einkommen',
    'Schenkungen erhalten': 'Einkommen',
    'Schenkungen ausgerichtet': 'Abzüge',
}


def get_firebase_token():
    """Get Firebase access token from Firebase CLI config"""
    try:
        config_path = Path.home() / '.config' / 'configstore' / 'firebase-tools.json'
        with open(config_path) as f:
            config = json.load(f)
            return config['tokens']['access_token']
    except Exception as e:
        print(f'❌ Error reading Firebase token: {e}')
        print('Run: firebase login --reauth')
        sys.exit(1)


def convert_to_firestore_fields(data):
    """Convert dict to Firestore field format"""
    fields = {}
    for key, value in data.items():
        if value is None or value == '' or value == 'None':
            continue
        if isinstance(value, int):
            fields[key] = {'integerValue': str(value)}
        else:
            fields[key] = {'stringValue': str(value)}
    return fields


def upload_to_firestore(token, doc_id, fields):
    """Upload document to Firestore via REST API"""
    url = f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/{DATABASE_ID}/documents/{COLLECTION}/{doc_id}'

    payload = json.dumps({'fields': fields})

    result = subprocess.run(
        [
            'curl', '-s', '-X', 'PATCH', url,
            '-H', f'Authorization: Bearer {token}',
            '-H', 'Content-Type: application/json',
            '-d', payload
        ],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        raise Exception(f'Curl failed: {result.stderr}')

    response = json.loads(result.stdout)
    if 'error' in response:
        raise Exception(f"Firebase error: {response['error']}")

    return response


def parse_tsv_row(row):
    """Parse TSV row and convert subcategories"""
    # TSV structure:
    # [0]: Empty
    # [1]: Structural Label
    # [2]: Kategorie (Category)
    # [3]: Unterkategorie (Subcategory) - GERMAN NAMES
    # [4]: Person
    # [5]: Index No.
    # [6]: Description

    if len(row) < 6:
        return None

    # Index is at column [5]
    if not row[5] or not row[5].strip():
        return None

    try:
        index_no = row[5].strip()
        if not index_no.replace('.', '').isdigit():
            return None
    except:
        return None

    # Get German subcategory and convert to app format
    german_subcat = row[3].strip() if row[3] else ''
    converted_subcat = SUBCATEGORY_CONVERSION.get(german_subcat, german_subcat)

    # Get main category
    main_category = SUB_TO_MAIN_CATEGORY.get(converted_subcat, 'Einkommen')

    # Clean person string
    person_str = row[4].strip() if row[4] else ''
    if 'Person' in person_str:
        if 'Person 1' in person_str:
            person_str = 'Person 1'
        elif 'Person 2' in person_str:
            person_str = 'Person 2'

    # Create complete 15-field structure for consistency with existing uploads
    data = {
        'Canton': 'ZH',
        'Index': index_no,
        'Tax_Year': TAX_YEAR,
        'Main_Category': main_category,
        'Sub_Category': converted_subcat,
        'Person': person_str,
        'Description': row[6].strip() if len(row) > 6 and row[6] else '',
        'Legal_Reference_Canton': '',  # To be populated with legal research
        'Legal_Reference_Federal': '',  # To be populated with legal research
        'Rational_Explanation': '',     # To be populated with legal research
        'Deductibility_Rules': '',      # To be populated with legal research
        'Max_Deductible': '',           # To be populated with legal research
        'Limitations': '',              # To be populated with legal research
        'Source': 'https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html',
        'Source_Document': 'Steuererklärung 2024 Kanton Zürich',
        'Verification_Status': 'pending'
    }

    # Keep all fields for consistency - don't filter empty ones
    return data


def main():
    print('=' * 70)
    print('Uploading Zürich Tax Indexes from New TSV (with conversions)')
    print('=' * 70)
    print()

    # Check TSV file exists
    if not os.path.exists(TSV_FILE):
        print(f'❌ TSV file not found: {TSV_FILE}')
        sys.exit(1)

    print(f'✅ Reading TSV file: {TSV_FILE}')

    # Get Firebase token
    token = get_firebase_token()
    print('✅ Firebase token retrieved')
    print()

    # Read TSV file
    indexes = []
    with open(TSV_FILE, 'r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter='\t')

        # Skip header rows (first 2 rows)
        next(reader, None)
        next(reader, None)

        for row in reader:
            data = parse_tsv_row(row)
            if data:
                indexes.append(data)

    print(f'✅ Parsed {len(indexes)} tax indexes from TSV')
    print()

    # Group by verification status
    verified = [idx for idx in indexes if idx.get('Verification_Status') == 'verified']
    pending = [idx for idx in indexes if idx.get('Verification_Status') == 'pending']

    print(f'   - Verified: {len(verified)}')
    print(f'   - Pending: {len(pending)}')
    print()

    # Group by Main_Category
    by_category = {}
    for idx in indexes:
        cat = idx.get('Main_Category', 'Unknown')
        by_category[cat] = by_category.get(cat, 0) + 1

    print('Breakdown by Main_Category:')
    for cat, count in sorted(by_category.items()):
        print(f'   - {cat}: {count}')
    print()

    # Upload all indexes
    success_count = 0
    fail_count = 0
    updated_count = 0

    for idx_data in indexes:
        index_no = idx_data['Index']
        doc_id = f"ZH_{index_no}_{TAX_YEAR}"

        try:
            sys.stdout.write(f"[Uploading] {doc_id} ({idx_data['Sub_Category']})... ")
            sys.stdout.flush()

            fields = convert_to_firestore_fields(idx_data)
            upload_to_firestore(token, doc_id, fields)

            print('✅')
            success_count += 1
            updated_count += 1
        except Exception as e:
            error_str = str(e)
            if 'already exists' in error_str.lower():
                print('⚠️  (already exists)')
                updated_count += 1
            else:
                print(f'❌ {error_str[:50]}')
                fail_count += 1

    print()
    print('=' * 70)
    print(f'✅ Successfully uploaded/updated {success_count} tax indexes')
    print(f'⚠️  Already existed: {updated_count - success_count}')
    if fail_count > 0:
        print(f'❌ Failed: {fail_count}')
    print('=' * 70)
    print()
    print('Verify at:')
    print(f'https://console.firebase.google.com/project/{PROJECT_ID}/firestore/databases/{DATABASE_ID}/data/~2F{COLLECTION}')
    print()

    sys.exit(0 if fail_count == 0 else 1)


if __name__ == '__main__':
    main()
