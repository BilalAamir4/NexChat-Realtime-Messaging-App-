/*import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexChat Premium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: PremiumTimelineChat(messages: dummyPremiumMessages),
    );
  }
}

final List<Message> dummyPremiumMessages = [
  Message(
    sender: 'Alice',
    text: 'Hey! Are we still reviewing the app design today?',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    isMe: false,
    time: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
  ),
  Message(
    sender: 'Alice',
    text: 'I have a few tweaks I want to suggest.',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    isMe: false,
    time: DateTime.now().subtract(const Duration(hours: 2, minutes: 28)),
  ),
  Message(
    sender: 'Me',
    text: 'Yes absolutely! The premium timeline layout looks great so far.',
    avatarUrl: 'https://i.pravatar.cc/150?img=11',
    isMe: true,
    time: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
  ),
  Message(
    sender: 'Me',
    text: 'Send over your tweaks whenever you are ready.',
    avatarUrl: 'https://i.pravatar.cc/150?img=11',
    isMe: true,
    time: DateTime.now().subtract(const Duration(hours: 1, minutes: 14)),
  ),
  Message(
    sender: 'Alice',
    text: 'Awesome, compiling them into a doc right now. Speak soon!',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    isMe: false,
    time: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
];

// ─────────────────────────────────────────────────────────
//  SOFT CARD DESIGN TOKENS
// ─────────────────────────────────────────────────────────
class _SoftCard {
  static const bgDark1 = Color(0xFF0D1B2E);
  static const bgDark2 = Color(0xFF0F172A);

  static const cardThemDark = Color(0xFF1C2A3F);
  static const cardThemLight = Color(0xFFFFFFFF);

  static const cardMeFrom = Color(0xFF1E40AF);
  static const cardMeMid = Color(0xFF2563EB);
  static const cardMeTo = Color(0xFF60A5FA);

  static const textPrimaryDark = Color(0xFFE2EAF5);
  static const textPrimaryLight = Color(0xFF1E293B);
  static const textMutedDark = Color(0xFF64748B);
  static const textMutedLight = Color(0xFF94A3B8);
  static const timelineDot = Color(0xFF3B82F6);

  static List<BoxShadow> cardMeShadow = [
    BoxShadow(color: Color(0x662563EB), blurRadius: 20, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x331E40AF), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static List<BoxShadow> cardThemShadowDark = [
    BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 5)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static List<BoxShadow> cardThemShadowLight = [
    BoxShadow(color: Color(0x18000000), blurRadius: 14, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static List<BoxShadow> dotShadow = [
    BoxShadow(color: Color(0x503B82F6), blurRadius: 12, spreadRadius: 2),
    BoxShadow(color: Color(0x283B82F6), blurRadius: 20, spreadRadius: 4),
  ];
}

// ─────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────
class PremiumTimelineChat extends StatelessWidget {
  final List<Message> messages;
  const PremiumTimelineChat({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, isDark),
      body: Stack(
        children: [
          _Background(isDark: isDark),
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final showAvatar =
                    index == 0 || messages[index - 1].sender != msg.sender;
                final prevSameUser =
                    index > 0 && messages[index - 1].sender == msg.sender;
                return _TimelineRow(
                  message: msg,
                  isDark: isDark,
                  showAvatar: showAvatar,
                  grouped: prevSameUser,
                  isLastMessage: index == messages.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.72),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 14),
                    _GlowAvatar(
                      url: 'https://i.pravatar.cc/150?img=5',
                      size: 38,
                      glowColor: _SoftCard.timelineDot,
                      isOnline: true,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alice Laurent',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? _SoftCard.textPrimaryDark
                                  : _SoftCard.textPrimaryLight,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _AppBarIconBtn(icon: Icons.call_rounded, isDark: isDark),
                    const SizedBox(width: 4),
                    _AppBarIconBtn(
                      icon: Icons.videocam_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _AppBarIconBtn(
                      icon: Icons.more_vert_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BACKGROUND
// ─────────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  final bool isDark;
  const _Background({required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (!isDark) return Container(color: const Color(0xFFF1F5FB));
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_SoftCard.bgDark1, _SoftCard.bgDark2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TIMELINE ROW
// ─────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final Message message;
  final bool isDark;
  final bool showAvatar;
  final bool grouped;
  final bool isLastMessage;

  const _TimelineRow({
    required this.message,
    required this.isDark,
    required this.showAvatar,
    required this.grouped,
    required this.isLastMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: grouped ? 5 : 16, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LEFT — them
          Expanded(
            child: message.isMe
                ? const SizedBox()
                : _SoftCardBubble(
                    message: message,
                    isDark: isDark,
                    showAvatar: showAvatar,
                    isMe: false,
                    grouped: grouped,
                  ),
          ),

          // CENTER — dot + time
          _TimelineSpine(isDark: isDark, time: _fmt(message.time)),

          // RIGHT — me
          Expanded(
            child: message.isMe
                ? _SoftCardBubble(
                    message: message,
                    isDark: isDark,
                    showAvatar: showAvatar,
                    isMe: true,
                    grouped: grouped,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) => "${t.hour}:${t.minute.toString().padLeft(2, '0')}";
}

// ─────────────────────────────────────────────────────────
//  TIMELINE SPINE — Soft Card: large glowing dot
// ─────────────────────────────────────────────────────────
class _TimelineSpine extends StatelessWidget {
  final bool isDark;
  final String time;

  const _TimelineSpine({required this.isDark, required this.time});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large glowing dot
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark ? _SoftCard.bgDark1 : Colors.white,
                width: 2.5,
              ),
              boxShadow: _SoftCard.dotShadow,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: isDark
                  ? _SoftCard.textMutedDark
                  : _SoftCard.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SOFT CARD BUBBLE
// ─────────────────────────────────────────────────────────
class _SoftCardBubble extends StatelessWidget {
  final Message message;
  final bool isDark;
  final bool showAvatar;
  final bool isMe;
  final bool grouped;

  const _SoftCardBubble({
    required this.message,
    required this.isDark,
    required this.showAvatar,
    required this.isMe,
    required this.grouped,
  });

  @override
  Widget build(BuildContext context) {
    const r = 18.0;
    const s = 5.0;
    final br = grouped
        ? (isMe
              ? const BorderRadius.only(
                  topLeft: Radius.circular(r),
                  bottomLeft: Radius.circular(r),
                  topRight: Radius.circular(s),
                  bottomRight: Radius.circular(r),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(s),
                  bottomLeft: Radius.circular(r),
                  topRight: Radius.circular(r),
                  bottomRight: Radius.circular(r),
                ))
        : BorderRadius.circular(r);

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        if (showAvatar) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMe) ...[
                _GlowAvatar(
                  url: message.avatarUrl,
                  size: 30,
                  glowColor: _SoftCard.timelineDot,
                  isOnline: false,
                  isDark: isDark,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                message.sender,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.4),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 7),
                _GlowAvatar(
                  url: message.avatarUrl,
                  size: 30,
                  glowColor: _SoftCard.cardMeMid,
                  isOnline: false,
                  isDark: isDark,
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
        ],

        // Card
        isMe
            ? _MeCard(message: message, borderRadius: br)
            : _ThemCard(message: message, isDark: isDark, borderRadius: br),
      ],
    );
  }
}

// "Me" — gradient card with inset highlight
class _MeCard extends StatelessWidget {
  final Message message;
  final BorderRadius borderRadius;
  const _MeCard({required this.message, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _SoftCard.cardMeFrom,
            _SoftCard.cardMeMid,
            _SoftCard.cardMeTo,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
        boxShadow: _SoftCard.cardMeShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// "Them" — frosted card
class _ThemCard extends StatelessWidget {
  final Message message;
  final bool isDark;
  final BorderRadius borderRadius;
  const _ThemCard({
    required this.message,
    required this.isDark,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? _SoftCard.cardThemDark : _SoftCard.cardThemLight,
        borderRadius: borderRadius,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? _SoftCard.cardThemShadowDark
            : _SoftCard.cardThemShadowLight,
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: isDark
              ? _SoftCard.textPrimaryDark
              : _SoftCard.textPrimaryLight,
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  GLOW AVATAR
// ─────────────────────────────────────────────────────────
class _GlowAvatar extends StatelessWidget {
  final String url;
  final double size;
  final Color glowColor;
  final bool isOnline;
  final bool isDark;
  const _GlowAvatar({
    required this.url,
    required this.size,
    required this.glowColor,
    required this.isOnline,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF2563EB),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? _SoftCard.bgDark1 : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  APP BAR ICON BUTTON
// ─────────────────────────────────────────────────────────
class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _AppBarIconBtn({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MESSAGE MODEL
// ─────────────────────────────────────────────────────────
class Message {
  final String sender;
  final String text;
  final String avatarUrl;
  final bool isMe;
  final DateTime time;

  const Message({
    required this.sender,
    required this.text,
    required this.avatarUrl,
    required this.isMe,
    required this.time,
  });
}
*/
