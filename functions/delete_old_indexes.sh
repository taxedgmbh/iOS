#!/bin/bash

ACCESS_TOKEN=$(cat ~/.config/configstore/firebase-tools.json | python3 -c "import json, sys; print(json.load(sys.stdin)['tokens']['access_token'])" 2>/dev/null)

# Delete all existing documents first
for INDEX in 100 101 102 103 120 121 130 131 140 141; do
  echo "Deleting ZH_${INDEX}_2024..."
  curl -s -X DELETE \
    "https://firestore.googleapis.com/v1/projects/taxedgmbh/databases/taxedgmbh/documents/taxIndexes/ZH_${INDEX}_2024" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" > /dev/null
done

echo "✅ Old documents deleted"
