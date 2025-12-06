/**
 * Migration Script: Populate Workspace Claims for Existing Users
 *
 * This script updates custom claims for all existing users so they can
 * access their workspace documents after the security fix deployment.
 *
 * Run this ONCE after deploying the security fix:
 *   node migrate_user_claims.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin using application default credentials
// This will use your Firebase CLI login credentials
admin.initializeApp({
  projectId: 'taxedgmbh'
});

// Get Firestore database instance (named database: "taxedgmbh")
const db = admin.firestore();
db.settings({ databaseId: 'taxedgmbh' });

/**
 * Update workspace claims for a single user
 */
async function updateUserWorkspaceClaims(userId) {
  try {
    console.log(`🔐 Updating claims for user: ${userId}`);

    // Get user's workspace memberships from Firestore
    const workspacesSnapshot = await db
      .collection('workspaces')
      .where('members', 'array-contains', userId)
      .get();

    // Build workspaces claim object
    const workspaceClaims = {};
    workspacesSnapshot.docs.forEach((doc) => {
      workspaceClaims[doc.id] = true;
    });

    console.log(`   Found ${Object.keys(workspaceClaims).length} workspace memberships`);

    // Update user's custom claims
    await admin.auth().setCustomUserClaims(userId, {
      workspaces: workspaceClaims,
      claimsUpdatedAt: Date.now(),
    });

    console.log(`✅ Updated claims for user: ${userId}`);
    console.log(`   Workspaces: ${Object.keys(workspaceClaims).join(', ') || 'none'}`);

    return { userId, workspaceCount: Object.keys(workspaceClaims).length };

  } catch (error) {
    console.error(`❌ Failed to update claims for user ${userId}:`, error.message);
    return { userId, error: error.message };
  }
}

/**
 * Main migration function
 */
async function migrateAllUsers() {
  console.log('🚀 Starting user claims migration...\n');

  try {
    // Get all users from Firebase Auth
    const listUsersResult = await admin.auth().listUsers();
    const users = listUsersResult.users;

    console.log(`📊 Found ${users.length} total users\n`);

    // Track results
    const results = {
      success: [],
      failed: [],
      noWorkspaces: []
    };

    // Process users one by one to avoid rate limits
    for (const user of users) {
      const result = await updateUserWorkspaceClaims(user.uid);

      if (result.error) {
        results.failed.push(result);
      } else if (result.workspaceCount === 0) {
        results.noWorkspaces.push(result);
      } else {
        results.success.push(result);
      }

      console.log(''); // Blank line between users
    }

    // Print summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 MIGRATION SUMMARY');
    console.log('='.repeat(60));
    console.log(`✅ Successfully updated: ${results.success.length} users`);
    console.log(`⚠️  No workspaces found: ${results.noWorkspaces.length} users`);
    console.log(`❌ Failed: ${results.failed.length} users`);
    console.log('='.repeat(60));

    if (results.success.length > 0) {
      console.log('\n✅ Users with workspace access:');
      results.success.forEach(r => {
        console.log(`   ${r.userId}: ${r.workspaceCount} workspace(s)`);
      });
    }

    if (results.noWorkspaces.length > 0) {
      console.log('\n⚠️  Users with no workspace memberships:');
      results.noWorkspaces.forEach(r => {
        console.log(`   ${r.userId}`);
      });
    }

    if (results.failed.length > 0) {
      console.log('\n❌ Failed users:');
      results.failed.forEach(r => {
        console.log(`   ${r.userId}: ${r.error}`);
      });
    }

    console.log('\n🎉 Migration completed!');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }

  process.exit(0);
}

// Run migration
migrateAllUsers();
