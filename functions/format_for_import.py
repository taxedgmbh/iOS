#!/usr/bin/env python3

"""
Format SO canton tax indexes for easy Firebase Console import
"""

import json
import csv

# Read the JSON file
with open('so_indexes.json', 'r') as f:
    data = json.load(f)

# Create simplified import format
print("🔥 FIREBASE CONSOLE IMPORT INSTRUCTIONS")
print("=" * 80)
print("\n1. Go to Firebase Console:")
print("   https://console.firebase.google.com/project/taxedgmbh/firestore\n")
print("2. Create the 'taxIndexes' collection if it doesn't exist\n")
print("3. Add these key documents for SO canton:\n")
print("-" * 80)

# Key documents to import first
key_docs = [
    "SO_100",  # Main employment Person 1
    "SO_101",  # Main employment Person 2
    "SO_300",  # Securities income
    "SO_310",  # Maintenance contributions
    "SO_500",  # Professional expenses P1
    "SO_540",  # Pillar 3a P1
    "SO_550",  # Pillar 3a P2
    "SO_900",  # Assets
    "SO_920",  # Debts
]

# Print each document in a copy-paste friendly format
for doc_id in key_docs:
    if doc_id in data:
        doc = data[doc_id]
        print(f"\n📄 DOCUMENT ID: {doc_id}")
        print(f"Description: {doc.get('Description_DE', doc.get('Sub_Category', ''))}")
        print("-" * 40)

        # Print essential fields only
        essential_fields = {
            "Canton": doc.get("Canton"),
            "Index": doc.get("Index"),
            "Main_Category": doc.get("Main_Category"),
            "Sub_Category": doc.get("Sub_Category"),
            "Person": doc.get("Person"),
            "canton": doc.get("canton"),
            "index": doc.get("index"),
            "mainCategory": doc.get("mainCategory"),
            "subcategory": doc.get("subcategory"),
            "person": doc.get("person"),
        }

        print("FIELDS TO ADD:")
        for field, value in essential_fields.items():
            if value:
                print(f"  {field}: {value}")
        print("")

print("\n" + "=" * 80)
print("\n✅ QUICK TEST:")
print("After adding SO_100, test in your app by:")
print("1. Setting canton to 'SO' in user profile")
print("2. Uploading a document with category 'salary' (Haupterwerb)")
print("3. The document should show Index: 100")

# Also create a simple CSV for bulk import
with open('so_indexes_import.csv', 'w', newline='') as csvfile:
    fieldnames = ['Document_ID', 'Canton', 'Index', 'Main_Category', 'Sub_Category',
                  'Person', 'Description_DE', 'canton', 'index', 'mainCategory',
                  'subcategory', 'person']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

    writer.writeheader()
    for doc_id, doc in data.items():
        row = {
            'Document_ID': doc_id,
            'Canton': doc.get('Canton', ''),
            'Index': doc.get('Index', ''),
            'Main_Category': doc.get('Main_Category', ''),
            'Sub_Category': doc.get('Sub_Category', ''),
            'Person': doc.get('Person', ''),
            'Description_DE': doc.get('Description_DE', ''),
            'canton': doc.get('canton', ''),
            'index': doc.get('index', ''),
            'mainCategory': doc.get('mainCategory', ''),
            'subcategory': doc.get('subcategory', ''),
            'person': doc.get('person', '')
        }
        writer.writerow(row)

print("\n💾 CSV file created: so_indexes_import.csv")
print("You can use this for bulk import if Firebase Console supports it")