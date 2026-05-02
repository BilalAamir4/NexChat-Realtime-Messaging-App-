import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../features/chat/models/chat_model.dart';
import '../features/chat/providers/chat_provider.dart';
import '../routes/app_routes.dart';
import 'group_creation_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  final ChatType?
  filter; // null = all, ChatType.direct = chats, ChatType.group = groups
  const ChatListScreen({super.key, this.filter});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final List<bool> _waveDots = [true, false, false];
  Timer? _timer;

  // ── Palette ────────────────────────────────────────────────────────────────
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

  static const BoxDecoration _blueCard = BoxDecoration(
    color: _cardSurface,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    border: Border.fromBorderSide(BorderSide(color: _indigo200, width: 1)),
    boxShadow: [
      BoxShadow(color: Color(0x0F4F46E5), blurRadius: 18, offset: Offset(0, 6)),
    ],
  );

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  // Returns the screen title based on filter
  String get _title {
    if (widget.filter == ChatType.group) return 'Groups';
    if (widget.filter == ChatType.direct) return 'Chats';
    return 'Chats';
  }

  // Returns the empty state message based on filter
  String get _emptyMessage {
    if (widget.filter == ChatType.group) return 'No groups yet';
    return 'No conversations yet';
  }

  String get _emptySubMessage {
    if (widget.filter == ChatType.group) return 'Create a group to get started';
    return 'Start a new chat to get going';
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        final last = _waveDots.removeLast();
        _waveDots.insert(0, last);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('MMM d').format(dt);
  }

  Future<Map<String, String>> _fetchUserInfo(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      return {
        'name': data?['displayName'] as String? ?? 'Unknown',
        'photo': data?['photoURL'] as String? ?? '',
      };
    } catch (_) {
      return {'name': 'Unknown', 'photo': ''};
    }
  }

  // ── Typing indicator ───────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: _waveDots[i] ? 6 : 3,
          decoration: const BoxDecoration(
            color: _indigo,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // ── Preview bubble ─────────────────────────────────────────────────────────
  Widget _buildPreviewBubble(
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
            ? _buildTypingIndicator()
            : Text(
                text,
                style: TextStyle(
                  color: isSent ? Colors.white : _slateDark,
                  fontSize: 13.5,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar({
    double radius = 24,
    String? photoUrl,
    String? name,
    bool isGroup = false,
  }) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: photoUrl == null || photoUrl.isEmpty
            ? const LinearGradient(
                colors: [_indigo, _violet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(color: _indigo200, width: 2),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
          : Center(
              child: isGroup
                  ? Icon(
                      Icons.group_rounded,
                      color: Colors.white,
                      size: radius * 0.85,
                    )
                  : name != null && name.isNotEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: radius * 0.75,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: Colors.white,
                      size: radius * 0.85,
                    ),
            ),
    );
  }

  // ── Chat list item ─────────────────────────────────────────────────────────
  Widget _buildChatItem(ChatModel chat, String name, String photoUrl) {
    final isGroup = chat.type == ChatType.group;
    final isTyping = false;
    final lastMsg = chat.lastMessage;
    final isSent = lastMsg?.senderId == _myUid;
    final unread = chat.unreadFor(_myUid);
    final timeStr = _formatTime(lastMsg?.sentAt);
    final previewText = lastMsg?.text ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      splashColor: _indigo200.withValues(alpha: 0.3),
      highlightColor: _indigo100.withValues(alpha: 0.2),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.chatRoom,
        arguments: {
          'chatId': chat.chatId,
          'otherUserName': name,
          'otherUserAvatar': photoUrl,
          'isGroup': isGroup,
          'groupName': chat.groupName,
        },
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10, left: 14, right: 14),
        decoration: _blueCard,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(
              radius: 24,
              photoUrl: photoUrl,
              name: name,
              isGroup: isGroup,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isGroup ? (chat.groupName ?? 'Group') : name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _slateDark,
                          letterSpacing: -0.2,
                        ),
                      ),
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
                          timeStr,
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
                  _buildPreviewBubble(
                    isTyping ? '' : previewText,
                    isSent: isSent,
                    isTyping: isTyping,
                  ),
                  if (unread > 0)
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
                              color: _violet.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          unread.toString(),
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
  void _openSearchSheet() {
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
                    color: _indigo200.withValues(alpha: 0.5),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildSearchResult('Alex Morgan'),
                        _buildSearchResult('Sarah Lee'),
                        _buildSearchResult('Dev Team'),
                        _buildSearchResult('John Doe'),
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

  Widget _buildSearchResult(String name) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: _buildAvatar(radius: 21, name: name),
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
      onTap: () => Navigator.pop(context),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsStreamProvider);
    final isGroupsScreen = widget.filter == ChatType.group;

    return Scaffold(
      backgroundColor: _pageDark,

      // ── Drawer ──────────────────────────────────────────────────────────
      drawer: Drawer(
        backgroundColor: _indigo50,
        child: Column(
          children: [
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
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
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

      // ── Bottom nav ───────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        height: 66,
        decoration: BoxDecoration(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: _indigo200, width: 1),
          boxShadow: [
            BoxShadow(
              color: _indigo.withValues(alpha: 0.1),
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
              // Chats tab
              GestureDetector(
                onTap: () {
                  if (widget.filter != ChatType.direct) {
                    Navigator.pushReplacementNamed(context, AppRoutes.chat);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: !isGroupsScreen ? _indigo : _slateMuted,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: !isGroupsScreen ? _indigo : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              // Search button
              GestureDetector(
                onTap: _openSearchSheet,
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
                        color: _violet.withValues(alpha: 0.4),
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
              // Groups tab
              GestureDetector(
                onTap: () {
                  if (widget.filter != ChatType.group) {
                    Navigator.pushReplacementNamed(context, AppRoutes.groups);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_rounded,
                      color: isGroupsScreen ? _indigo : _slateMuted,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isGroupsScreen ? _indigo : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB — only show on groups screen ────────────────────────────────
      floatingActionButton: isGroupsScreen
          ? FloatingActionButton(
              onPressed: () => showCreateGroupSheet(context),
              backgroundColor: _indigo,
              child: const Icon(Icons.group_add_rounded, color: Colors.white),
            )
          : null,

      // ── Body ────────────────────────────────────────────────────────────
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
              // AppBar
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.dashboard,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: const TextStyle(
                                color: _slateDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const SizedBox(
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
                    ),
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
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      icon: const Icon(Icons.person_outline, color: _slateDark),
                    ),
                  ],
                ),
              ),

              // Section label
              chatsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (chats) {
                  final filtered = widget.filter == null
                      ? chats
                      : chats.where((c) => c.type == widget.filter).toList();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isGroupsScreen ? 'Your Groups' : 'Recent',
                          style: const TextStyle(
                            color: _slateMid,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${filtered.length} ${isGroupsScreen ? 'group' : 'conversation'}${filtered.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: _slateMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Chat list
              Expanded(
                child: chatsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _indigo),
                  ),
                  error: (e, st) => const Center(
                    child: Text(
                      'Could not load chats',
                      style: TextStyle(color: _slateMuted),
                    ),
                  ),
                  data: (chats) {
                    // Apply filter
                    final filtered = widget.filter == null
                        ? chats
                        : chats.where((c) => c.type == widget.filter).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGroupsScreen
                                  ? Icons.group_outlined
                                  : Icons.chat_bubble_outline_rounded,
                              size: 56,
                              color: _indigo200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _emptyMessage,
                              style: const TextStyle(
                                color: _slateDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _emptySubMessage,
                              style: const TextStyle(
                                color: _slateMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final chat = filtered[index];

                        // For group chats, no need to fetch user info
                        if (chat.type == ChatType.group) {
                          return _buildChatItem(
                            chat,
                            chat.groupName ?? 'Group',
                            '',
                          );
                        }

                        // For direct chats, fetch the other user's info
                        final otherUid = chat.otherUserId(_myUid);
                        return FutureBuilder<Map<String, String>>(
                          future: _fetchUserInfo(otherUid),
                          builder: (context, snapshot) {
                            final name = snapshot.data?['name'] ?? '...';
                            final photo = snapshot.data?['photo'] ?? '';
                            return _buildChatItem(chat, name, photo);
                          },
                        );
                      },
                    );
                  },
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
