import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexchat_real_time_messaging_app/app.dart';
import 'package:nexchat_real_time_messaging_app/core/services/notification_service.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    await NotificationService.instance.initialize(navigatorKey);
  }

  runApp(
    const ProviderScope(
      child: NexChatApp(),
    ),
  );
}