#!/usr/bin/env python3
"""
Analyze Bern TSV to understand structure and extract all indexes
"""

import csv
from collections import defaultdict

TSV_FILE = '/Users/emanuelflury/Downloads/📑 Tax Return Map - Bern.tsv'

def main():
    print('=' * 70)
    print('Analyzing Bern Tax Return Map TSV')
    print('=' * 70)
    print()

    indexes = []
    subcategories = set()
    by_category = defaultdict(int)

    with open(TSV_FILE, 'r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter='\t')

        # Read all rows
        rows = list(reader)

        print(f'Total rows: {len(rows)}')
        print()

        # Analyze structure
        for i, row in enumerate(rows[:10]):
            print(f'Row {i}: {row}')

        print()
        print('=' * 70)
        print('Extracting indexes...')
        print('=' * 70)

        # Skip header rows
        for i, row in enumerate(rows[3:], start=3):
            if len(row) < 6:
                continue

            # Column structure:
            # [0]: Empty or row number
            # [1]: Structural Label (P1/P2)
            # [2]: Kategorie (Category)
            # [3]: Unterkategorie (Subcategory) - German
            # [4]: Person
            # [5]: Index No.
            # [6]: Inhalt (Description)

            index_no = row[5].strip() if len(row) > 5 else ''
            if not index_no:
                continue

            # Skip non-numeric indexes (totals, headers)
            if not any(c.isdigit() for c in index_no):
                continue

            category = row[2].strip() if len(row) > 2 else ''
            subcategory = row[3].strip() if len(row) > 3 else ''
            description = row[6].strip() if len(row) > 6 else ''

            indexes.append({
                'index': index_no,
                'category': category,
                'subcategory': subcategory,
                'description': description,
                'row': i
            })

            if subcategory:
                subcategories.add(subcategory)
            if category:
                by_category[category] += 1

    print(f'\n✅ Found {len(indexes)} tax indexes\n')

    print('Breakdown by Category:')
    for cat, count in sorted(by_category.items()):
        print(f'   - {cat}: {count}')

    print(f'\n\nUnique Subcategories ({len(subcategories)}):')
    for subcat in sorted(subcategories):
        print(f'   - "{subcat}"')

    print('\n\nFirst 20 indexes:')
    for idx in indexes[:20]:
        print(f"   {idx['index']:8} | {idx['category']:30} | {idx['subcategory']:40} | {idx['description'][:50]}")

    print('\n\nAll index numbers:')
    all_indexes = sorted(set(idx['index'] for idx in indexes))
    print(f'   Total unique indexes: {len(all_indexes)}')
    print(f'   Indexes: {", ".join(all_indexes[:30])}...')

if __name__ == '__main__':
    main()
