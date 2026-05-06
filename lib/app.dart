import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexchat_real_time_messaging_app/routes/app_routes.dart';
import 'package:nexchat_real_time_messaging_app/features/chat/screens/goup_info_screen.dart';

// Auth screens
import 'package:nexchat_real_time_messaging_app/features/auth/screens/splash_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/screens/login_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/screens/otp_screen.dart';

// Main screens
import 'package:nexchat_real_time_messaging_app/features/chat/screens/chat_list_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/profile/screens/profile_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/user_discovery/screens/user_discovery.dart';
import 'package:nexchat_real_time_messaging_app/features/chat/models/chat_model.dart';

// Theme
import 'package:nexchat_real_time_messaging_app/core/theme/app_theme.dart';
import 'package:nexchat_real_time_messaging_app/core/theme/theme_provider.dart';

import 'package:nexchat_real_time_messaging_app/main.dart' show navigatorKey;

import 'features/auth/screens/register_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/settings/screens/settings_sceen.dart';

class NexChatApp extends ConsumerWidget {
  const NexChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(resolvedThemeModeProvider);

    return MaterialApp(
      title: 'NexChat',
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      // ── Theme ──────────────────────────────
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash:    (_) => SplashScreen(),
        AppRoutes.login:     (_) => LoginScreen(),
        AppRoutes.register:  (_) => RegisterScreen(),
        AppRoutes.profile:   (_) => ProfileScreen(),
        AppRoutes.dashboard: (_) => DashboardScreen(),
        AppRoutes.discover:  (_) => RadarScreen(),
        AppRoutes.chat:      (_) => ChatListScreen(filter: ChatType.direct),
        AppRoutes.groups:    (_) => ChatListScreen(filter: ChatType.group),
        AppRoutes.settings:  (_) => SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.otp) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: args['verificationId'],
              phoneNumber:    args['phoneNumber'],
            ),
          );
        }

        if (settings.name == AppRoutes.chatRoom) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId:          args['chatId']          as String,
              otherUserId:     args['otherUserId']     as String,
              otherUserName:   args['otherUserName']   as String,
              otherUserAvatar: args['otherUserAvatar'] as String,
              isGroup:         args['isGroup']         as bool? ?? false,
              groupName:       args['groupName']       as String?,
            ),
          );
        }

        if (settings.name == AppRoutes.groupInfo) {
          final args = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (_) => GroupInfoScreen(
              chatId: args['chatId'] as String,
            ),
          );
        }

        return null;
      },
    );
  }
}