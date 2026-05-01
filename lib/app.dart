import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexchat_real_time_messaging_app/routes/app_routes.dart';

// Auth screens
import 'package:nexchat_real_time_messaging_app/screens/splash_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/login_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/register_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/otp_screen.dart';

// Main screens
import 'package:nexchat_real_time_messaging_app/screens/chat_list_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/chat_screen.dart';
import 'package:nexchat_real_time_messaging_app/screens/profile_screen.dart';

class NexChatApp extends ConsumerWidget {
  const NexChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'NexChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFE8EEFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash:    (_) => const SplashScreen(),
        AppRoutes.login:     (_) => const LoginScreen(),
        AppRoutes.register:  (_) => const RegisterScreen(),
        AppRoutes.chat:      (_) => const ChatListScreen(),
        AppRoutes.profile:   (_) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        // OTP screen — needs verificationId + phoneNumber
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
              otherUserName:   args['otherUserName']   as String,
              otherUserAvatar: args['otherUserAvatar'] as String,
            ),
          );
        }
        return null;
      },
    );
  }
}