import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexchat_real_time_messaging_app/app.dart';
import 'package:nexchat_real_time_messaging_app/core/services/notification_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ── Initialize FCM ──────────────────────────────────────────────────────
  await NotificationService.instance.initialize(navigatorKey);

  runApp(
    const ProviderScope(
      child: NexChatApp(),
    ),
  );
}