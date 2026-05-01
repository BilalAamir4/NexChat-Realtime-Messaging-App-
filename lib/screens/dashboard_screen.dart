import 'package:flutter/material.dart';

// ── NexChat Dashboard Screen ──────────────────────────────────────────────────
// Landing screen after splash. Shows overview of Chats and Group Chats.
// No bottom nav — the two section cards serve as navigation.
// Drawer is inherited from ChatListScreen pattern.
// AppBar title "NexChat" is tappable (no-op here, already on dashboard).
// ChatListScreen/GroupChatScreen titles are tappable → pop back to dashboard.
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ── Palette (mirrors ChatListScreen) ───────────────────────────────────────
  static const _indigo = Color(0xFF4F46E5);
  static const _violet = Color(0xFF7C3AED);
  static const _indigo100 = Color(0xFFE0E7FF);
  static const _indigo200 = Color(0xFFC7D2FE);
  static const _indigo50 = Color(0xFFEEF2FF);
  static const _cardSurface = Color(0xFFF7F8FF);
  static const _pageDark = Color(0xFFE8EEFF);
  static const _pageLight = Color(0xFFF0F4FF);
  static const _slateDark = Color(0xFF1E1B4B);
  static const _slateMid = Color(0xFF475569);
  static const _slateMuted = Color(0xFF94A3B8);

  // ── Shared card decoration ─────────────────────────────────────────────────
  static const BoxDecoration _blueCard = BoxDecoration(
    color: _cardSurface,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    border: Border.fromBorderSide(BorderSide(color: _indigo200, width: 1)),
    boxShadow: [
      BoxShadow(
        color: Color(0x0F4F46E5),
        blurRadius: 18,
        offset: Offset(0, 6),
      ),
    ],
  );

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar({double radius = 21}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_indigo, _violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _indigo200, width: 2),
        boxShadow: [
          BoxShadow(
            color: _indigo.withOpacity(0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Icons.person, color: Colors.white, size: radius * 0.85),
    );
  }

  // ── Preview bubble (compact, read-only) ────────────────────────────────────
  Widget _buildPreviewBubble(String text, {bool isSent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: isSent
            ? const LinearGradient(
          colors: [_indigo, _violet],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : null,
        color: isSent ? null : _indigo100,
        border: isSent ? null : Border.all(color: _indigo200, width: 0.8),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isSent ? 12 : 4),
          bottomRight: Radius.circular(isSent ? 4 : 12),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isSent ? Colors.white : _slateDark,
          fontSize: 12.5,
          height: 1.3,
        ),
      ),
    );
  }

  // ── Single preview row inside a section card ───────────────────────────────
  Widget _buildPreviewRow({
    required String name,
    required String message,
    required String time,
    bool isSent = false,
    int unread = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: _slateDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    // Timestamp chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _indigo100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _indigo200, width: 0.8),
                      ),
                      child: Text(
                        time,
                        style: const TextStyle(
                          color: _slateMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildPreviewBubble(message, isSent: isSent),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_violet, _indigo],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _violet.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card (Chats or Groups) ─────────────────────────────────────────
  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String countLabel,
    required String route,
    required List<Widget> previews,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: _blueCard,
        child: Column(
          children: [
            // ── Card header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_indigo, _violet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _indigo.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _slateDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  // Count pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_indigo, _violet],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      countLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ─────────────────────────────────────────────────────
            Divider(
              color: _indigo200.withOpacity(0.6),
              height: 1,
              indent: 14,
              endIndent: 14,
            ),

            // ── Preview rows ─────────────────────────────────────────────────
            ...previews,

            const SizedBox(height: 4),

            // ── Footer — "View all" ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      color: _indigo,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _indigo,
                    size: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Drawer tile (mirrors ChatListScreen._drawerTile) ───────────────────────
  Widget _drawerTile(
      BuildContext context,
      IconData icon,
      String label, {
        String? sub,
        VoidCallback? onTap,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _indigo100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _indigo200, width: 1),
        ),
        child: Icon(icon, color: _indigo, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: _slateDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: sub != null
          ? Text(sub, style: const TextStyle(color: _slateMuted, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: _indigo200, size: 18),
      onTap: onTap ?? () {},
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageDark,

      // ── Drawer (mirrors ChatListScreen) ───────────────────────────────────
      drawer: Drawer(
        backgroundColor: _indigo50,
        child: Column(
          children: [
            // Header — indigo→violet gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_indigo, _violet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.45),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Bilal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _indigo200,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Online',
                        style: TextStyle(color: _indigo200, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _drawerTile(
              context,
              Icons.person_outline,
              'Profile',
              sub: 'View your profile',
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            _drawerTile(
              context,
              Icons.settings_outlined,
              'Settings',
              sub: 'App preferences',
            ),
            _drawerTile(
              context,
              Icons.palette_outlined,
              'Themes',
              sub: 'Change appearance',
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _indigo200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: _slateMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_pageDark, _pageLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: _pageLight,
                  border: Border(
                    bottom: BorderSide(color: _indigo200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Hamburger — opens drawer
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu_rounded, color: _slateDark),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    // Tappable title — already on dashboard so no-op,
                    // but keeps the same tap target pattern as child screens
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NexChat',
                            style: TextStyle(
                              color: _slateDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          SizedBox(
                            width: 40,
                            height: 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_indigo, _indigo200],
                                ),
                                borderRadius:
                                BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: _slateDark,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _violet,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    // Greeting
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good morning, Bilal 👋',
                            style: TextStyle(
                              color: _slateDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Here's what's waiting for you",
                            style: TextStyle(
                              color: _slateMuted,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Chats section card ────────────────────────────────
                    _buildSectionCard(
                      context: context,
                      icon: Icons.chat_bubble_rounded,
                      title: 'Chats',
                      countLabel: '24 chats',
                      route: '/chats',
                      previews: [
                        _buildPreviewRow(
                          name: 'Alex Morgan',
                          message: 'Hey, are you coming today?',
                          time: '12:41',
                          unread: 2,
                        ),
                        const SizedBox(height: 2),
                        _buildPreviewRow(
                          name: 'Sarah Lee',
                          message: 'See you tomorrow!',
                          time: '11:05',
                          isSent: true,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Groups section card ───────────────────────────────
                    _buildSectionCard(
                      context: context,
                      icon: Icons.group_rounded,
                      title: 'Group Chats',
                      countLabel: '6 groups',
                      route: '/groups', // add this route when GroupChatListScreen is ready
                      previews: [
                        _buildPreviewRow(
                          name: 'Dev Team',
                          message: 'Usman: PR is ready to review',
                          time: '10:15',
                          unread: 3,
                        ),
                        const SizedBox(height: 2),
                        _buildPreviewRow(
                          name: 'Family',
                          message: 'Ammi: Dinner at 8 tonight!',
                          time: '09:30',
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}