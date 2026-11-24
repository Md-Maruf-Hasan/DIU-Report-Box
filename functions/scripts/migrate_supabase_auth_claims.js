const admin = require("firebase-admin");

admin.initializeApp();

async function migrateUsers() {
  let pageToken;
  let migratedCount = 0;

  do {
    const page = await admin.auth().listUsers(1000, pageToken);

    for (const user of page.users) {
      const currentClaims = user.customClaims || {};
      const appRole =
        currentClaims.appRole ||
        (currentClaims.role === "admin" ? "admin" : "student");

      await admin.auth().setCustomUserClaims(user.uid, {
        ...currentClaims,
        role: "authenticated",
        appRole,
      });
      migratedCount += 1;
    }

    pageToken = page.pageToken;
  } while (pageToken);

  console.log(`Updated Supabase-compatible claims for ${migratedCount} users.`);
}

migrateUsers().catch((error) => {
  console.error("Failed to migrate Firebase auth claims:", error);
  process.exitCode = 1;
});
