#!/bin/bash

# Get access token
ACCESS_TOKEN=$(cat ~/.config/configstore/firebase-tools.json | python3 -c "import json, sys; print(json.load(sys.stdin)['tokens']['access_token'])" 2>/dev/null)

# Test upload
curl -X PATCH \
  "https://firestore.googleapis.com/v1/projects/taxedgmbh/databases/taxedgmbh/documents/taxIndexes/ZH_TEST_2024" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "Canton": {"stringValue": "ZH"},
      "Index": {"stringValue": "TEST"},
      "Tax_Year": {"integerValue": "2024"}
    }
  }'
