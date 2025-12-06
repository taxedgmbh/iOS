/**
 * Workspace Claims Manager
 *
 * Manages custom claims for workspace membership in user JWT tokens.
 * This enables Firebase Storage Rules to verify workspace access without querying Firestore.
 *
 * Security Model:
 * - User custom claims contain a "workspaces" object mapping workspaceId -> true
 * - Storage Rules can check: request.auth.token.workspaces[workspaceId] == true
 * - Claims are updated when users join/leave workspaces
 * - Maximum 1000 bytes for custom claims (approximately 15-20 workspaces)
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

/**
 * Maximum size of custom claims in bytes
 * Firebase has a hard limit of 1000 bytes for custom claims
 */
const MAX_CLAIMS_SIZE = 1000;

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
 * Update user's workspace membership custom claims
 *
 * This function is called whenever a user's workspace membership changes:
 * - When user joins a workspace
 * - When user leaves a workspace
 * - When user is removed from a workspace
 * - On user login (to sync claims with Firestore)
 *
 * @param userId - The Firebase Auth UID of the user
 * @returns Promise<void>
 */
export async function updateUserWorkspaceClaims(userId: string): Promise<void> {
  try {
    console.log(`🔐 Updating workspace claims for user: ${userId}`);

    // Get user's workspace memberships from Firestore
    const db = getDb();
    const workspacesSnapshot = await db
      .collection("workspaces")
      .where("memberIds", "array-contains", userId)
      .get();

    // Build workspaces claim object: { workspaceId: true, ... }
    const workspaceClaims: { [key: string]: boolean } = {};

    workspacesSnapshot.docs.forEach((doc) => {
      workspaceClaims[doc.id] = true;
    });

    console.log(`   Found ${Object.keys(workspaceClaims).length} workspace memberships`);

    // Validate claims size
    const claimsJson = JSON.stringify({ workspaces: workspaceClaims });
    const claimsSize = Buffer.byteLength(claimsJson, "utf8");

    if (claimsSize > MAX_CLAIMS_SIZE) {
      console.warn(`⚠️  Claims size (${claimsSize} bytes) exceeds limit (${MAX_CLAIMS_SIZE} bytes)`);
      console.warn(`   User has too many workspace memberships (${Object.keys(workspaceClaims).length})`);
      throw new Error(`User has too many workspace memberships to fit in custom claims`);
    }

    console.log(`   Claims size: ${claimsSize} bytes (${MAX_CLAIMS_SIZE} max)`);

    // Update user's custom claims
    await admin.auth().setCustomUserClaims(userId, {
      workspaces: workspaceClaims,
      claimsUpdatedAt: Date.now(),
    });

    console.log(`✅ Successfully updated workspace claims for user: ${userId}`);
    console.log(`   Workspaces: ${Object.keys(workspaceClaims).join(", ") || "none"}`);

  } catch (error) {
    console.error(`❌ Failed to update workspace claims for user ${userId}:`, error);
    throw error;
  }
}

/**
 * Callable Cloud Function: Update Workspace Claims
 *
 * Called by iOS client when:
 * - User logs in (to sync claims with current workspace memberships)
 * - User joins/creates a workspace
 * - User leaves a workspace
 *
 * Authentication required.
 *
 * Request: {}
 * Response: { success: true, workspaceCount: number }
 */
export const updateWorkspaceClaims = functions.https.onCall(
  async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to update workspace claims"
      );
    }

    const userId = context.auth.uid;
    console.log(`📱 iOS client requested claims update for user: ${userId}`);

    try {
      await updateUserWorkspaceClaims(userId);

      // Get updated claims to return workspace count
      const user = await admin.auth().getUser(userId);
      const workspaces = (user.customClaims?.workspaces as { [key: string]: boolean }) || {};
      const workspaceCount = Object.keys(workspaces).length;

      return {
        success: true,
        workspaceCount,
        message: `Workspace claims updated successfully (${workspaceCount} workspaces)`,
      };

    } catch (error) {
      console.error("❌ updateWorkspaceClaims failed:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to update workspace claims",
        error instanceof Error ? error.message : "Unknown error"
      );
    }
  }
);

/**
 * Firestore Trigger: Auto-update claims when workspace membership changes
 *
 * Triggers when:
 * - Workspace document is created (owner gets claims)
 * - Workspace document is updated (members added/removed)
 * - Workspace document is deleted (all members lose claims)
 *
 * This ensures claims stay in sync with Firestore without manual iOS calls.
 */
export const onWorkspaceMembershipChange = functions.firestore
  .document("workspaces/{workspaceId}")
  .onWrite(async (change, context) => {
    const workspaceId = context.params.workspaceId;

    try {
      // Get members before and after the change
      const beforeMembers = (change.before.data()?.memberIds as string[]) || [];
      const afterMembers = (change.after.data()?.memberIds as string[]) || [];

      // Find all affected users (added or removed)
      const allAffectedUsers = new Set([...beforeMembers, ...afterMembers]);

      console.log(`🔄 Workspace ${workspaceId} membership changed`);
      console.log(`   Before: ${beforeMembers.length} members`);
      console.log(`   After: ${afterMembers.length} members`);
      console.log(`   Affected users: ${allAffectedUsers.size}`);

      // Update claims for all affected users in parallel
      const updatePromises = Array.from(allAffectedUsers).map((userId) =>
        updateUserWorkspaceClaims(userId).catch((error) => {
          console.error(`Failed to update claims for user ${userId}:`, error);
          // Don't throw - continue updating other users
        })
      );

      await Promise.all(updatePromises);

      console.log(`✅ Workspace membership claims updated for ${allAffectedUsers.size} users`);

    } catch (error) {
      console.error(`❌ onWorkspaceMembershipChange failed for workspace ${workspaceId}:`, error);
      // Don't throw - this is a background trigger
    }
  });

/**
 * Callable Cloud Function: Get User's Current Claims (for debugging)
 *
 * Returns the user's current custom claims.
 * Useful for debugging and verifying claims are set correctly.
 *
 * Authentication required.
 *
 * Response: { claims: object }
 */
export const getUserClaims = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  try {
    const user = await admin.auth().getUser(context.auth.uid);
    return {
      claims: user.customClaims || {},
      message: "Custom claims retrieved successfully",
    };
  } catch (error) {
    throw new functions.https.HttpsError(
      "internal",
      "Failed to get user claims",
      error instanceof Error ? error.message : "Unknown error"
    );
  }
});
