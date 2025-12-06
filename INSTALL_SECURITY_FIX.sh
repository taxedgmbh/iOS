#!/bin/bash
#
# Security Fix Installation Script
# Deploys custom claims-based workspace security for Firebase Storage
#

set -e  # Exit on any error

echo "🔐 =========================================="
echo "   Security Fix Deployment Script"
echo "   Workspace Claims-Based Access Control"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Firebase authentication
echo "📋 Step 1/6: Checking Firebase authentication..."
if ! firebase projects:list > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Firebase credentials expired or not logged in${NC}"
    echo ""
    echo "Please run: firebase login --reauth"
    echo ""
    echo "Then re-run this script."
    exit 1
fi
echo -e "${GREEN}✅ Firebase authenticated${NC}"
echo ""

# Step 2: Build Cloud Functions
echo "📋 Step 2/6: Building TypeScript Cloud Functions..."
cd functions
npm install > /dev/null 2>&1
npm run build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ TypeScript build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Cloud Functions built successfully${NC}"
cd ..
echo ""

# Step 3: Deploy Cloud Functions
echo "📋 Step 3/6: Deploying Cloud Functions to Firebase..."
echo "   This will deploy:"
echo "   - updateWorkspaceClaims (callable)"
echo "   - onWorkspaceMembershipChange (Firestore trigger)"
echo "   - getUserClaims (debug)"
echo ""
firebase deploy --only functions --force
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Cloud Functions deployment failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Cloud Functions deployed successfully${NC}"
echo ""

# Step 4: Deploy Storage Rules
echo "📋 Step 4/6: Deploying updated Storage Rules..."
echo "   This will enforce workspace membership verification"
echo ""
firebase deploy --only storage --force
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Storage Rules deployment failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Storage Rules deployed successfully${NC}"
echo ""

# Step 5: Prompt for migration
echo "📋 Step 5/6: Migrate existing users..."
echo ""
echo -e "${YELLOW}⚠️  You need to run the migration script to populate claims for existing users${NC}"
echo ""
echo "Run this command to migrate all existing users:"
echo ""
echo -e "${GREEN}cd functions && node -e \"\$(cat <<'MIGRATION_SCRIPT'
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
db.settings({ databaseId: 'taxedgmbh' });

async function migrateAllUsers() {
  const auth = admin.auth();
  let nextPageToken;
  let userCount = 0;

  do {
    const listUsersResult = await auth.listUsers(1000, nextPageToken);

    for (const userRecord of listUsersResult.users) {
      try {
        // Get user's workspaces
        const workspacesSnapshot = await db
          .collection('workspaces')
          .where('memberIds', 'array-contains', userRecord.uid)
          .get();

        const workspaces = {};
        workspacesSnapshot.docs.forEach(doc => {
          workspaces[doc.id] = true;
        });

        // Set custom claims
        await auth.setCustomUserClaims(userRecord.uid, {
          workspaces: workspaces,
          claimsUpdatedAt: Date.now()
        });

        userCount++;
        console.log(\\\`✅ Migrated user: \\\${userRecord.email} (\\\${Object.keys(workspaces).length} workspaces)\\\`);

      } catch (error) {
        console.error(\\\`❌ Failed to migrate user \\\${userRecord.uid}:\\\`, error);
      }
    }

    nextPageToken = listUsersResult.pageToken;
  } while (nextPageToken);

  console.log(\\\`\\n✅ Migration complete: \\\${userCount} users processed\\\`);
}

migrateAllUsers().catch(console.error);
MIGRATION_SCRIPT
)\"${NC}"
echo ""
read -p "Press Enter after running the migration script..."
echo ""

# Step 6: Add FirebaseFunctions to Xcode (manual step)
echo "📋 Step 6/6: Add FirebaseFunctions to Xcode..."
echo ""
echo -e "${YELLOW}⚠️  MANUAL STEP REQUIRED:${NC}"
echo ""
echo "You need to add FirebaseFunctions dependency to your Xcode project:"
echo ""
echo "Option 1 - Via Xcode UI:"
echo "  1. Open TaxedGmbH_IOS.xcodeproj in Xcode"
echo "  2. Select the project in navigator"
echo "  3. Select TaxedGmbH_IOS target"
echo "  4. Go to 'General' tab → 'Frameworks, Libraries, and Embedded Content'"
echo "  5. Click '+' button"
echo "  6. Search for 'FirebaseFunctions'"
echo "  7. Add it to the project"
echo "  8. Build the project (⌘+B)"
echo ""
echo "Option 2 - Via Swift Package Manager:"
echo "  Run: xed ."
echo "  Then: File → Add Package Dependencies"
echo "  Search: https://github.com/firebase/firebase-ios-sdk"
echo "  Select: FirebaseFunctions"
echo "  Add Package"
echo ""
echo -e "${GREEN}After adding the dependency, run: xcodebuild build -scheme TaxedGmbH_IOS${NC}"
echo ""

# Summary
echo "🔐 =========================================="
echo "   Deployment Summary"
echo "=========================================="
echo ""
echo -e "${GREEN}✅ Cloud Functions deployed${NC}"
echo -e "${GREEN}✅ Storage Rules deployed${NC}"
echo -e "${YELLOW}⚠️  Migration pending (run the script above)${NC}"
echo -e "${YELLOW}⚠️  Xcode dependency pending (add FirebaseFunctions)${NC}"
echo ""
echo "📖 See SECURITY_FIX_DEPLOYMENT.md for complete documentation"
echo ""
echo "🧪 Next steps:"
echo "  1. Run the migration script"
echo "  2. Add FirebaseFunctions to Xcode"
echo "  3. Build the iOS app"
echo "  4. Test security (see SECURITY_FIX_DEPLOYMENT.md Step 7)"
echo ""
echo "🔐 Security Status: Implementation complete, testing required"
echo ""
