import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Top-level handler required by FCM — must be a bare function, not a method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this is called.
  // flutter_local_notifications can show a heads-up here if desired,
  // but FCM shows the notification automatically when the app is killed/backgrounded.
  debugPrint('📩 Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Android high-importance channel — required for heads-up notifications.
  static const _androidChannel = AndroidNotificationChannel(
    'nexchat_messages',
    'NexChat Messages',
    description: 'New message notifications from NexChat',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ── Initialise (call once from main.dart) ────────────────────────────────

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    // 1. Register the background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

    // 3. Set up flutter_local_notifications (needed for foreground display)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload, navigatorKey);
      },
    );

    // 4. Create the Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 5. FCM: show foreground notifications as heads-up banners
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 6. Listen for foreground messages → show local notification
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // 7. App opened from a notification while backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(
        message.data['chatId'] as String?,
        navigatorKey,
      );
    });

    // 8. App was fully killed — check if launched via notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Delay slightly so Navigator is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(
          initial.data['chatId'] as String?,
          navigatorKey,
        );
      });
    }

    // 9. Save the FCM token when auth state changes (login / logout)
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        saveTokenToFirestore();
      }
    });

    // 10. Listen for token refreshes
    _fcm.onTokenRefresh.listen((_) => saveTokenToFirestore());
  }

  // ── Save FCM Token ────────────────────────────────────────────────────────

  Future<void> saveTokenToFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final token = await _fcm.getToken();
    if (token == null) return;

    // Store in users/{uid}/fcmTokens/{token}
    // Using the token as the doc ID makes it easy to delete on logout.
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': _platform(),
    });

    debugPrint('✅ FCM token saved for $uid');
  }

  /// Call this on sign-out so the device stops receiving notifications.
  Future<void> deleteTokenFromFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final token = await _fcm.getToken();
    if (token == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .delete();

    debugPrint('🗑 FCM token removed for $uid');
  }

  // ── Show Local Notification (foreground) ─────────────────────────────────

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final chatId = message.data['chatId'] as String?;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(notification.body ?? ''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: chatId,
    );
  }

  // ── Navigate to Chat on Tap ───────────────────────────────────────────────

  void _handleNotificationTap(
      String? chatId,
      GlobalKey<NavigatorState> navigatorKey,
      ) {
    if (chatId == null || chatId.isEmpty) return;

    // Fetch chat info and push the ChatRoom route
    _firestore.collection('chats').doc(chatId).get().then((snap) {
      if (!snap.exists) return;
      final data = snap.data()!;
      final uid = _auth.currentUser?.uid ?? '';
      final participants = List<String>.from(data['participants'] ?? []);
      final isGroup = data['type'] == 'group';
      final otherUid =
      participants.firstWhere((id) => id != uid, orElse: () => '');

      navigatorKey.currentState?.pushNamed(
        '/chatRoom',
        arguments: {
          'chatId': chatId,
          'otherUserId': otherUid,
          'otherUserName': isGroup ? (data['groupName'] ?? 'Group') : '',
          'otherUserAvatar': '',
          'isGroup': isGroup,
          'groupName': data['groupName'] as String?,
        },
      );
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _platform() {
    // Works without dart:io — just checks if Android channel creation works.
    try {
      return 'android';
    } catch (_) {
      return 'ios';
    }
  }
}