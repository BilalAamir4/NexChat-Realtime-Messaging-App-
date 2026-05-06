// functions/index.js
// Deploy with: firebase deploy --only functions

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Triggered when a new message doc is created inside any chat.
 * Path: chats/{chatId}/messages/{messageId}
 *
 * What it does:
 *  1. Reads the parent chat to get all participant UIDs
 *  2. Skips the sender
 *  3. Fetches every recipient's FCM tokens from users/{uid}/fcmTokens
 *  4. Sends a multicast FCM push notification
 *  5. Cleans up any stale/invalid tokens automatically
 */
exports.onNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const { chatId } = event.params;

    // Ignore system messages
    if (message.type === "system") return null;

    const senderId = message.senderId;
    if (!senderId) return null;

    // ── 1. Load the parent chat ──────────────────────────────────────────
    const chatSnap = await db.collection("chats").doc(chatId).get();
    if (!chatSnap.exists) return null;

    const chat = chatSnap.data();
    const participants = chat.participants || [];
    const isGroup = chat.type === "group";

    // ── 2. Determine recipients (everyone except sender) ─────────────────
    const recipientIds = participants.filter((uid) => uid !== senderId);
    if (recipientIds.length === 0) return null;

    // ── 3. Fetch sender display name ─────────────────────────────────────
    const senderSnap = await db.collection("users").doc(senderId).get();
    const senderName = senderSnap.exists
      ? senderSnap.data().displayName || "Someone"
      : "Someone";

    // ── 4. Build notification title & body ────────────────────────────────
    const chatName = isGroup ? chat.groupName || "Group Chat" : senderName;

    const notificationTitle = isGroup
      ? `${senderName} in ${chatName}`
      : senderName;

    const notificationBody = buildBody(message);

    // ── 5. Collect valid FCM tokens for all recipients ────────────────────
    const tokenDocs = await Promise.all(
      recipientIds.map((uid) =>
        db.collection("users").doc(uid).collection("fcmTokens").get()
      )
    );

    // Map token → uid so we can clean up stale tokens per user
    const tokenToUid = {};
    const allTokens = [];

    tokenDocs.forEach((snap, i) => {
      const uid = recipientIds[i];
      snap.docs.forEach((doc) => {
        const token = doc.data().token;
        if (token) {
          allTokens.push(token);
          tokenToUid[token] = uid;
        }
      });
    });

    if (allTokens.length === 0) {
      console.log("No FCM tokens found for recipients.");
      return null;
    }

    // ── 6. Send multicast notification ────────────────────────────────────
    const fcmMessage = {
      tokens: allTokens,
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      data: {
        chatId,
        senderId,
        isGroup: isGroup ? "true" : "false",
        type: message.type || "text",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "nexchat_messages",
          priority: "max",
          defaultSound: true,
          defaultVibrateTimings: true,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notificationTitle,
              body: notificationBody,
            },
            badge: 1,
            sound: "default",
            contentAvailable: true,
          },
        },
      },
    };

    let response;
    try {
      response = await messaging.sendEachForMulticast(fcmMessage);
      console.log(
        `✅ Sent ${response.successCount}/${allTokens.length} notifications for chat ${chatId}`
      );
    } catch (err) {
      console.error("FCM send error:", err);
      return null;
    }

    // ── 7. Remove stale tokens that FCM rejected ──────────────────────────
    const staleTokenDeletions = [];

    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const code = resp.error?.code;
        const isStale =
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered";

        if (isStale) {
          const staleToken = allTokens[idx];
          const uid = tokenToUid[staleToken];
          if (uid) {
            staleTokenDeletions.push(
              db
                .collection("users")
                .doc(uid)
                .collection("fcmTokens")
                .doc(staleToken)
                .delete()
            );
            console.log(`🗑 Removing stale token for user ${uid}`);
          }
        }
      }
    });

    if (staleTokenDeletions.length > 0) {
      await Promise.all(staleTokenDeletions);
    }

    return null;
  }
);

// ── Helper: build readable notification body ──────────────────────────────────

function buildBody(message) {
  switch (message.type) {
    case "image":
      return "📷 Photo";
    case "voice":
      return "🎤 Voice message";
    default:
      // Truncate long text
      const text = message.content || "";
      return text.length > 80 ? text.substring(0, 77) + "…" : text;
  }
}
