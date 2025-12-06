#!/bin/bash

ACCESS_TOKEN=$(cat ~/.config/configstore/firebase-tools.json | python3 -c "import json, sys; print(json.load(sys.stdin)['tokens']['access_token'])" 2>/dev/null)

# Test single upload with full output
curl -X PATCH \
  "https://firestore.googleapis.com/v1/projects/taxedgmbh/databases/taxedgmbh/documents/taxIndexes/ZH_100_2024" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"fields":{"Canton":{"stringValue":"ZH"},"Index":{"stringValue":"100"}}}'
