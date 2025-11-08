#!/bin/bash

# Diagnostic script to check workspace permission issue
# This will help identify why Firebase Storage rules are failing

WORKSPACE_ID="V59XKFt4De8ooBKlAULx"
DATABASE="taxedgmbh"

echo "🔍 WORKSPACE PERMISSION DIAGNOSTIC"
echo "=================================="
echo ""
echo "Workspace ID: $WORKSPACE_ID"
echo "Database: $DATABASE"
echo ""

# Check if Firebase CLI is logged in
echo "1️⃣ Checking Firebase authentication..."
firebase projects:list 2>&1 | grep -q "$DATABASE" && echo "   ✅ Authenticated to project: $DATABASE" || echo "   ❌ Not authenticated to Firebase"
echo ""

# Note: Firebase CLI doesn't have direct Firestore document read commands
# We need to check via Firestore console or use the app's AuthenticationService

echo "2️⃣ Workspace data needs to be checked in Firestore Console:"
echo "   URL: https://console.firebase.google.com/project/$DATABASE/firestore/databases/$DATABASE/data/workspaces/$WORKSPACE_ID"
echo ""

echo "3️⃣ Please verify in Firebase Console:"
echo "   - Does workspace document exist?"
echo "   - Does it have a 'memberIds' field?"
echo "   - What values are in the 'memberIds' array?"
echo "   - Does it match the authenticated user's UID?"
echo ""

echo "4️⃣ To get user's Firebase Auth UID:"
echo "   - Check app console logs for: '🔍 DEBUG Upload Context'"
echo "   - Look for 'User ID: [uid]'"
echo ""

echo "5️⃣ Storage Rules Check:"
echo "   The rule checks: userId in workspace.data.memberIds"
echo "   Path: /databases/$DATABASE/documents/workspaces/$WORKSPACE_ID"
echo ""

echo "📋 ACTION ITEMS:"
echo "   [ ] 1. Check Firestore console for workspace: $WORKSPACE_ID"
echo "   [ ] 2. Note the memberIds array values"
echo "   [ ] 3. Check app console for 'User ID:' in debug output"
echo "   [ ] 4. Compare: Is User ID in memberIds array?"
echo ""
