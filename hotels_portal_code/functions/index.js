const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { setGlobalOptions } = require("firebase-functions/v2");

// Initialize the Firebase Admin SDK to access Firestore and FCM
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Set global options for function instances
setGlobalOptions({ maxInstances: 10 });

/**
 * A generic function to send a push notification to a user (guest or admin).
 * @param {string} userId The ID of the user to whom the notification will be sent.
 * @param {string} userType The collection name ('guests' or 'admins').
 * @param {object} notificationData The data from the created notification document.
 * @param {string} notificationId The ID of the notification document.
 */
async function sendPushNotification(
  userId,
  userType,
  notificationData,
  notificationId
) {
  console.log(`Attempting to send notification to ${userType} ID: ${userId}`);

  try {
    // 1. Fetch the user's document to get their FCM token
    const userDoc = await db.collection(userType).doc(userId).get();

    if (!userDoc.exists) {
      console.log(`User document not found for ${userType} ID: ${userId}`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    const settings = userData.settings;

    if (!fcmToken) {
      console.log(`FCM token not found for ${userType} ID: ${userId}`);
      return;
    }

    if (!settings || !settings.pushNotifications) {
      console.log(`User ${userId} does not allow push notifications.`);
      return;
    }

    // 2. Construct the FCM payload
    const payload = {
      notification: {
        title: notificationData.title || "New Notification",
        body: notificationData.message || "You have a new update.",
      },
      data: {
        type: notificationData.type || "general",
        bookingId: notificationData.bookingId || "",
        notificationId: notificationId,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // Essential for Flutter to handle background taps
      },
      token: fcmToken,
    };

    console.log(
      `Sending payload to token: ${fcmToken}`,
      JSON.stringify(payload)
    );

    // 3. Send the push notification
    const response = await messaging.send(payload);

    console.log("Successfully sent message:", response);
  } catch (error) {
    console.error(
      `Error sending push notification to ${userType} ID ${userId}:`,
      error
    );
  }
}

/**
 * Fetches all ministry admins and sends them a push notification based on an activity.
 * @param {object} activityData The data from the created activity document.
 * @param {string} activityId The ID of the activity document.
 */
async function sendAdminsPushNotification(activityData, activityId) {
  console.log(
    `Attempting to send activity notification to all ministry admins.`
  );

  try {
    // 1. Get all ministry admins
    const adminsSnapshot = await db
      .collection("admins")
      .where("role", "==", "ministry admin")
      .get();

    if (adminsSnapshot.empty) {
      console.log("No ministry admins found to notify.");
      return;
    }

    // 2. Collect FCM tokens from admins who have push notifications enabled
    const tokens = [];
    adminsSnapshot.forEach((doc) => {
      const adminData = doc.data();
      const fcmToken = adminData.fcmToken;
      const settings = adminData.settings;

      if (fcmToken && settings && settings.pushNotifications === true) {
        tokens.push(fcmToken);
      } else {
        console.log(
          `Skipping admin ${doc.id}: No token or notifications disabled.`
        );
      }
    });

    if (tokens.length === 0) {
      console.log(
        "No ministry admins with valid FCM tokens and enabled notifications found."
      );
      return;
    }

    // 3. Construct the FCM payload from the activity data
    const payload = {
      notification: {
        title: activityData.type || "New System Activity",
        body:
          activityData.description ||
          "A new activity has occurred in the system.",
      },
      data: {
        type: "activity", // Custom type for client-side handling
        activityId: activityId,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // Essential for Flutter
      },
    };

    console.log(
      `Sending multicast notification to ${tokens.length} ministry admins.`
    );

    // 4. Send the push notification to all collected tokens at once
    const response = await messaging.sendEachForMulticast({
      tokens: tokens,
      notification: payload.notification,
      data: payload.data,
    });

    console.log(`Successfully sent ${response.successCount} messages.`);
    if (response.failureCount > 0) {
      console.error(`Failed to send ${response.failureCount} messages.`);
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(
            `Failure for token ${tokens[idx]}: ${resp.error.message}`
          );
        }
      });
    }
  } catch (error) {
    console.error(`Error sending push notification to ministry admins:`, error);
  }
}

// --- Cloud Function Triggers ---

/**
 * Triggered when a new notification is created for a GUEST.
 * Sends a push notification to that guest.
 */
exports.sendGuestPushNotification = onDocumentCreated(
  "guests/{guestId}/notifications/{notificationId}",
  (event) => {
    const { guestId, notificationId } = event.params;
    const notificationData = event.data.data();

    if (!notificationData) {
      console.log("No data found in the guest notification document.");
      return;
    }

    return sendPushNotification(
      guestId,
      "guests",
      notificationData,
      notificationId
    );
  }
);

/**
 * Triggered when a new notification is created for an ADMIN.
 * Sends a push notification to that admin.
 */
exports.sendAdminPushNotification = onDocumentCreated(
  "admins/{adminId}/notifications/{notificationId}",
  (event) => {
    const { adminId, notificationId } = event.params;
    const notificationData = event.data.data();

    if (!notificationData) {
      console.log("No data found in the admin notification document.");
      return;
    }

    return sendPushNotification(
      adminId,
      "admins",
      notificationData,
      notificationId
    );
  }
);

/**
 * Triggered when a new activity is created.
 * Sends a push notification to all ministry admins.
 */
exports.sendMinistryAdminPushNotification = onDocumentCreated(
  "activities/{activityId}",
  (event) => {
    const { activityId } = event.params;
    const activityData = event.data.data();

    if (!activityData) {
      console.log("No data found in the activity document.");
      return;
    }

    return sendAdminsPushNotification(activityData, activityId);
  }
);
