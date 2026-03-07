import 'package:flutter/material.dart';

import '../screens/chat_list_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/verify_email_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignupScreen(),
    '/verify': (context) => const VerifyEmailScreen(),
    '/chats': (context) => const ChatListScreen(),
    '/chat': (context) => const ChatScreen(),
    '/profile': (context) => const ProfileScreen(),
  };
}
