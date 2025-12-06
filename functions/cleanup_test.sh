#!/bin/bash

ACCESS_TOKEN=$(cat ~/.config/configstore/firebase-tools.json | python3 -c "import json, sys; print(json.load(sys.stdin)['tokens']['access_token'])" 2>/dev/null)

curl -s -X DELETE \
  "https://firestore.googleapis.com/v1/projects/taxedgmbh/databases/taxedgmbh/documents/taxIndexes/ZH_TEST_2024" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" > /dev/null

echo "✅ Cleaned up test document"
