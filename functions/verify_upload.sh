#!/bin/bash

ACCESS_TOKEN=$(cat ~/.config/configstore/firebase-tools.json | python3 -c "import json, sys; print(json.load(sys.stdin)['tokens']['access_token'])" 2>/dev/null)

curl -s "https://firestore.googleapis.com/v1/projects/taxedgmbh/databases/taxedgmbh/documents/taxIndexes" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'documents' in data:
    print(f\"✅ Found {len(data['documents'])} documents in taxIndexes collection:\")
    for doc in data['documents']:
        doc_id = doc['name'].split('/')[-1]
        canton = doc['fields']['Canton']['stringValue']
        index = doc['fields']['Index']['stringValue']
        print(f\"  - {doc_id}: Canton {canton}, Index {index}\")
else:
    print('No documents found')
"
