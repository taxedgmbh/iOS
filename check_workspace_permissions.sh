#!/bin/bash

# Script to check workspace permissions in Firestore
# This will help diagnose why storage rules are failing

WORKSPACE_ID="V59XKFt4De8ooBKlAULx"

echo "🔍 Checking workspace: $WORKSPACE_ID"
echo ""

# Check if workspace exists
echo "📋 Workspace document:"
firebase firestore:get workspaces/$WORKSPACE_ID --project taxedgmbh 2>&1

echo ""
echo "---"
echo ""
