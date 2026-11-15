import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import * as fs from "fs";
import * as path from "path";

const PROJECT_ID = "diu-report-box-test";

describe("DIU Report Box - Firestore Security Rules Unit Tests", () => {
  let testEnv: RulesTestEnvironment;

  before(async () => {
    const rules = fs.readFileSync(path.resolve(__dirname, "../../firestore.rules"), "utf8");
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules,
        host: "127.0.0.1",
        port: 8080,
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  // 1. Unverified user blocked
  it("blocks unverified users from reading posts", async () => {
    const unverifiedContext = testEnv.authenticatedContext("unverified_user", {
      email_verified: false,
    });
    const db = unverifiedContext.firestore();
    await assertFails(db.collection("lostFound").get());
  });

  // 2. Student cannot read another student's report
  it("prevents a student from reading another student's report", async () => {
    // Setup report as student A via admin context
    await testEnv.withSecurityRulesDisabled(async (adminContext) => {
      const adminDb = adminContext.firestore();
      await adminDb.collection("reports").doc("rep1").set({
        reporterUid: "student_a",
        departmentId: "swe",
        roomNo: "703",
        status: "submitted",
      });
    });

    const studentBContext = testEnv.authenticatedContext("student_b", {
      email_verified: true,
      role: "student",
    });
    const studentB = studentBContext.firestore();
    await assertFails(studentB.collection("reports").doc("rep1").get());

    const studentAContext = testEnv.authenticatedContext("student_a", {
      email_verified: true,
      role: "student",
    });
    const studentA = studentAContext.firestore();
    await assertSucceeds(studentA.collection("reports").doc("rep1").get());
  });

  // 3. Student cannot read maintenance contact numbers
  it("prevents students from reading maintenance contacts (admin only)", async () => {
    await testEnv.withSecurityRulesDisabled(async (adminContext) => {
      const adminDb = adminContext.firestore();
      await adminDb
        .collection("departments")
        .doc("swe")
        .collection("maintenanceContacts")
        .doc("contact1")
        .set({
          name: "SWE Maintenance Staff",
          phone: "8801711111111",
          active: true,
        });
    });

    const studentContext = testEnv.authenticatedContext("student_a", {
      email_verified: true,
      role: "student",
    });
    const studentDb = studentContext.firestore();
    await assertFails(
      studentDb
        .collection("departments")
        .doc("swe")
        .collection("maintenanceContacts")
        .doc("contact1")
        .get()
    );

    const adminContext = testEnv.authenticatedContext("admin_user", {
      email_verified: true,
      role: "admin",
    });
    const adminDb = adminContext.firestore();
    await assertSucceeds(
      adminDb
        .collection("departments")
        .doc("swe")
        .collection("maintenanceContacts")
        .doc("contact1")
        .get()
    );
  });

  // 4. Anonymous author not readable by students
  it("prevents students from reading anonymous post authors", async () => {
    await testEnv.withSecurityRulesDisabled(async (adminContext) => {
      const adminDb = adminContext.firestore();
      await adminDb.collection("postAuthors").doc("anon_post_1").set({
        postId: "anon_post_1",
        authorUid: "secret_author",
      });
    });

    const studentContext = testEnv.authenticatedContext("student_a", {
      email_verified: true,
      role: "student",
    });
    const studentDb = studentContext.firestore();
    await assertFails(studentDb.collection("postAuthors").doc("anon_post_1").get());

    const adminContext = testEnv.authenticatedContext("admin_user", {
      email_verified: true,
      role: "admin",
    });
    const adminDb = adminContext.firestore();
    await assertSucceeds(adminDb.collection("postAuthors").doc("anon_post_1").get());
  });
});
