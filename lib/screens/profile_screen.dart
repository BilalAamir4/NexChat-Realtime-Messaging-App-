import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ── Palette (matches ChatListScreen & ChatScreen) ─────────────────────────
  static const _indigo = Color(0xFF4F46E5);
  static const _violet = Color(0xFF7C3AED);
  static const _indigo100 = Color(0xFFE0E7FF);
  static const _indigo200 = Color(0xFFC7D2FE);
  static const _cardSurface = Color(0xFFF7F8FF);
  static const _pageDark = Color(0xFFE8EEFF);
  static const _pageLight = Color(0xFFF0F4FF);
  static const _slateDark = Color(0xFF1E1B4B);
  static const _slateMid = Color(0xFF475569);
  static const _slateMuted = Color(0xFF94A3B8);

  // ── Reusable blue-white card decoration ───────────────────────────────────
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

  // ── Stat card ─────────────────────────────────────────────────────────────
  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: _blueCard,
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _indigo,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: _slateMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, {String? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _slateMid,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          if (action != null)
            Text(
              action,
              style: const TextStyle(
                color: _indigo,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ── Action pill button ────────────────────────────────────────────────────
  Widget _pillButton({
    required IconData icon,
    required String label,
    bool filled = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
            colors: [_indigo, _violet],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: filled ? null : _cardSurface,
          borderRadius: BorderRadius.circular(30),
          border: filled ? null : Border.all(color: _indigo200, width: 1),
          boxShadow: filled
              ? [
            BoxShadow(
              color: _violet.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: _indigo.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : _indigo),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : _indigo,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Device card ───────────────────────────────────────────────────────────
  Widget _deviceCard(IconData icon, String name, String lastActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _blueCard,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _indigo100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _indigo200, width: 1),
            ),
            child: Icon(icon, color: _indigo, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _slateDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lastActive,
                  style: const TextStyle(color: _slateMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _indigo100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _indigo200, width: 0.8),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: _indigo,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_pageDark, _pageLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // ── Hero SliverAppBar ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: _pageLight,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _indigo,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: _slateDark),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient banner
                    Container(
                      height: 170,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_indigo, _violet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      // Subtle decorative circles
                      child: Stack(
                        children: [
                          Positioned(
                            top: -30,
                            right: -30,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            left: 40,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar overlapping banner bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [_indigo, _violet],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: _indigo.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body content ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 14),

                  // Name + username
                  const Text(
                    'Bilal',
                    style: TextStyle(
                      color: _slateDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '@bilal.nx',
                    style: TextStyle(
                      color: _slateMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Online status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _indigo100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _indigo200, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Online',
                          style: TextStyle(
                            color: _slateMid,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Action pill buttons ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _pillButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Message',
                        filled: true,
                        onTap: () => Navigator.pushNamed(context, '/chat'),
                      ),
                      const SizedBox(width: 10),
                      _pillButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _pillButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () {},
                      ),
                    ],
                  ),

                  // ── About / Bio ──────────────────────────────────────────
                  _sectionHeader('ABOUT'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _indigo200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0F4F46E5),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Violet left accent bar
                          Container(
                            width: 3,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_indigo, _violet],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Flutter dev by day, dark mode enjoyer by night. Building NexChat — because every chat app deserves a little more personality.',
                              style: TextStyle(
                                color: _slateMid,
                                fontSize: 13.5,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Pinned quote ─────────────────────────────────────────
                  _sectionHeader('PINNED'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _indigo200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: _violet.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_indigo, _violet],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.format_quote_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '"Code is like humor. When you have to explain it, it\'s bad."',
                              style: TextStyle(
                                color: _slateDark,
                                fontSize: 13.5,
                                fontStyle: FontStyle.italic,
                                height: 1.55,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Stats ────────────────────────────────────────────────
                  _sectionHeader('STATS'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _statCard('1.2k', 'Messages'),
                        const SizedBox(width: 10),
                        _statCard('14', 'Groups'),
                        const SizedBox(width: 10),
                        _statCard('87', 'Friends'),
                      ],
                    ),
                  ),

                  // ── Media gallery ────────────────────────────────────────
                  _sectionHeader('MEDIA', action: 'See all'),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final colors = [
                          [_indigo, _violet],
                          [_violet, const Color(0xFFEC4899)],
                          [const Color(0xFF0EA5E9), _indigo],
                          [_indigo, const Color(0xFF06B6D4)],
                          [_violet, _indigo],
                          [const Color(0xFF6366F1), _violet],
                          [_indigo, const Color(0xFF8B5CF6)],
                          [_violet, const Color(0xFF3B82F6)],
                        ];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors[index % colors.length],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border:
                            Border.all(color: _indigo200, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: _indigo.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              index % 3 == 0
                                  ? Icons.image_outlined
                                  : index % 3 == 1
                                  ? Icons.videocam_outlined
                                  : Icons.mic_outlined,
                              color: Colors.white.withOpacity(0.75),
                              size: 26,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Active devices ───────────────────────────────────────
                  _sectionHeader('ACTIVE DEVICES'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _deviceCard(
                          Icons.smartphone_rounded,
                          'iPhone 14 Pro',
                          'Last active: just now',
                        ),
                        _deviceCard(
                          Icons.laptop_rounded,
                          'MacBook Pro',
                          'Last active: 2 hours ago',
                        ),
                        _deviceCard(
                          Icons.tablet_android_rounded,
                          'iPad Air',
                          'Last active: yesterday',
                        ),
                      ],
                    ),
                  ),

                  // ── Logout ───────────────────────────────────────────────
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _cardSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}