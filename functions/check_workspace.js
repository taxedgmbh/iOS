const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'taxedgmbh' });

const db = admin.firestore();
db.settings({ databaseId: 'taxedgmbh' });

async function checkWorkspace() {
  try {
    // Check specific workspace
    const ws = await db.collection('workspaces').doc('V59XKFt4De8ooBKlAULx').get();
    if (ws.exists) {
      const data = ws.data();
      console.log('✅ Workspace V59XKFt4De8ooBKlAULx exists!');
      console.log('   Members:', data.members || []);
      console.log('   Owner:', data.owner || 'not set');
      console.log('   Name:', data.name || 'not set');
    } else {
      console.log('❌ Workspace V59XKFt4De8ooBKlAULx does not exist');
    }

    // List all workspaces
    const allWs = await db.collection('workspaces').get();
    console.log('\n📊 All workspaces:', allWs.size);
    allWs.docs.forEach(doc => {
      const data = doc.data();
      const memberCount = data.members ? data.members.length : 0;
      console.log(`   - ${doc.id}: ${memberCount} member(s)`);
      if (data.members && data.members.length > 0) {
        console.log(`     Members: ${data.members.join(', ')}`);
      }
    });

    // List all users
    console.log('\n👥 All users:');
    const listUsersResult = await admin.auth().listUsers();
    listUsersResult.users.forEach(user => {
      console.log(`   - ${user.uid}: ${user.email || 'no email'}`);
      if (user.customClaims && user.customClaims.workspaces) {
        const workspaceIds = Object.keys(user.customClaims.workspaces);
        console.log(`     Has claims for workspaces: ${workspaceIds.join(', ')}`);
      } else {
        console.log(`     No workspace claims set`);
      }
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  process.exit(0);
}

checkWorkspace();