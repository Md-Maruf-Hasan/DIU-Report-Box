const admin = require("firebase-admin");

if (process.env.FIRESTORE_EMULATOR_HOST) {
  admin.initializeApp({ projectId: "diu-report-box" });
} else {
  admin.initializeApp();
}

const email = process.argv[2];
const role = process.argv[3] || "admin";

if (!email) {
  console.error("Usage: node scripts/set_admin_role.js <user-email> [role]");
  process.exit(1);
}

async function setRole() {
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, {
      ...user.customClaims,
      role: "authenticated",
      appRole: role,
    });
    await admin.firestore().collection("users").doc(user.uid).set(
      { role },
      { merge: true }
    );
    console.log(`Successfully assigned role "${role}" to ${email} (UID: ${user.uid})`);
  } catch (err) {
    console.error("Error setting custom claim role:", err);
    process.exit(1);
  }
}

setRole();
