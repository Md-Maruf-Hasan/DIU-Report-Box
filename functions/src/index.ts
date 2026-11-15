import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { CONFIG } from "./config";
import { formatReportSms, getSmsProvider } from "./sms/smsGateway";

admin.initializeApp();
const db = admin.firestore();

// -----------------------------------------------------------------------------
// 1. Domain Validation: Reject non-university emails
// -----------------------------------------------------------------------------
export const validateEmailOnCreate = functions.auth.user().onCreate(async (user) => {
  const email = user.email || "";
  const domain = email.split("@")[1]?.toLowerCase();

  if (domain !== CONFIG.ALLOWED_EMAIL_DOMAIN.toLowerCase()) {
    console.warn(`[Security] Unauthorized email registration attempted: ${email}. Deleting account.`);
    try {
      await admin.auth().deleteUser(user.uid);
      await db.collection("users").doc(user.uid).delete();
    } catch (err) {
      console.error(`Failed to delete unauthorized user ${user.uid}:`, err);
    }
  } else {
    // Ensure default role is 'student' if not set
    const currentClaims = (await admin.auth().getUser(user.uid)).customClaims || {};
    if (!currentClaims.role) {
      await admin.auth().setCustomUserClaims(user.uid, { role: "student" });
    }
  }
});

// -----------------------------------------------------------------------------
// 2. Anonymous Q&A Posts
// -----------------------------------------------------------------------------
export const createAnonymousPost = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.email_verified) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in with a verified university email to post."
    );
  }

  const { title, body, imageUrl } = data;
  if (!title || typeof title !== "string" || title.trim().length === 0) {
    throw new functions.https.HttpsError("invalid-argument", "Title is required.");
  }
  if (!body || typeof body !== "string" || body.trim().length === 0) {
    throw new functions.https.HttpsError("invalid-argument", "Body is required.");
  }

  const postRef = db.collection("qaPosts").doc();
  const postId = postRef.id;

  const batch = db.batch();

  // Public document: absolutely NO authorUid or authorName
  batch.set(postRef, {
    title: title.trim(),
    body: body.trim(),
    imageUrl: imageUrl || null,
    isAnonymous: true,
    authorUid: null,
    authorName: null,
    likeCount: 0,
    commentCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Admin-only author document: stores true author identity securely
  const authorRef = db.collection("postAuthors").doc(postId);
  batch.set(authorRef, {
    postId,
    authorUid: context.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();
  return { success: true, postId };
});

export const createAnonymousComment = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.email_verified) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in with a verified university email to comment."
    );
  }

  const { postId, text } = data;
  if (!postId || typeof postId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "postId is required.");
  }
  if (!text || typeof text !== "string" || text.trim().length === 0) {
    throw new functions.https.HttpsError("invalid-argument", "Comment text is required.");
  }

  const commentRef = db.collection("qaPosts").doc(postId).collection("comments").doc();
  const commentId = commentRef.id;

  const batch = db.batch();

  // Public comment: NO authorUid or authorName
  batch.set(commentRef, {
    text: text.trim(),
    isAnonymous: true,
    authorUid: null,
    authorName: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Admin-only comment author document
  const commentAuthorRef = db.collection("commentAuthors").doc(commentId);
  batch.set(commentAuthorRef, {
    postId,
    commentId,
    authorUid: context.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Increment commentCount
  const postRef = db.collection("qaPosts").doc(postId);
  batch.update(postRef, {
    commentCount: admin.firestore.FieldValue.increment(1),
  });

  await batch.commit();
  return { success: true, commentId };
});

export const deleteAnonymousPost = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.email_verified) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  const { postId } = data;
  if (!postId) throw new functions.https.HttpsError("invalid-argument", "postId required.");

  const authorDoc = await db.collection("postAuthors").doc(postId).get();
  const isAdmin = context.auth.token.role === "admin";
  const isOwner = authorDoc.exists && authorDoc.data()?.authorUid === context.auth.uid;

  if (!isAdmin && !isOwner) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You can only delete your own posts."
    );
  }

  const batch = db.batch();
  batch.delete(db.collection("qaPosts").doc(postId));
  if (authorDoc.exists) {
    batch.delete(db.collection("postAuthors").doc(postId));
  }
  await batch.commit();
  return { success: true };
});

// -----------------------------------------------------------------------------
// 3. Specific Report Creation (Anti-spam rate limit 5/24h, Ref Counter)
// -----------------------------------------------------------------------------
export const createReport = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.email_verified) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in with a verified university email to submit a report."
    );
  }

  const uid = context.auth.uid;
  const { departmentId, roomId, roomNo, category, description, imageUrls } = data;

  if (!departmentId || !roomId || !roomNo || !category || !description) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Department, Room, Category, and Description are all required."
    );
  }

  if (typeof description !== "string" || description.trim().length < CONFIG.MIN_REPORT_DESC_LENGTH) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Description must be at least ${CONFIG.MIN_REPORT_DESC_LENGTH} characters.`
    );
  }

  // Enforce server-side rate limit: 5 reports per 24 hours per student
  const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const recentReportsSnap = await db
    .collection("reports")
    .where("reporterUid", "==", uid)
    .where("createdAt", ">=", twentyFourHoursAgo)
    .get();

  if (recentReportsSnap.size >= CONFIG.MAX_REPORTS_PER_DAY) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      `Anti-spam limit reached: You can submit at most ${CONFIG.MAX_REPORTS_PER_DAY} reports in a 24-hour period.`
    );
  }

  // Generate sequential reference number (e.g., R-1001) via transaction
  const counterRef = db.collection("metadata").doc("reportCounter");
  const reportRef = db.collection("reports").doc();

  // Get reporter user profile name
  const userDoc = await db.collection("users").doc(uid).get();
  const reporterName = userDoc.exists ? userDoc.data()?.name || "Student" : "Student";

  const result = await db.runTransaction(async (transaction) => {
    const counterDoc = await transaction.get(counterRef);
    let nextCount = 1001;
    if (counterDoc.exists) {
      nextCount = (counterDoc.data()?.current || 1000) + 1;
    }
    transaction.set(counterRef, { current: nextCount }, { merge: true });

    const refNo = `R-${nextCount}`;
    const reportData = {
      refNo,
      reporterUid: uid,
      reporterName,
      departmentId,
      roomId,
      roomNo,
      category,
      description: description.trim(),
      imageUrls: Array.isArray(imageUrls) ? imageUrls.slice(0, 3) : [],
      status: "submitted",
      smsStatus: "pending",
      smsAttempts: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    transaction.set(reportRef, reportData);
    return { reportId: reportRef.id, refNo };
  });

  return { success: true, ...result };
});

// -----------------------------------------------------------------------------
// 4. SMS Routing on Report Creation
// -----------------------------------------------------------------------------
export const onReportCreated = functions.firestore
  .document("reports/{reportId}")
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const reportId = context.params.reportId;
    console.log(`[ReportCreated] Processing report ${reportId}`);

    if (!report || report.smsStatus === "sent") {
      return;
    }

    const { departmentId, roomNo, category, description, refNo } = report;

    // Get department details for department code
    let deptCode = "DEPT";
    try {
      const deptDoc = await db.collection("departments").doc(departmentId).get();
      if (deptDoc.exists) {
        deptCode = deptDoc.data()?.code || deptDoc.data()?.name || "DEPT";
      }
    } catch (e) {
      console.warn("Could not fetch dept code:", e);
    }

    // Lookup maintenance contacts for the department
    const contactsSnap = await db
      .collection("departments")
      .doc(departmentId)
      .collection("maintenanceContacts")
      .where("active", "==", true)
      .get();

    if (contactsSnap.empty) {
      console.warn(`No active maintenance contacts found for department ${departmentId}`);
      await snap.ref.update({
        smsStatus: "failed",
        smsAttempts: admin.firestore.FieldValue.increment(1),
        lastSmsError: "No active maintenance contacts registered for this department.",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    // Filter contacts if category matching is configured
    const matchingContacts = contactsSnap.docs.filter((doc) => {
      const data = doc.data();
      if (!data.categories || data.categories.length === 0) return true;
      return data.categories.includes(category);
    });

    const targetContacts = matchingContacts.length > 0 ? matchingContacts : contactsSnap.docs;

    const message = formatReportSms({
      deptCode,
      roomNo,
      category,
      description,
      refNo,
    });

    const smsProvider = getSmsProvider();
    let anySuccess = false;
    let lastError = "";

    for (const contactDoc of targetContacts) {
      const phone = contactDoc.data().phone;
      if (!phone) continue;

      const result = await smsProvider.sendSms(phone, message);
      if (result.success) {
        anySuccess = true;
      } else {
        lastError = result.error || "SMS failed";
      }
    }

    await snap.ref.update({
      smsStatus: anySuccess ? "sent" : "failed",
      smsAttempts: admin.firestore.FieldValue.increment(1),
      lastSmsError: anySuccess ? null : lastError,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

// -----------------------------------------------------------------------------
// 5. Retry Failed SMS (Scheduled / Callable)
// -----------------------------------------------------------------------------
export const retryFailedSms = functions.https.onCall(async (data, context) => {
  // Allow admins or internal scheduled caller
  if (context.auth && context.auth.token.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Admin only.");
  }

  const failedReportsSnap = await db
    .collection("reports")
    .where("smsStatus", "in", ["failed", "pending"])
    .where("smsAttempts", "<", CONFIG.MAX_SMS_ATTEMPTS)
    .limit(20)
    .get();

  const smsProvider = getSmsProvider();
  let retriedCount = 0;

  for (const doc of failedReportsSnap.docs) {
    const report = doc.data();
    const { departmentId, roomNo, category, description, refNo } = report;

    let deptCode = "DEPT";
    const deptDoc = await db.collection("departments").doc(departmentId).get();
    if (deptDoc.exists) {
      deptCode = deptDoc.data()?.code || "DEPT";
    }

    const contactsSnap = await db
      .collection("departments")
      .doc(departmentId)
      .collection("maintenanceContacts")
      .where("active", "==", true)
      .get();

    if (contactsSnap.empty) continue;

    const message = formatReportSms({ deptCode, roomNo, category, description, refNo });
    let anySuccess = false;
    let error = "";

    for (const c of contactsSnap.docs) {
      const phone = c.data().phone;
      if (!phone) continue;
      const res = await smsProvider.sendSms(phone, message);
      if (res.success) anySuccess = true;
      else error = res.error || "Retry failed";
    }

    await doc.ref.update({
      smsStatus: anySuccess ? "sent" : "failed",
      smsAttempts: admin.firestore.FieldValue.increment(1),
      lastSmsError: anySuccess ? null : error,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    retriedCount++;
  }

  return { retriedCount };
});

// -----------------------------------------------------------------------------
// 6. FCM Push Notification on Report Status Change
// -----------------------------------------------------------------------------
export const onReportStatusChanged = functions.firestore
  .document("reports/{reportId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after || before.status === after.status) {
      return;
    }

    const reporterUid = after.reporterUid;
    const newStatus = after.status;
    const refNo = after.refNo || "your report";

    // Lookup user FCM tokens
    const userDoc = await db.collection("users").doc(reporterUid).get();
    if (!userDoc.exists) return;

    const fcmTokens: string[] = userDoc.data()?.fcmTokens || [];
    if (fcmTokens.length === 0) return;

    const payload: admin.messaging.MulticastMessage = {
      tokens: fcmTokens,
      notification: {
        title: `Report Status Updated: ${refNo}`,
        body: `Your report status is now "${newStatus.replace("_", " ").toUpperCase()}".`,
      },
      data: {
        reportId: context.params.reportId,
        refNo: refNo,
        status: newStatus,
      },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(payload);
      console.log(`Sent status push to ${response.successCount} devices for report ${refNo}`);
    } catch (err) {
      console.error("Error sending FCM notification:", err);
    }
  });

// -----------------------------------------------------------------------------
// 7. Q&A Comment Created Trigger: Comment Count & Post Author Notification
// -----------------------------------------------------------------------------
export const onCommentCreated = functions.firestore
  .document("qaPosts/{postId}/comments/{commentId}")
  .onCreate(async (snap, context) => {
    const postId = context.params.postId;
    const comment = snap.data();

    // If regular non-anonymous comment, increment comment count
    if (!comment.isAnonymous) {
      await db.collection("qaPosts").doc(postId).update({
        commentCount: admin.firestore.FieldValue.increment(1),
      });
    }

    // Notify post author if author is known and not the commenter
    const postDoc = await db.collection("qaPosts").doc(postId).get();
    if (!postDoc.exists) return;

    const authorUid = postDoc.data()?.authorUid;
    if (!authorUid || authorUid === comment.authorUid) return;

    const authorUserDoc = await db.collection("users").doc(authorUid).get();
    const tokens: string[] = authorUserDoc.data()?.fcmTokens || [];
    if (tokens.length === 0) return;

    try {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "New reply on your Q&A post",
          body: comment.isAnonymous ? "Someone replied anonymously." : `${comment.authorName || "Someone"} replied to your post.`,
        },
        data: { postId },
      });
    } catch (e) {
      console.error("Error sending reply push:", e);
    }
  });

// -----------------------------------------------------------------------------
// 8. Admin Role Assignment (Admin-only Callable)
// -----------------------------------------------------------------------------
export const setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators can assign user roles."
    );
  }

  const { targetUid, role } = data;
  if (!targetUid || !["student", "admin"].includes(role)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid targetUid or role.");
  }

  await admin.auth().setCustomUserClaims(targetUid, { role });
  await db.collection("users").doc(targetUid).update({ role });

  return { success: true, targetUid, role };
});
