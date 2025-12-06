#!/bin/bash

# Upload SO canton data using Firebase CLI
TOKEN="1//09MmkJ2r7kTOfCgYIARAAGAkSNwF-L9IrAtnYgN4ZiRGHZ3eTH3kImCH-rqpcXW3hDk3Yo5_63KgBSRhGtC-nuNejJUpHA5Uz0ak"
PROJECT="taxedgmbh"

echo "🚀 Uploading SO canton tax indexes using Firebase CLI"
echo "================================================="

# Create a temporary JSON file for import
cat > /tmp/taxIndexes_import.json << 'EOF'
{
  "__collections__": {
    "taxIndexes": {
      "SO_100": {
        "Canton": "SO",
        "Index": "100",
        "Main_Category": "Einkommen",
        "Sub_Category": "Haupterwerb (Main employment)",
        "Person": "Person 1",
        "canton": "SO",
        "index": "100",
        "mainCategory": "Einkommen",
        "subcategory": "Haupterwerb (Main employment)",
        "person": "Person 1",
        "Description_DE": "Einkünfte aus unselbständiger Erwerbstätigkeit",
        "__collections__": {}
      },
      "SO_101": {
        "Canton": "SO",
        "Index": "101",
        "Main_Category": "Einkommen",
        "Sub_Category": "Haupterwerb (Main employment)",
        "Person": "Person 2",
        "canton": "SO",
        "index": "101",
        "mainCategory": "Einkommen",
        "subcategory": "Haupterwerb (Main employment)",
        "person": "Person 2",
        "Description_DE": "Einkünfte aus unselbständiger Erwerbstätigkeit",
        "__collections__": {}
      },
      "SO_300": {
        "Canton": "SO",
        "Index": "300",
        "Main_Category": "Einkommen",
        "Sub_Category": "Wertschriftenertrag",
        "canton": "SO",
        "index": "300",
        "mainCategory": "Einkommen",
        "subcategory": "Wertschriftenertrag",
        "Description_DE": "Wertschriftenertrag (Securities Income)",
        "__collections__": {}
      },
      "SO_500": {
        "Canton": "SO",
        "Index": "500",
        "Main_Category": "Sonstiges",
        "Sub_Category": "Person 1",
        "Person": "Person 1",
        "canton": "SO",
        "index": "500",
        "mainCategory": "Sonstiges",
        "subcategory": "Person 1",
        "person": "Person 1",
        "Description_DE": "Berufsauslagen bei unselbständiger Erwerbstätigkeit",
        "__collections__": {}
      }
    }
  }
}
EOF

echo "📁 Created import file: /tmp/taxIndexes_import.json"
echo ""

# Try to import using Firebase CLI
echo "⏳ Attempting Firebase import..."
firebase firestore:import /tmp/taxIndexes_import.json --token "$TOKEN" --project "$PROJECT" 2>&1

echo ""
echo "✅ If successful, check your Firebase Console:"
echo "   https://console.firebase.google.com/project/taxedgmbh/firestore/data/~2FtaxIndexes"