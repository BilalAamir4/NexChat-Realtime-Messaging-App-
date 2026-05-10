// functions/index.js
// Deploy with: firebase deploy --only functions

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onValueWritten } = require("firebase-functions/v2/database");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
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
 *  6. Writes a notification document to users/{uid}/notifications
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

    // ── 3. Fetch sender display name & avatar ────────────────────────────
    const senderSnap = await db.collection("users").doc(senderId).get();
    const senderData = senderSnap.exists ? senderSnap.data() : {};
    const senderName = senderData.displayName || "Someone";
    const senderAvatar = senderData.photoURL || "";

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

    // ── 6. Send multicast notification (if tokens exist) ─────────────────
    if (allTokens.length > 0) {
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
        // Don't return — still write Firestore notifications below
      }

      // ── 7. Remove stale tokens that FCM rejected ────────────────────────
      if (response) {
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
      }
    } else {
      console.log("No FCM tokens found for recipients — skipping FCM send.");
    }

    // ── 8. Write notification docs to Firestore for each recipient ────────
    await Promise.all(
      recipientIds.map((uid) =>
        saveNotificationToFirestore(uid, {
          chatId,
          senderName,
          senderAvatar,
          body: notificationBody,
          isGroup,
          groupName: isGroup ? (chat.groupName || null) : null,
        })
      )
    );

    return null;
  }
);

/**
 * Triggered when presence data changes in Realtime Database.
 * Path: /presence/{uid}
 *
 * Mirrors isOnline + lastSeen to Firestore so presenceProvider
 * picks it up automatically. Handles crash/kill cases where
 * onDisconnect fires but the app can't write to Firestore itself.
 */
exports.syncPresenceToFirestore = onValueWritten(
  {
    ref: "/presence/{uid}",
    region: "asia-southeast1",
    database: "nexchat-24abe-default-rtdb",
  },
  async (event) => {
    const uid = event.params.uid;
    const presence = event.data.after.val();

    if (presence === null) return null;

    console.log(`🔄 Syncing presence for user ${uid}:`, presence);

    return db.collection("users").doc(uid).set(presence, { merge: true });
  }
);

/**
 * Runs daily — deletes notification docs older than 7 days.
 * Keeps Firestore tidy without any manual effort.
 */
exports.cleanOldNotifications = onSchedule("every 24 hours", async () => {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 7);

  const usersSnap = await db.collection("users").get();

  await Promise.all(
    usersSnap.docs.map(async (userDoc) => {
      const oldSnap = await userDoc.ref
        .collection("notifications")
        .where("createdAt", "<", cutoff)
        .get();

      if (oldSnap.empty) return;

      const batch = db.batch();
      oldSnap.docs.forEach((d) => batch.delete(d.reference));
      await batch.commit();
      console.log(
        `🧹 Deleted ${oldSnap.size} old notifications for user ${userDoc.id}`
      );
    })
  );
});

// ── Helper: write one notification doc for a recipient ────────────────────────

async function saveNotificationToFirestore(recipientUid, opts) {
  await db
    .collection("users")
    .doc(recipientUid)
    .collection("notifications")
    .add({
      chatId:       opts.chatId,
      senderName:   opts.senderName   ?? "Someone",
      senderAvatar: opts.senderAvatar ?? "",
      body:         opts.body         ?? "New message",
      isGroup:      opts.isGroup      ?? false,
      groupName:    opts.groupName    ?? null,
      read:         false,
      createdAt:    FieldValue.serverTimestamp(),
    });
}

// ── Helper: build readable notification body ──────────────────────────────────

function buildBody(message) {
  switch (message.type) {
    case "image":
      return "📷 Photo";
    case "voice":
      return "🎤 Voice message";
    default: {
      const text = message.content || "";
      return text.length > 80 ? text.substring(0, 77) + "…" : text;
    }
  }
}