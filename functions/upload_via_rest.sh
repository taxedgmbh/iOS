#!/bin/bash

# Upload SO canton tax indexes via Firestore REST API
# This uses anonymous access if enabled, or will show the authentication requirement

PROJECT_ID="taxedgmbh"
COLLECTION="taxIndexes"

# Function to create a document
create_document() {
    local doc_id=$1
    local json_data=$2

    echo "Uploading document: $doc_id"

    # Try to create the document using the REST API
    curl -X PATCH \
        "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}/${doc_id}" \
        -H 'Content-Type: application/json' \
        -d "$json_data" \
        2>/dev/null | python3 -m json.tool 2>/dev/null || echo "Failed: Authentication required"

    echo ""
}

# Test with a simple document first
echo "🚀 Testing Firestore REST API access..."
echo "Project: $PROJECT_ID"
echo "Collection: $COLLECTION"
echo "="
echo ""

# Create test document for SO_100 (Main employment Person 1)
TEST_DOC='{
  "fields": {
    "Canton": {"stringValue": "SO"},
    "Index": {"stringValue": "100"},
    "Main_Category": {"stringValue": "Einkommen"},
    "Sub_Category": {"stringValue": "Haupterwerb (Main employment)"},
    "Person": {"stringValue": "Person 1"},
    "canton": {"stringValue": "SO"},
    "index": {"stringValue": "100"},
    "mainCategory": {"stringValue": "Einkommen"},
    "subcategory": {"stringValue": "Haupterwerb (Main employment)"},
    "person": {"stringValue": "Person 1"},
    "Description_DE": {"stringValue": "Einkünfte aus unselbständiger Erwerbstätigkeit"},
    "Field1_Name_DE": {"stringValue": "Bruttolohn"},
    "Field1_Type": {"stringValue": "currency"},
    "Field1_Required": {"booleanValue": true},
    "Currency_Required": {"booleanValue": false},
    "FX_Required": {"booleanValue": false},
    "Display_Formula": {"stringValue": "Field1"},
    "Notes": {"stringValue": "From Lohnausweis"}
  }
}'

create_document "SO_100" "$TEST_DOC"

# If the above works, we can continue with more documents
echo "📋 Key tax index mappings for SO canton:"
echo ""
echo "Income categories:"
echo "  • SO_100: Main employment (Person 1) - Haupterwerb"
echo "  • SO_101: Main employment (Person 2) - Haupterwerb"
echo "  • SO_300: Securities income - Wertschriftenertrag"
echo ""
echo "Deductions:"
echo "  • SO_500: Professional expenses (Person 1) - Berufsauslagen"
echo "  • SO_540: Pillar 3a contributions (Person 1)"
echo ""
echo "Assets/Liabilities:"
echo "  • SO_900: Assets - Vermögen"
echo "  • SO_920: Debts - Schulden"
echo ""
echo "⚠️ If authentication is required:"
echo "1. You'll need to add Firebase Auth to the request"
echo "2. Or enable anonymous access in Firestore Rules (temporary)"
echo "3. Or use the Firebase Console to manually import the data"