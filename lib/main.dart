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
  debugPrint('Step 1: Firebase init start');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Step 2: Firebase init done');

  if (!kIsWeb) {
    debugPrint('Step 3: NotificationService init start');
    await NotificationService.instance.initialize(navigatorKey);
    debugPrint('Step 4: NotificationService init done');
  }

  debugPrint('Step 5: runApp');
  runApp(const ProviderScope(child: NexChatApp()));
}