import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexchat_real_time_messaging_app/routes/app_routes.dart';
import 'package:nexchat_real_time_messaging_app/screens/goup_info_screen.dart';

// Auth screens
import 'package:nexchat_real_time_messaging_app/screens/splash_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/login_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/register_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/otp_screen.dart';

// Main screens
import 'package:nexchat_real_time_messaging_app/screens/chat_list_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/chat_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/profile_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/dashboard_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/user_discovery.dart';
import 'package:nexchat_real_time_messaging_app/features/chat/models/chat_model.dart';

// ↓ ADD THIS IMPORT
import 'package:nexchat_real_time_messaging_app/main.dart' show navigatorKey;

class NexChatApp extends ConsumerWidget {
  const NexChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'NexChat',
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFE8EEFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
        ),
      ),
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