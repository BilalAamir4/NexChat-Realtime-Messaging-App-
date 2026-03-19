import 'dart:async';

import 'package:flutter/material.dart';

// ── Cool & Modern — Cool Blue-White Edition ──────────────────────────────────
// Page bg:      #E8EEFF → #F0F4FF  (indigo-tinted gradient)
// Card surface: #F7F8FF  — cool blue-white
// Card border:  #C7D2FE  (indigo-200)
// AppBar:       #F0F4FF
// Drawer:       #EEF2FF
// Sheet:        #F0F4FF → #F7F8FF
// Indigo:       #4F46E5  — primary actions
// Violet:       #7C3AED  — accents / gradients
// Indigo-200:   #C7D2FE  — borders
// Indigo-100:   #E0E7FF  — received bubble, chips
// Slate-900:    #1E1B4B  — headings
// Slate-600:    #475569  — body text
// Slate-400:    #94A3B8  — muted / timestamps
// ─────────────────────────────────────────────────────────────────────────────

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final List<bool> _waveDots = [true, false, false];
  Timer? _timer;

  // ── Palette ────────────────────────────────────────────────────────────────
  static const _indigo = Color(0xFF4F46E5);
  static const _violet = Color(0xFF7C3AED);
  static const _indigo100 = Color(0xFFE0E7FF); // received bubble, chip bg
  static const _indigo200 = Color(0xFFC7D2FE); // borders
  static const _indigo50 = Color(0xFFEEF2FF); // lightest — drawer bg
  static const _cardSurface = Color(0xFFF7F8FF); // blue-white card
  static const _pageDark = Color(0xFFE8EEFF); // page gradient top
  static const _pageLight = Color(0xFFF0F4FF); // page gradient bottom / AppBar
  static const _slateDark = Color(0xFF1E1B4B);
  static const _slateMid = Color(0xFF475569);
  static const _slateMuted = Color(0xFF94A3B8);
  static const _slateEdge = Color(0xFFCBD5E1);

  // Reusable blue-white card decoration
  static const BoxDecoration _blueCard = BoxDecoration(
    color: _cardSurface,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    border: Border.fromBorderSide(BorderSide(color: _indigo200, width: 1)),
    boxShadow: [
      BoxShadow(
        color: Color(0x0F4F46E5), // indigo at ~6% opacity
        blurRadius: 18,
        offset: Offset(0, 6),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        bool last = _waveDots.removeLast();
        _waveDots.insert(0, last);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Typing indicator ───────────────────────────────────────────────────────
  Widget buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: _waveDots[i] ? 6 : 3,
          decoration: BoxDecoration(color: _indigo, shape: BoxShape.circle),
        );
      }),
    );
  }

  // ── Message preview bubble ─────────────────────────────────────────────────
  Widget buildPreviewBubble(
    String text, {
    bool isSent = false,
    bool isTyping = false,
  }) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(top: 4),
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
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSent ? 16 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 16),
          ),
        ),
        child: isTyping
            ? buildTypingIndicator()
            : Text(
                text,
                style: TextStyle(
                  color: isSent ? Colors.white : _slateDark,
                  fontSize: 13.5,
                  height: 1.3,
                ),
              ),
      ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar({double radius = 24}) {
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
            color: _indigo.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Icons.person, color: Colors.white, size: radius * 0.85),
    );
  }

  // ── Chat list item ─────────────────────────────────────────────────────────
  Widget buildChatItem({
    required String name,
    String? lastMessage,
    String? time,
    bool isTyping = false,
    int unreadCount = 0,
    bool lastMessageSent = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      splashColor: _indigo200.withOpacity(0.3),
      highlightColor: _indigo100.withOpacity(0.2),
      onTap: () => Navigator.pushNamed(context, '/chat'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10, left: 14, right: 14),
        decoration: _blueCard,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _slateDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      // Timestamp chip — indigo-100 tinted
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _indigo100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _indigo200, width: 0.8),
                        ),
                        child: Text(
                          time ?? '',
                          style: const TextStyle(
                            color: _slateMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  buildPreviewBubble(
                    isTyping ? '' : (lastMessage ?? ''),
                    isSent: lastMessageSent,
                    isTyping: isTyping,
                  ),
                  if (unreadCount > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
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
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bottom sheet ────────────────────────────────────────────────────
  void openSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_pageLight, _cardSurface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag handle — indigo-200
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _indigo200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Search conversations',
                        style: TextStyle(
                          color: _slateDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search field — blue-white surface
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      cursorColor: _indigo,
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: const TextStyle(color: _slateMuted),
                        prefixIcon: const Icon(Icons.search, color: _indigo),
                        filled: true,
                        fillColor: _cardSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _indigo200,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _indigo200,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _indigo,
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    color: _indigo200.withOpacity(0.5),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        buildSearchResult('Alex Morgan'),
                        buildSearchResult('Sarah Lee'),
                        buildSearchResult('Dev Team'),
                        buildSearchResult('John Doe'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildSearchResult(String name) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: _buildAvatar(radius: 21),
      title: Text(
        name,
        style: const TextStyle(
          color: _slateDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: const Text(
        'Tap to open chat',
        style: TextStyle(color: _slateMuted, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: _indigo200),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/chat');
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageDark,

      // ── Drawer ────────────────────────────────────────────────────────────
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
              Icons.person_outline,
              'Profile',
              sub: 'View your profile',
            ),
            _drawerTile(
              Icons.settings_outlined,
              'Settings',
              sub: 'App preferences',
            ),
            _drawerTile(
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

      // ── Bottom nav bar ─────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        height: 66,
        decoration: BoxDecoration(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: _indigo200, width: 1),
          boxShadow: [
            BoxShadow(
              color: _indigo.withOpacity(0.1),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Chats — active
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_rounded,
                    color: _indigo,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: _indigo,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              // Search — gradient pill
              GestureDetector(
                onTap: openSearchSheet,
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_indigo, _violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _violet.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              // Groups — inactive
              const Icon(Icons.group_outlined, color: _slateMuted, size: 22),
            ],
          ),
        ),
      ),

      // ── Body ───────────────────────────────────────────────────────────────
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
              // AppBar — pageLight surface
              Container(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                decoration: const BoxDecoration(
                  color: _pageLight,
                  border: Border(
                    bottom: BorderSide(color: _indigo200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu_rounded, color: _slateDark),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chats',
                            style: TextStyle(
                              color: _slateDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          SizedBox(
                            width: 32,
                            height: 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_indigo, _indigo200],
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(4),
                                ),
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
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                      icon: const Icon(Icons.person_outline, color: _slateDark),
                    ),
                  ],
                ),
              ),

              // Section label
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent',
                      style: TextStyle(
                        color: _slateMid,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      '4 conversations',
                      style: TextStyle(color: _slateMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Chat list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    buildChatItem(
                      name: 'Alex Morgan',
                      lastMessage: 'Hey, are you coming today?',
                      time: '12:41',
                      unreadCount: 2,
                      lastMessageSent: false,
                    ),
                    buildChatItem(
                      name: 'Sarah Lee',
                      lastMessage: 'See you tomorrow!',
                      time: '11:05',
                      lastMessageSent: true,
                    ),
                    buildChatItem(
                      name: 'Dev Team',
                      isTyping: true,
                      time: '10:15',
                      unreadCount: 3,
                    ),
                    buildChatItem(
                      name: 'John Doe',
                      lastMessage: 'Can you review the document?',
                      time: '09:50',
                      lastMessageSent: false,
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

  // ── Drawer tile ────────────────────────────────────────────────────────────
  Widget _drawerTile(IconData icon, String label, {String? sub}) {
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
      onTap: () {},
    );
  }
}
