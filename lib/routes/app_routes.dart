import 'package:flutter/material.dart';

// Auth
import 'package:nexchat_real_time_messaging_app/features/auth/screens/splash_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/screens/login_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/screens/register_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/screens/otp_screen.dart';

// Main
import 'package:nexchat_real_time_messaging_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/chat/screens/chat_list_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/chat/screens/chat_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/chat/screens/goup_info_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/chat/models/chat_model.dart';
import 'package:nexchat_real_time_messaging_app/features/notifications/notifications_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/profile/screens/profile_screen.dart';
import 'package:nexchat_real_time_messaging_app/features/settings/screens/settings_sceen.dart';
import 'package:nexchat_real_time_messaging_app/features/user_discovery/screens/user_discovery.dart';

// ─────────────────────────────────────────────
//  Route name constants
// ─────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash        = '/';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String otp           = '/otp';
  static const String dashboard     = '/dashboard';
  static const String chat          = '/chat';
  static const String groups        = '/groups';
  static const String chatRoom      = '/chat-room';
  static const String createGroup   = '/create-group';
  static const String groupInfo     = '/group-info';
  static const String notifications = '/notifications';
  static const String profile       = '/profile';
  static const String settings      = '/settings';
  static const String discover      = '/discover';

  // ─────────────────────────────────────────────
  //  Route generator
  //  Wire up in app.dart: onGenerateRoute: AppRoutes.generateRoute
  //  No `routes:` map — it would override the custom transitions.
  // ─────────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {

    // ── Auth flow ───────────────────────────────────────────────────────

      case AppRoutes.splash:
        return _fade(const SplashScreen(), routeSettings);

      case AppRoutes.login:
      // Cinematic continuation of splash beam reveal — content rises up
        return _fadeSlideUp(const LoginScreen(), routeSettings);

      case AppRoutes.register:
      // Login → Register: forward horizontal shared-axis
        return _slideRight(const RegisterScreen(), routeSettings);

      case AppRoutes.otp:
      // OTP screen emerges after the phone-number bottom sheet
        final args = routeSettings.arguments as Map<String, dynamic>? ?? {};
        return _fadeScale(
          OtpScreen(
            verificationId: args['verificationId'] as String? ?? '',
            phoneNumber:    args['phoneNumber']    as String? ?? '',
          ),
          routeSettings,
        );

    // ── Main app ────────────────────────────────────────────────────────

      case AppRoutes.dashboard:
      // Stack-clearing navigation — pure fade
        return _fade(const DashboardScreen(), routeSettings);

      case AppRoutes.chat:
      // Dashboard → Chats: slides up from the bottom nav area
        return _slideUp(
          const ChatListScreen(filter: ChatType.direct),
          routeSettings,
        );

      case AppRoutes.groups:
      // Dashboard → Groups: same depth as chat, slides up
        return _slideUp(
          const ChatListScreen(filter: ChatType.group),
          routeSettings,
        );

      case AppRoutes.chatRoom:
      // Chat list → Chat room: drill into conversation (slides right)
        final args = routeSettings.arguments as Map<String, dynamic>? ?? {};
        return _slideRight(
          ChatScreen(
            chatId:          args['chatId']          as String? ?? '',
            otherUserId:     args['otherUserId']     as String? ?? '',
            otherUserName:   args['otherUserName']   as String? ?? '',
            otherUserAvatar: args['otherUserAvatar'] as String? ?? '',
            isGroup:         args['isGroup']         as bool?   ?? false,
            groupName:       args['groupName']       as String?,
          ),
          routeSettings,
        );

      case AppRoutes.groupInfo:
      // ChatRoom → Group info: drill deeper (slides right)
        final args = routeSettings.arguments as Map<String, dynamic>? ?? {};
        return _slideRight(
          GroupInfoScreen(chatId: args['chatId'] as String? ?? ''),
          routeSettings,
        );

      case AppRoutes.notifications:
      // Bell tap → drops down from the top bar
        return _slideDown(const NotificationsScreen(), routeSettings);

      case AppRoutes.profile:
      // Dashboard → Profile: card lifting up
        return _slideUp(const ProfileScreen(), routeSettings);

      case AppRoutes.settings:
      // Dashboard → Settings: consistent overlay feel
        return _slideUp(const SettingsScreen(), routeSettings);

      case AppRoutes.discover:
      // Dashboard → Discover: radar card expands into full screen
        return _scaleUp(const RadarScreen(), routeSettings);

      default:
        return _fade(const LoginScreen(), routeSettings);
    }
  }

  // ─────────────────────────────────────────────
  //  Transition builders
  // ─────────────────────────────────────────────

  /// Pure crossfade.
  /// Used for stack-clearing navigations and as a safe fallback.
  static PageRouteBuilder<T> _fade<T>(Widget page, RouteSettings s) {
    return PageRouteBuilder<T>(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  /// Fade + gentle upward slide (6 % of screen height).
  /// Splash → Login: login card rises into view after the beam reveal.
  static PageRouteBuilder<T> _fadeSlideUp<T>(Widget page, RouteSettings s) {
    return PageRouteBuilder<T>(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end:   Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Horizontal slide from right + fade.
  /// Standard forward navigation: Login→Register, Chat list→Chat room,
  /// Chat room→Group info.
  static PageRouteBuilder<T> _slideRight<T>(Widget page, RouteSettings s) {
    return PageRouteBuilder<T>(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        // Outgoing screen nudges left while incoming arrives from the right
        final outgoing = Tween<Offset>(
          begin: Offset.zero,
          end:   const Offset(-0.15, 0),
        ).animate(
          CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut),
        );
        return SlideTransition(
          position: outgoing,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0),
              end:   Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          ),
        );
      },
    );
  }

  /// Slide up from below + fade (10 % of screen height).
  /// Dashboard → Chat, Groups, Profile, Settings.
  static PageRouteBuilder<T> _slideUp<T>(Widget page, RouteSettings s) {
    return PageRouteBuilder<T>(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 370),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.10),
              end:   Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide down from above + fade (8 % of screen height).
  /// Notifications drops from the top bell icon.
  static PageRouteBuilder<T> _slideDown<T>(Widget page, RouteSettings s) {
    return PageRouteBuilder<T>(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end:   Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Fade + scale up from 93 %.
  /// Login/Register → OTP: screen emerges after the phone-number sheet.
  static PageRouteBuilder<T> _fadeScale<T>(Widget page, RouteSettings s) {
    return PageRouteBuilder<T>(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.93, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Scale up from 95 % + fade.
  /// Dashboard → Discover: the radar card expands into the full screen.
  static PageRouteBuilder<T> _scaleUp<T>(Widget page, RouteSettings s) {
    return PageRouteBuilder<T>(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}