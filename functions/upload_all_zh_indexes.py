#!/usr/bin/env python3
"""
Upload ALL Zürich Tax Indexes from TSV to Firebase
Reads comprehensive TSV file and uploads all 95 indexes with complete metadata
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
TSV_FILE = '/Users/emanuelflury/Downloads/📑 Tax Return Map - Zurich .tsv'

# Mapping from Unterkategorie (Subcategory) to Main_Category
SUB_TO_MAIN_CATEGORY = {
    # Einkommen (Income)
    'Unselbständige Erwerbstätigkeit': 'Einkommen',
    'Selbständige Erwerbstätigkeit': 'Einkommen',
    'Vorsorge': 'Einkommen',
    'Übrige Einkünfte': 'Einkommen',
    'Wertschriften und Guthaben': 'Einkommen',
    'Liegenschaften': 'Einkommen',
    'Total der Einkünfte': 'Einkommen',

    # Abzüge (Deductions)
    'Berufsauslagen': 'Abzüge',
    'Versicherungen und Zinsen': 'Abzüge',
    'Versicherungsprämien': 'Abzüge',
    'Weiterbildung': 'Abzüge',
    'Unterhaltsbeiträge': 'Abzüge',
    'Spenden': 'Abzüge',
    'Kinderbetreuung': 'Abzüge',
    'Schuldzinsen': 'Abzüge',

    # Vermögen (Assets)
    'Bankguthaben': 'Vermögen',
    'Wertpapiere': 'Vermögen',
    'Immobilien': 'Vermögen',
    'Fahrzeuge': 'Vermögen',
    'Übrige Vermögenswerte': 'Vermögen',

    # Schulden (Liabilities)
    'Hypotheken': 'Schulden',
    'Kredite': 'Schulden',
    'Übrige Schulden': 'Schulden'
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

    # Use curl to upload
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
    """Parse TSV row into tax index data - handles both 15 and 16 column formats"""
    # Both formats have same structure for first 6 columns:
    # [0]: Empty
    # [1]: Structural Label
    # [2]: Kategorie (Category)
    # [3]: Unterkategorie (Subcategory)
    # [4]: Person
    # [5]: Index No.
    #
    # Then they differ:
    # 16 columns: [6]=Description, [7]=Legal_Ref_Canton, [8]=Legal_Ref_Federal, ...
    # 15 columns: [6]=Legal_Ref_Canton, [7]=Legal_Ref_Federal, ... (no Description)

    if len(row) < 15:
        return None

    # Index is always at column [5]
    if not row[5] or not row[5].strip():
        return None

    try:
        index_no = row[5].strip()
        # Skip non-numeric indexes
        if not index_no.replace('.', '').isdigit():
            return None
    except:
        return None

    sub_category = row[3].strip() if row[3] else ''
    main_category = SUB_TO_MAIN_CATEGORY.get(sub_category, 'Einkommen')

    person_str = row[4].strip() if row[4] else ''
    # Clean up person string (remove extra text like "eff.CHF 262")
    if 'Person' in person_str:
        if 'Person 1' in person_str:
            person_str = 'Person 1'
        elif 'Person 2' in person_str:
            person_str = 'Person 2'

    # Base data same for both formats
    data = {
        'Canton': 'ZH',
        'Index': index_no,
        'Tax_Year': TAX_YEAR,
        'Main_Category': main_category,
        'Sub_Category': sub_category,
        'Person': person_str,
    }

    # For 15-column rows, no Description field, legal refs start at [6]
    if len(row) == 15:
        data.update({
            'Legal_Reference_Canton': row[6].strip() if len(row) > 6 and row[6] else '',
            'Legal_Reference_Federal': row[7].strip() if len(row) > 7 and row[7] else '',
            'Rational_Explanation': row[8].strip() if len(row) > 8 and row[8] else '',
            'Deductibility_Rules': row[9].strip() if len(row) > 9 and row[9] else '',
            'Max_Deductible': row[10].strip() if len(row) > 10 and row[10] else '',
            'Limitations': row[11].strip() if len(row) > 11 and row[11] else '',
            'Source': row[12].strip() if len(row) > 12 and row[12] else '',
            'Source_Document': row[13].strip() if len(row) > 13 and row[13] else '',
            'Verification_Status': row[14].strip() if len(row) > 14 and row[14] else 'pending'
        })
    else:  # 16 columns
        data.update({
            'Description': row[6].strip() if len(row) > 6 and row[6] else '',
            'Legal_Reference_Canton': row[7].strip() if len(row) > 7 and row[7] else '',
            'Legal_Reference_Federal': row[8].strip() if len(row) > 8 and row[8] else '',
            'Rational_Explanation': row[9].strip() if len(row) > 9 and row[9] else '',
            'Deductibility_Rules': row[10].strip() if len(row) > 10 and row[10] else '',
            'Max_Deductible': row[11].strip() if len(row) > 11 and row[11] else '',
            'Limitations': row[12].strip() if len(row) > 12 and row[12] else '',
            'Source': row[13].strip() if len(row) > 13 and row[13] else '',
            'Source_Document': row[14].strip() if len(row) > 14 and row[14] else '',
            'Verification_Status': row[15].strip() if len(row) > 15 and row[15] else 'pending'
        })

    # Remove empty fields
    data = {k: v for k, v in data.items() if v}

    return data


def main():
    print('=' * 60)
    print('Uploading ALL Zürich Tax Indexes from TSV to Firebase')
    print('=' * 60)
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

        # Skip header rows (first 3 rows: title header, section title, column headers)
        next(reader, None)
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

    # Upload all indexes
    success_count = 0
    fail_count = 0

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
        except Exception as e:
            print(f'❌ {str(e)[:50]}')
            fail_count += 1

    print()
    print('=' * 60)
    print(f'✅ Successfully uploaded {success_count} tax indexes')
    if fail_count > 0:
        print(f'❌ Failed: {fail_count}')
    print('=' * 60)
    print()
    print('Verify at:')
    print(f'https://console.firebase.google.com/project/{PROJECT_ID}/firestore/databases/{DATABASE_ID}/data/~2F{COLLECTION}')
    print()

    sys.exit(0 if fail_count == 0 else 1)


if __name__ == '__main__':
    main()
