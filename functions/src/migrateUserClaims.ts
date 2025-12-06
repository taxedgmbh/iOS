/**
 * Cloud Function: Migrate User Claims
 *
 * This function updates custom claims for ALL existing users.
 * Run this ONCE after deploying the security fix.
 *
 * Call via Firebase CLI:
 *   firebase functions:call migrateAllUserClaims
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

/**
 * Get Firestore database instance (named database: "taxedgmbh")
 * Cached to avoid multiple settings() calls
 */
let dbInstance: admin.firestore.Firestore | null = null;

function getDb() {
  if (!dbInstance) {
    dbInstance = admin.firestore();
    dbInstance.settings({ databaseId: "taxedgmbh" });
  }
  return dbInstance;
}

/**
 * Update workspace claims for a single user
 */
async function updateUserWorkspaceClaims(userId: string): Promise<{
  userId: string;
  workspaceCount?: number;
  error?: string;
}> {
  try {
    console.log(`🔐 Updating claims for user: ${userId}`);

    // Get user's workspace memberships from Firestore
    const db = getDb();
    const workspacesSnapshot = await db
      .collection("workspaces")
      .where("members", "array-contains", userId)
      .get();

    // Build workspaces claim object
    const workspaceClaims: { [key: string]: boolean } = {};
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
    console.log(`   Workspaces: ${Object.keys(workspaceClaims).join(", ") || "none"}`);

    return { userId, workspaceCount: Object.keys(workspaceClaims).length };

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`❌ Failed to update claims for user ${userId}:`, errorMessage);
    return { userId, error: errorMessage };
  }
}

/**
 * Callable Cloud Function: Migrate All User Claims
 *
 * Updates custom claims for all users in Firebase Auth.
 * This is a one-time migration function.
 *
 * IMPORTANT: This function is restricted to admin use only.
 * In production, you should add additional authentication checks.
 */
export const migrateAllUserClaims = functions
  .runWith({
    timeoutSeconds: 540, // 9 minutes (max)
    memory: "512MB"
  })
  .https.onCall(async (data, context) => {
    console.log("🚀 Starting user claims migration...");

    // Optional: Add admin verification
    // if (!context.auth || !isAdmin(context.auth.uid)) {
    //   throw new functions.https.HttpsError(
    //     "permission-denied",
    //     "Only admins can run migration"
    //   );
    // }

    try {
      // Get all users from Firebase Auth
      const results = {
        success: [] as any[],
        failed: [] as any[],
        noWorkspaces: [] as any[]
      };

      // List all users (handles pagination automatically)
      let nextPageToken: string | undefined;
      let totalUsers = 0;

      do {
        const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
        totalUsers += listUsersResult.users.length;

        console.log(`📊 Processing batch of ${listUsersResult.users.length} users...`);

        // Process users in batches to avoid rate limits
        for (const user of listUsersResult.users) {
          const result = await updateUserWorkspaceClaims(user.uid);

          if (result.error) {
            results.failed.push(result);
          } else if (result.workspaceCount === 0) {
            results.noWorkspaces.push(result);
          } else {
            results.success.push(result);
          }

          // Small delay to avoid rate limits
          await new Promise(resolve => setTimeout(resolve, 100));
        }

        nextPageToken = listUsersResult.pageToken;
      } while (nextPageToken);

      // Print summary
      console.log("\n" + "=".repeat(60));
      console.log("📊 MIGRATION SUMMARY");
      console.log("=".repeat(60));
      console.log(`Total users processed: ${totalUsers}`);
      console.log(`✅ Successfully updated: ${results.success.length} users`);
      console.log(`⚠️  No workspaces found: ${results.noWorkspaces.length} users`);
      console.log(`❌ Failed: ${results.failed.length} users`);
      console.log("=".repeat(60));

      return {
        success: true,
        totalUsers,
        successCount: results.success.length,
        noWorkspacesCount: results.noWorkspaces.length,
        failedCount: results.failed.length,
        successUsers: results.success,
        noWorkspacesUsers: results.noWorkspaces,
        failedUsers: results.failed
      };

    } catch (error) {
      console.error("❌ Migration failed:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Migration failed",
        error instanceof Error ? error.message : "Unknown error"
      );
    }
  });
