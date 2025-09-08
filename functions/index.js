const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/// 🔧 Helper: cleanup invalid tokens
async function cleanupInvalidTokens(tokens, responses) {
  const invalidTokens = [];
  responses.forEach((res, idx) => {
    if (!res.success) {
      const errorCode = res.error?.code;
      if (
        errorCode === "messaging/invalid-argument" ||
        errorCode === "messaging/registration-token-not-registered"
      ) {
        invalidTokens.push(tokens[idx]);
      }
    }
  });

  if (invalidTokens.length > 0) {
    logger.warn(`🗑️ Cleaning up invalid tokens`, { invalidTokens });
    for (const token of invalidTokens) {
      const snap = await db.collection("users").where("fcmToken", "==", token).get();
      snap.forEach((doc) => {
        doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
        logger.info(`🗑️ Removed invalid FCM token from user ${doc.id}`);
      });
    }
  }
}

/// 🔔 When a new job is created → mark the driver for notification
exports.onJobCreated = onDocumentCreated(
  { document: "jobs/{jobId}", region: "us-central1" },
  async (event) => {
    const job = event.data?.data();
    if (!job || !job.driverId) return;

    const driverRef = db.collection("users").doc(job.driverId);
    await driverRef.update({ pendingNotification: true });

    logger.info(`📌 Marked driver ${job.driverId} for pending notification`);
  }
);

/// 📩 When driver doc flagged → send summary notification (only once)
exports.sendDriverSummary = onDocumentUpdated(
  { document: "users/{driverId}", region: "us-central1" },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const driverId = event.params.driverId;

    if (!after?.pendingNotification || before?.pendingNotification === after?.pendingNotification) {
      return;
    }

    // Reset flag
    await event.data.after.ref.update({
      pendingNotification: admin.firestore.FieldValue.delete(),
    });

    // Count active jobs
    const jobsSnap = await db
      .collection("jobs")
      .where("driverId", "==", driverId)
      .where("status", "==", "active")
      .get();

    const jobCount = jobsSnap.size;
    if (jobCount === 0) return;

    // Get driver FCM token
    const driverDoc = await db.collection("users").doc(driverId).get();
    const fcmToken = driverDoc.data()?.fcmToken;
    if (!fcmToken) {
      logger.warn(`⚠️ No FCM token for driver ${driverId}`);
      return;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: "🚚 New Jobs Assigned",
        body:
          jobCount === 1
            ? "You have 1 active job waiting."
            : `You have ${jobCount} active jobs waiting.`,
      },
      data: { driverId, totalActiveJobs: jobCount.toString() },
    };

    try {
      const response = await admin.messaging().send(message);
      logger.info(`✅ Sent summary notification to driver ${driverId} (${jobCount} jobs)`);

      // Cleanup invalid tokens
      await cleanupInvalidTokens([fcmToken], [response]);
    } catch (err) {
      logger.error(`❌ Error sending summary notification to driver ${driverId}`, err);
    }
  }
);

/// ✅ Notify admin when a job is marked as finished
exports.notifyAdminOnJobFinished = onDocumentUpdated(
  { document: "jobs/{jobId}", region: "us-central1" },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const jobId = event.params.jobId;

    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== "finished") return;

    logger.info(`✅ Job #${jobId} marked as finished by driver ${after.driverId}`);

    // Try to get driver email
    let driverEmail = after.driverId;
    try {
      const driverDoc = await db.collection("drivers").doc(after.driverId).get();
      if (driverDoc.exists && driverDoc.data()?.email) {
        driverEmail = driverDoc.data().email;
      }
    } catch (err) {
      logger.warn(`⚠️ Could not fetch driver details for ${after.driverId}`, err);
    }

    // Collect admin FCM tokens
    const adminSnap = await db.collection("users").where("role", "==", "admin").get();
    const tokens = [];
    adminSnap.forEach((doc) => {
      const token = doc.data()?.fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      logger.warn("⚠️ No valid FCM tokens for admins");
      return;
    }

    const message = {
      tokens,
      notification: {
        title: "✅ Job Completed",
        body: `Job #${jobId} has been finished by driver (${driverEmail}).`,
      },
      data: { jobId, driverId: after.driverId, status: "finished" },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      logger.info(`📤 Sent finish notification to admins`, {
        successCount: response.successCount,
        failureCount: response.failureCount,
      });

      // Cleanup invalid tokens
      await cleanupInvalidTokens(tokens, response.responses);
    } catch (err) {
      logger.error("❌ Error sending finish notification", err);
    }
  }
);