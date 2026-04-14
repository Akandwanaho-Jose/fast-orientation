const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

function getAnnouncementTopics(announcement) {
  const topics = new Set(["announcements"]);

  if (announcement.priority === "urgent") {
    topics.add("urgent_announcements");
  }

  if (announcement.category) {
    const categoryTopic = String(announcement.category).trim().toLowerCase();
    if (categoryTopic) {
      topics.add(categoryTopic);
    }
  }

  return Array.from(topics);
}

function getAnnouncementBody(announcement, fallbackText) {
  const description = typeof announcement.description === "string" ?
    announcement.description.trim() : "";

  if (!description) {
    return fallbackText;
  }

  return description.length > 100 ?
    description.substring(0, 100) + "..." :
    description;
}

function getTimestampMillis(value) {
  if (!value) {
    return null;
  }

  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }

  if (value instanceof Date) {
    return value.getTime();
  }

  return null;
}

/**
 * Trigger when a new announcement is created
 * Sends push notifications to all subscribed users
 */
exports.onAnnouncementCreated = functions.firestore
    .document("announcements/{announcementId}")
    .onCreate(async (snap, context) => {
      try {
        const announcement = snap.data();
        const announcementId = context.params.announcementId;

        console.log("📢 New announcement created:", announcement.title);

        // Prepare notification payload
        const notificationPayload = {
          notification: {
            title: announcement.isPinned ?
              "📌 " + announcement.title : announcement.title,
            body: getAnnouncementBody(
                announcement,
                "A new announcement has been posted.",
            ),
            icon: "https://your-domain.com/app-icon.png",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            announcementId: announcementId,
            type: "announcement",
            priority: announcement.priority || "normal",
            category: announcement.category || "general",
            isPinned: announcement.isPinned ? "true" : "false",
            timestamp: Date.now().toString(),
          },
          android: {
            notification: {
              icon: "ic_notification",
              color: "#1976D2",
              sound: "default",
              channelId: announcement.priority === "urgent" ?
                "urgent_announcements" : "announcements",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                alert: {
                  title: announcement.isPinned ?
                    "📌 " + announcement.title : announcement.title,
                  body: getAnnouncementBody(
                      announcement,
                      "A new announcement has been posted.",
                  ),
                },
              },
            },
          },
        };

        // Determine topics to send to
        const topics = getAnnouncementTopics(announcement);

        // Send notifications to all relevant topics
        const promises = topics.map((topic) => {
          console.log("📤 Sending notification to topic:", topic);
          return admin.messaging().sendToTopic(topic, notificationPayload);
        });

        await Promise.all(promises);

        console.log("✅ Notifications sent successfully to topics:", topics);

        // Log notification stats for analytics
        await admin.firestore().collection("notification_stats").add({
          announcementId: announcementId,
          announcementTitle: announcement.title,
          topicsSent: topics,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          priority: announcement.priority || "normal",
          category: announcement.category || "general",
          totalTopics: topics.length,
        });

        return null;
      } catch (error) {
        console.error("❌ Error sending notification:", error);

        // Log error for debugging
        await admin.firestore().collection("notification_errors").add({
          announcementId: context.params.announcementId,
          error: error.message,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        throw error;
      }
    });

/**
 * Trigger when an announcement is updated
 * Sends update notifications whenever an admin edit updates the content
 */
exports.onAnnouncementUpdated = functions.firestore
    .document("announcements/{announcementId}")
    .onUpdate(async (change, context) => {
      try {
        const beforeData = change.before.data();
        const afterData = change.after.data();
        const announcementId = context.params.announcementId;

        const beforeUpdatedAt = getTimestampMillis(beforeData.updatedAt);
        const afterUpdatedAt = getTimestampMillis(afterData.updatedAt);

        // Only notify for explicit admin edits. This avoids spamming users for
        // background updates like view-count increments.
        if (!afterUpdatedAt || beforeUpdatedAt === afterUpdatedAt) {
          console.log("⚡ Skipping update notification for non-content change");
          return null;
        }

        console.log("📝 Announcement updated, sending notification:",
            afterData.title);

        const topics = getAnnouncementTopics(afterData);

        const notificationPayload = {
          notification: {
            title: (afterData.isPinned ? "📌 Updated: " : "📝 Updated: ") +
              afterData.title,
            body: getAnnouncementBody(
                afterData,
                "An announcement has been updated. Tap to view changes.",
            ),
            icon: "https://your-domain.com/app-icon.png",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            announcementId: announcementId,
            type: "announcement_update",
            priority: afterData.priority || "normal",
            category: afterData.category || "general",
            timestamp: Date.now().toString(),
          },
          android: {
            notification: {
              icon: "ic_notification",
              color: "#1976D2",
              sound: "default",
              channelId: afterData.priority === "urgent" ?
                "urgent_announcements" : "announcements",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                alert: {
                  title: (afterData.isPinned ? "📌 Updated: " : "📝 Updated: ") +
                    afterData.title,
                  body: getAnnouncementBody(
                      afterData,
                      "An announcement has been updated. Tap to view changes.",
                  ),
                },
              },
            },
          },
        };

        const promises = topics.map((topic) => {
          console.log("📤 Sending update notification to topic:", topic);
          return admin.messaging().sendToTopic(topic, notificationPayload);
        });

        await Promise.all(promises);

        console.log("✅ Update notification sent successfully to topics:", topics);

        await admin.firestore().collection("notification_stats").add({
          announcementId: announcementId,
          announcementTitle: afterData.title,
          topicsSent: topics,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          priority: afterData.priority || "normal",
          category: afterData.category || "general",
          totalTopics: topics.length,
          notificationType: "update",
        });

        return null;
      } catch (error) {
        console.error("❌ Error sending update notification:", error);

        await admin.firestore().collection("notification_errors").add({
          announcementId: context.params.announcementId,
          error: error.message,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          source: "onAnnouncementUpdated",
        });

        throw error;
      }
    });

/**
 * Send custom notification (can be called from admin dashboard)
 */
exports.sendCustomNotification = functions.https
    .onCall(async (data, context) => {
      try {
        // Verify authentication
        if (!context.auth) {
          throw new functions.https.HttpsError(
              "unauthenticated",
              "User must be authenticated to send notifications",
          );
        }

        // Get user data to check if admin
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(context.auth.uid)
            .get();

        if (!userDoc.exists || userDoc.data().role !== "admin") {
          throw new functions.https.HttpsError(
              "permission-denied",
              "Only admins can send custom notifications",
          );
        }

        const {title, body, topic, tokens, customData} = data;

        if (!title || !body) {
          throw new functions.https.HttpsError(
              "invalid-argument",
              "Title and body are required",
          );
        }

        const notificationPayload = {
          notification: {
            title: title,
            body: body,
            icon: "https://your-domain.com/app-icon.png",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            type: "custom",
            timestamp: Date.now().toString(),
            ...customData,
          },
          android: {
            notification: {
              icon: "ic_notification",
              color: "#1976D2",
              sound: "default",
              channelId: "general_notifications",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        let result;

        if (topic) {
          // Send to topic
          result = await admin.messaging().sendToTopic(topic,
              notificationPayload);
          console.log("✅ Custom notification sent to topic:", topic);
        } else if (tokens && tokens.length > 0) {
          // Send to specific tokens
          result = await admin.messaging().sendMulticast({
            tokens: tokens,
            ...notificationPayload,
          });
          console.log("✅ Custom notification sent to tokens:", tokens.length);
        } else {
          throw new functions.https.HttpsError(
              "invalid-argument",
              "Either topic or tokens must be provided",
          );
        }

        return {success: true, result: result};
      } catch (error) {
        console.error("❌ Error sending custom notification:", error);
        throw new functions.https.HttpsError("internal", error.message);
      }
    });

/**
 * Clean up old notifications and stats
 * Runs daily to keep database clean
 */
exports.cleanupOldData = functions.pubsub
    .schedule("0 2 * * *") // Run at 2 AM daily
    .timeZone("Africa/Kampala") // Set to your timezone
    .onRun(async (context) => {
      try {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        // Clean up old notification stats
        const statsQuery = admin.firestore()
            .collection("notification_stats")
            .where("sentAt", "<", thirtyDaysAgo);

        const statsSnapshot = await statsQuery.get();

        if (!statsSnapshot.empty) {
          const batch = admin.firestore().batch();
          statsSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
          await batch.commit();
          console.log("🧹 Cleaned up " + statsSnapshot.docs.length +
              " old notification stats");
        }

        // Clean up old error logs
        const errorsQuery = admin.firestore()
            .collection("notification_errors")
            .where("timestamp", "<", thirtyDaysAgo);

        const errorsSnapshot = await errorsQuery.get();

        if (!errorsSnapshot.empty) {
          const batch = admin.firestore().batch();
          errorsSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
          await batch.commit();
          console.log("🧹 Cleaned up " + errorsSnapshot.docs.length +
              " old error logs");
        }

        return null;
      } catch (error) {
        console.error("❌ Error during cleanup:", error);
        throw error;
      }
    });

/**
 * Get notification statistics for admin dashboard
 */
exports.getNotificationStats = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated",
      );
    }

    const userDoc = await admin.firestore()
        .collection("users")
        .doc(context.auth.uid)
        .get();

    if (!userDoc.exists || userDoc.data().role !== "admin") {
      throw new functions.https.HttpsError(
          "permission-denied",
          "Only admins can view notification statistics",
      );
    }

    const {days = 30} = data;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const query = admin.firestore()
        .collection("notification_stats")
        .where("sentAt", ">=", startDate)
        .orderBy("sentAt", "desc");

    const snapshot = await query.get();

    const stats = {
      totalNotifications: snapshot.docs.length,
      byCategory: {},
      byPriority: {},
      byDate: {},
      recent: [],
    };

    snapshot.docs.forEach((doc) => {
      const docData = doc.data();

      // Count by category
      const category = docData.category || "general";
      stats.byCategory[category] = (stats.byCategory[category] || 0) + 1;

      // Count by priority
      const priority = docData.priority || "normal";
      stats.byPriority[priority] = (stats.byPriority[priority] || 0) + 1;

      // Count by date
      const date = docData.sentAt.toDate().toISOString().split("T")[0];
      stats.byDate[date] = (stats.byDate[date] || 0) + 1;

      // Add to recent (limit to 10)
      if (stats.recent.length < 10) {
        stats.recent.push({
          title: docData.announcementTitle,
          category: docData.category,
          priority: docData.priority,
          topicsSent: docData.topicsSent,
          sentAt: docData.sentAt.toDate().toISOString(),
        });
      }
    });

    return stats;
  } catch (error) {
    console.error("❌ Error getting notification stats:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
