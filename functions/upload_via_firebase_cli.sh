#!/bin/bash

# Upload Tax Indexes via Firebase CLI + REST API
# This uses the current Firebase CLI authentication

echo "=========================================="
echo "Uploading Zürich Tax Indexes via REST API"
echo "=========================================="

# Get Firebase access token
ACCESS_TOKEN=$(firebase login:ci --no-localhost 2>&1 | grep -oE '1//[A-Za-z0-9_-]+' | head -1)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Failed to get access token. Trying alternative method..."
    ACCESS_TOKEN=$(cat ~/.config/firebase/.token 2>/dev/null || echo "")
fi

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ No access token found. Please ensure you're logged in with 'firebase login'"
    exit 1
fi

echo "✅ Got access token"

# Project and database IDs
PROJECT_ID="taxedgmbh"
DATABASE_ID="taxedgmbh"

# Function to upload a single document
upload_document() {
    local CANTON=$1
    local INDEX=$2
    local JSON_DATA=$3

    DOC_ID="${CANTON}_${INDEX}_2024"

    echo "[Uploading] $DOC_ID..."

    # Use Firestore REST API
    curl -X PATCH \
        "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/taxIndexes/${DOC_ID}?currentDocument.exists=false" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${JSON_DATA}" \
        2>&1 | grep -q "error" && echo "  ❌ Failed" || echo "  ✅ Success"
}

# Upload Index 100 - Haupterwerb Person 1
upload_document "ZH" "100" '{
  "fields": {
    "Canton": {"stringValue": "ZH"},
    "Index": {"stringValue": "100"},
    "Tax_Year": {"integerValue": "2024"},
    "Main_Category": {"stringValue": "Einkünfte aus unselbständiger Erwerbstätigkeit"},
    "Sub_Category": {"stringValue": "Haupterwerb"},
    "Person": {"stringValue": "Person 1"},
    "Legal_Reference_Canton": {"stringValue": "§ 17 Abs. 1 StG ZH"},
    "Legal_Reference_Federal": {"stringValue": "Art. 17 Abs. 1 DBG"},
    "Rational_Explanation": {"stringValue": "Das Einkommen aus unselbständiger Erwerbstätigkeit umfasst sämtliche Bezüge aus einem Arbeitsverhältnis, einschliesslich Lohn, Gehalt, Gratifikationen und geldwerte Vorteile."},
    "Deductibility_Rules": {"stringValue": "Vollumfänglich steuerbar."},
    "Max_Deductible": {"stringValue": "Nicht zutreffend (Einkommensposten)"},
    "Limitations": {"stringValue": "Lohnausweis erforderlich."},
    "Source": {"stringValue": "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html"}
  }
}'

echo ""
echo "=========================================="
echo "Upload complete!"
echo "=========================================="
echo ""
echo "Verify at:"
echo "https://console.firebase.google.com/project/taxedgmbh/firestore/databases/taxedgmbh/data/~2FtaxIndexes"
