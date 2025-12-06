#!/usr/bin/env python3
"""
Upload Bern (BE) Tax Indexes from TSV
Converts English subcategory names to German app-expected format
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
CANTON = 'BE'
TSV_FILE = '/Users/emanuelflury/Downloads/📑 Tax Return Map - Bern.tsv'

# Mapping from English subcategory names (in TSV) to German app-expected names
SUBCATEGORY_CONVERSION = {
    # Income - Employment
    'Income from Gainful Employment': 'Unselbständige Erwerbstätigkeit',

    # Income - Self-Employment
    'Income from Self-Employment': 'Selbständige Erwerbstätigkeit',
    'Capital from Self-Employment': 'Selbständige Erwerbstätigkeit',

    # Income - Agriculture
    'Income from Agriculture/Forestry': 'Selbständige Erwerbstätigkeit',
    'Capital from Agriculture/Forestry': 'Selbständige Erwerbstätigkeit',

    # Income - Pensions & Social Security
    'Social Security and Pensions': 'Vorsorge',

    # Income - Support Payments
    'Support Payments': 'Übrige Einkünfte',

    # Income - Other
    'Other Taxable Income': 'Übrige Einkünfte',

    # Income - Securities & Investments
    'Investment/Lottery Winnings': 'Wertschriften und Guthaben',
    'Investment Assets': 'Wertschriften und Guthaben',

    # Income - Property
    'Property and Rental Income': 'Liegenschaften',

    # Income - Joint Ownership
    'Joint Ownership/Partnerships': 'Selbständige Erwerbstätigkeit',

    # Deductions - Pensions
    'Deductions for Pensions/Insurance': 'Vorsorge',

    # Deductions - Childcare
    'Deductions for Childcare/AHV/IV': 'Kinderbetreuung',

    # Deductions - Securities
    'Deductions for Securities/Lottery': 'Wertschriften und Guthaben',

    # Deductions - General
    'General Deductions': 'Versicherungen und Zinsen',

    # Deductions - Support & Disability
    'Support/Disability Costs': 'Unterhaltsbeiträge',

    # Deductions - Professional Expenses
    'Professional Expenses': 'Berufsauslagen',

    # Deductions - Property
    'Property and Admin Costs': 'Liegenschaften',

    # Social Deductions
    'Social Deductions': 'Spenden',

    # Wealth
    'Other Assets': 'Übriges Vermögen',
    'Insurance Assets': 'Versicherungen',
}

# Main category mapping
SUB_TO_MAIN_CATEGORY = {
    'Unselbständige Erwerbstätigkeit': 'Einkommen',
    'Selbständige Erwerbstätigkeit': 'Einkommen',
    'Vorsorge': 'Einkommen',
    'Übrige Einkünfte': 'Einkommen',
    'Wertschriften und Guthaben': 'Einkommen',
    'Liegenschaften': 'Einkommen',
    'Berufsauslagen': 'Abzüge',
    'Versicherungen und Zinsen': 'Abzüge',
    'Weiterbildung': 'Abzüge',
    'Unterhaltsbeiträge': 'Abzüge',
    'Spenden': 'Abzüge',
    'Kinderbetreuung': 'Abzüge',
    'Schuldzinsen': 'Abzüge',
    'Übriges Vermögen': 'Vermögen',
    'Versicherungen': 'Vermögen',
    'Schulden': 'Schulden',
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


def parse_tsv_row(row, category_field):
    """Parse TSV row and convert subcategories"""
    # TSV structure:
    # [0]: Empty
    # [1]: Structural Label
    # [2]: Kategorie (Category) - German description
    # [3]: Unterkategorie (Subcategory) - ENGLISH NAMES
    # [4]: Person
    # [5]: Index No.
    # [6]: Description

    if len(row) < 6:
        return None

    # Index is at column [5]
    index_no = row[5].strip() if row[5] else ''
    if not index_no:
        return None

    # Skip non-numeric indexes
    if not any(c.isdigit() for c in index_no):
        return None

    # Get English subcategory from TSV and convert to German
    english_subcat = row[3].strip() if row[3] else ''
    german_subcat = SUBCATEGORY_CONVERSION.get(english_subcat, 'Übrige Einkünfte')

    # Get main category
    main_category = SUB_TO_MAIN_CATEGORY.get(german_subcat, 'Einkommen')

    # Use the Category field (German description) as description
    description = category_field.strip() if category_field else ''

    # Clean person string
    person_str = row[4].strip() if row[4] else ''

    # Create complete 15-field structure
    data = {
        'Canton': CANTON,
        'Index': index_no,
        'Tax_Year': TAX_YEAR,
        'Main_Category': main_category,
        'Sub_Category': german_subcat,
        'Person': person_str,
        'Description': description,
        'Legal_Reference_Canton': '',  # To be populated with legal metadata
        'Legal_Reference_Federal': '',
        'Rational_Explanation': '',
        'Deductibility_Rules': '',
        'Max_Deductible': '',
        'Limitations': '',
        'Source': 'https://www.be.ch/de/start/themen/steuern.html',
        'Source_Document': 'Steuererklärung 2024 Kanton Bern',
        'Verification_Status': 'pending'
    }

    return data


def main():
    print('=' * 70)
    print('Uploading Bern (BE) Tax Indexes from TSV')
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
        rows = list(reader)

        # Skip header rows (first 3 rows)
        for row in rows[3:]:
            if len(row) < 6:
                continue

            # Use column [2] (Kategorie) as the description/category field
            data = parse_tsv_row(row, row[2])
            if data:
                indexes.append(data)

    print(f'✅ Parsed {len(indexes)} tax indexes from TSV')
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

    # Group by Sub_Category
    by_subcat = {}
    for idx in indexes:
        subcat = idx.get('Sub_Category', 'Unknown')
        by_subcat[subcat] = by_subcat.get(subcat, 0) + 1

    print('Breakdown by Sub_Category:')
    for subcat, count in sorted(by_subcat.items()):
        print(f'   - {subcat}: {count}')
    print()

    # Upload all indexes
    success_count = 0
    fail_count = 0
    updated_count = 0

    for idx_data in indexes:
        index_no = idx_data['Index']
        doc_id = f"{CANTON}_{index_no}_{TAX_YEAR}"

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
