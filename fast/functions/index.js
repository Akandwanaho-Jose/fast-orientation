/* eslint-disable require-jsdoc */
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

const firestore = admin.firestore();
const fieldValue = admin.firestore.FieldValue;

const DEFAULT_TOPIC = "announcements";
const TOPIC_BY_TYPE = {
  announcement: "announcements",
  event: "events",
  deadline: "deadlines",
  opportunity: "opportunities",
};

function readString(value, fallback = "") {
  return typeof value === "string" && value.trim() ?
    value.trim() :
    fallback;
}

function normalizeTopic(value, fallback = DEFAULT_TOPIC) {
  const normalized = readString(value, fallback)
      .toLowerCase()
      .replace(/[^a-z0-9_-]+/g, "_")
      .replace(/^_+|_+$/g, "");

  return normalized || fallback;
}

function truncate(value, fallback, maxLength = 140) {
  const text = readString(value, fallback);
  if (text.length <= maxLength) {
    return text;
  }
  return text.substring(0, maxLength - 3).trimEnd() + "...";
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

function getPushConfig(announcement) {
  const config = announcement.pushNotification;
  return config && typeof config === "object" ? config : {};
}

function getNotificationTopic(announcement) {
  const config = getPushConfig(announcement);
  const configuredTopic = readString(config.topic);
  if (configuredTopic && configuredTopic !== "auto") {
    return normalizeTopic(configuredTopic);
  }

  const priority = readString(announcement.priority, "normal").toLowerCase();
  if (priority === "urgent") {
    return "urgent_announcements";
  }

  const type = readString(announcement.type, "announcement").toLowerCase();
  return TOPIC_BY_TYPE[type] || DEFAULT_TOPIC;
}

function getNotificationTitle(announcement, mode) {
  const config = getPushConfig(announcement);
  const configuredTitle = readString(config.title);
  if (configuredTitle) {
    return configuredTitle;
  }

  const title = readString(announcement.title, "FAST Update");
  if (mode === "updated") {
    return "Updated: " + title;
  }
  return title;
}

function getNotificationBody(announcement, fallbackText) {
  const config = getPushConfig(announcement);
  const configuredBody = readString(config.body);
  if (configuredBody) {
    return truncate(configuredBody, fallbackText);
  }

  return truncate(announcement.description, fallbackText);
}

function getRequestedAt(announcement) {
  return getTimestampMillis(getPushConfig(announcement).requestedAt);
}

function hasNewPushRequest(beforeData, afterData) {
  if (!beforeData) {
    return true;
  }

  const beforeRequestedAt = getRequestedAt(beforeData);
  const afterRequestedAt = getRequestedAt(afterData);
  return Boolean(afterRequestedAt && beforeRequestedAt !== afterRequestedAt);
}

function getPushSkipReason(beforeData, afterData) {
  const config = getPushConfig(afterData);
  const status = readString(afterData.status, "draft").toLowerCase();
  const requestStatus = readString(config.status, "pending").toLowerCase();

  if (status !== "published") {
    return "announcement is not published";
  }
  if (config.enabled !== true) {
    return "pushNotification.enabled is not true";
  }
  if (requestStatus === "sent") {
    return "pushNotification.status is already sent";
  }
  if (!getRequestedAt(afterData)) {
    return "pushNotification.requestedAt is missing";
  }
  if (!hasNewPushRequest(beforeData, afterData)) {
    return "pushNotification.requestedAt has not changed";
  }
  return "";
}

function buildAnnouncementMessage(announcementId, announcement, mode) {
  const priority = readString(announcement.priority, "normal").toLowerCase();
  const type = mode === "updated" ? "announcement_update" : "announcement";
  const topic = getNotificationTopic(announcement);
  const title = getNotificationTitle(announcement, mode);
  const body = getNotificationBody(
      announcement,
      mode === "updated" ?
        "A FAST update has changed. Tap to view details." :
        "A new FAST update has been published.",
  );

  return {
    topic,
    title,
    body,
    message: {
      topic,
      notification: {
        title,
        body,
      },
      data: {
        announcementId,
        type,
        priority,
        category: readString(announcement.category, "general"),
        updateType: readString(announcement.type, "announcement"),
        topic,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        timestamp: Date.now().toString(),
      },
      android: {
        priority: priority === "urgent" ? "high" : "normal",
        notification: {
          icon: "ic_notification",
          color: "#003087",
          sound: "default",
          channelId: priority === "urgent" ?
            "urgent_announcements" :
            "announcements",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
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
    },
  };
}

async function recordNotificationFeed(announcementId, announcement, payload) {
  await firestore.collection("notification_feed").add({
    announcementId,
    title: payload.title,
    body: payload.body,
    topic: payload.topic,
    priority: readString(announcement.priority, "normal").toLowerCase(),
    category: readString(announcement.category, "general"),
    updateType: readString(announcement.type, "announcement"),
    sentAt: fieldValue.serverTimestamp(),
    createdFrom: "announcement",
  });
}

async function recordNotificationStats(announcementId, announcement, payload) {
  await firestore.collection("notification_stats").add({
    announcementId,
    announcementTitle: readString(announcement.title, "FAST Update"),
    topic: payload.topic,
    sentAt: fieldValue.serverTimestamp(),
    priority: readString(announcement.priority, "normal").toLowerCase(),
    category: readString(announcement.category, "general"),
    updateType: readString(announcement.type, "announcement"),
  });
}

async function markPushStatus(ref, status, fields = {}) {
  const update = {
    "pushNotification.enabled": false,
    "pushNotification.status": status,
    "pushNotification.updatedAt": fieldValue.serverTimestamp(),
    ...fields,
  };

  await ref.update(update);
}

async function sendAnnouncementPush(ref, announcementId, data, mode) {
  const payload = buildAnnouncementMessage(announcementId, data, mode);
  const response = await admin.messaging().send(payload.message);

  await recordNotificationFeed(announcementId, data, payload);
  await recordNotificationStats(announcementId, data, payload);

  await markPushStatus(ref, "sent", {
    "pushNotification.sentAt": fieldValue.serverTimestamp(),
    "pushNotification.messageId": response,
    "pushNotification.lastTopic": payload.topic,
    "pushNotification.error": fieldValue.delete(),
  });

  return response;
}

async function processAnnouncementPush(ref, announcementId, beforeData, data,
    mode) {
  const skipReason = getPushSkipReason(beforeData, data);
  if (skipReason) {
    console.log("Skipping notification for announcement:", announcementId,
        skipReason);
    return null;
  }

  try {
    const response = await sendAnnouncementPush(
        ref, announcementId, data, mode);
    console.log("Notification sent for announcement:", announcementId,
        response);
    return response;
  } catch (error) {
    console.error("Error sending announcement notification:", error);

    await markPushStatus(ref, "failed", {
      "pushNotification.error": error.message,
      "pushNotification.failedAt": fieldValue.serverTimestamp(),
    });

    await firestore.collection("notification_errors").add({
      announcementId,
      error: error.message,
      timestamp: fieldValue.serverTimestamp(),
      source: "announcement_push",
    });

    throw error;
  }
}

exports.onAnnouncementCreated = functions.firestore
    .document("announcements/{announcementId}")
    .onCreate(async (snap, context) => {
      return processAnnouncementPush(
          snap.ref,
          context.params.announcementId,
          null,
          snap.data(),
          "created",
      );
    });

exports.onAnnouncementUpdated = functions.firestore
    .document("announcements/{announcementId}")
    .onUpdate(async (change, context) => {
      return processAnnouncementPush(
          change.after.ref,
          context.params.announcementId,
          change.before.data(),
          change.after.data(),
          "updated",
      );
    });

exports.sendCustomNotification = functions.https
    .onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated to send notifications",
        );
      }

      const userDoc = await firestore
          .collection("users")
          .doc(context.auth.uid)
          .get();

      if (!userDoc.exists || userDoc.data().role !== "admin") {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Only admins can send custom notifications",
        );
      }

      const title = readString(data.title);
      const body = readString(data.body);
      const topic = readString(data.topic);
      const tokens = Array.isArray(data.tokens) ? data.tokens : [];
      const customData =
        data.customData && typeof data.customData === "object" ?
          data.customData :
          {};

      if (!title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Title and body are required",
        );
      }

      const messageBase = {
        notification: {title, body},
        data: {
          type: "custom",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          timestamp: Date.now().toString(),
          ...Object.fromEntries(
              Object.entries(customData)
                  .map(([key, value]) => [key, String(value)]),
          ),
        },
        android: {
          notification: {
            icon: "ic_notification",
            color: "#003087",
            sound: "default",
            channelId: "general_notifications",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
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

      if (topic) {
        const normalizedTopic = normalizeTopic(topic);
        const response = await admin.messaging().send({
          ...messageBase,
          topic: normalizedTopic,
        });
        return {success: true, topic: normalizedTopic, result: response};
      }

      if (tokens.length > 0) {
        const response = await admin.messaging().sendEachForMulticast({
          ...messageBase,
          tokens,
        });
        return {success: true, tokens: tokens.length, result: response};
      }

      throw new functions.https.HttpsError(
          "invalid-argument",
          "Either topic or tokens must be provided",
      );
    });

exports.cleanupOldData = functions.pubsub
    .schedule("0 2 * * *")
    .timeZone("Africa/Kampala")
    .onRun(async () => {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      await deleteOldDocuments("notification_stats", "sentAt", thirtyDaysAgo);
      await deleteOldDocuments("notification_errors", "timestamp",
          thirtyDaysAgo);
      await deleteOldDocuments("notification_feed", "sentAt", thirtyDaysAgo);

      return null;
    });

async function deleteOldDocuments(collectionName, field, cutoffDate) {
  const snapshot = await firestore
      .collection(collectionName)
      .where(field, "<", cutoffDate)
      .get();

  if (snapshot.empty) {
    return;
  }

  const batch = firestore.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  console.log("Cleaned old documents:", collectionName, snapshot.docs.length);
}

exports.getNotificationStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated",
    );
  }

  const userDoc = await firestore
      .collection("users")
      .doc(context.auth.uid)
      .get();

  if (!userDoc.exists || userDoc.data().role !== "admin") {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can view notification statistics",
    );
  }

  const days = Number(data.days || 30);
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  const snapshot = await firestore
      .collection("notification_stats")
      .where("sentAt", ">=", startDate)
      .orderBy("sentAt", "desc")
      .get();

  const stats = {
    totalNotifications: snapshot.docs.length,
    byCategory: {},
    byPriority: {},
    byTopic: {},
    byDate: {},
    recent: [],
  };

  snapshot.docs.forEach((doc) => {
    const docData = doc.data();
    const category = docData.category || "general";
    const priority = docData.priority || "normal";
    const topic = docData.topic || DEFAULT_TOPIC;
    const date = docData.sentAt.toDate().toISOString().split("T")[0];

    stats.byCategory[category] = (stats.byCategory[category] || 0) + 1;
    stats.byPriority[priority] = (stats.byPriority[priority] || 0) + 1;
    stats.byTopic[topic] = (stats.byTopic[topic] || 0) + 1;
    stats.byDate[date] = (stats.byDate[date] || 0) + 1;

    if (stats.recent.length < 10) {
      stats.recent.push({
        title: docData.announcementTitle,
        category,
        priority,
        topic,
        sentAt: docData.sentAt.toDate().toISOString(),
      });
    }
  });

  return stats;
});
