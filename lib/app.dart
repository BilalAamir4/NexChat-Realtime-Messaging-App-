import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nexchat_real_time_messaging_app/routes/app_routes.dart';
import 'package:nexchat_real_time_messaging_app/core/theme/app_theme.dart';
import 'package:nexchat_real_time_messaging_app/core/theme/theme_provider.dart';
import 'package:nexchat_real_time_messaging_app/main.dart' show navigatorKey;

class NexChatApp extends ConsumerWidget {
  const NexChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(resolvedThemeModeProvider);

    return MaterialApp(
      title: 'NexChat',
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      // ── Theme ────────────────────────────────────────────────────────────
      themeMode: themeMode,
      theme:     AppTheme.light,
      darkTheme: AppTheme.dark,

      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}