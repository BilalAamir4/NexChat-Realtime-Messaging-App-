import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import 'group_creation_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  final ChatType? filter;
  const ChatListScreen({super.key, this.filter});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final List<bool> _waveDots = [true, false, false];
  Timer? _timer;

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  String get _title {
    if (widget.filter == ChatType.group) return 'Groups';
    return 'Chats';
  }

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
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      return {
        'name': data?['displayName'] as String? ?? 'Unknown',
        'photo': data?['photoURL'] as String? ?? '',
      };
    } catch (_) {
      return {'name': 'Unknown', 'photo': ''};
    }
  }

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
              color: NexColors.indigo, shape: BoxShape.circle),
        );
      }),
    );
  }

  Widget _buildPreviewBubble(String text,
      {bool isSent = false, bool isTyping = false}) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          gradient: isSent
              ? const LinearGradient(
              colors: [NexColors.indigo, NexColors.violet],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight)
              : null,
          color: isSent ? null : context.receivedBubbleBg,
          border: isSent
              ? null
              : Border.all(color: context.receivedBubbleBorder, width: 0.8),
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
            color: isSent ? Colors.white : context.textPrimary,
            fontSize: 13.5,
            height: 1.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildAvatar(
      {double radius = 24,
        String? photoUrl,
        String? name,
        bool isGroup = false}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: photoUrl == null || photoUrl.isEmpty
            ? const LinearGradient(
            colors: [NexColors.indigo, NexColors.violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight)
            : null,
        border: Border.all(color: context.cardBorder, width: 2),
        boxShadow: [
          BoxShadow(
              color: NexColors.indigo.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
          : Center(
        child: isGroup
            ? Icon(Icons.group_rounded,
            color: Colors.white, size: radius * 0.85)
            : name != null && name.isNotEmpty
            ? Text(name[0].toUpperCase(),
            style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w700))
            : Icon(Icons.person,
            color: Colors.white, size: radius * 0.85),
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat, String name, String photoUrl) {
    final isGroup = chat.type == ChatType.group;
    final lastMsg = chat.lastMessage;
    final isSent = lastMsg?.senderId == _myUid;
    final unread = chat.unreadFor(_myUid);
    final timeStr = _formatTime(lastMsg?.sentAt);
    final previewText = lastMsg?.text ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      splashColor: NexColors.indigo200.withValues(alpha: 0.3),
      highlightColor: NexColors.indigo100.withValues(alpha: 0.2),
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.chatRoom, arguments: {
            'chatId': chat.chatId,
            'otherUserId': isGroup ? '' : chat.otherUserId(_myUid),
            'otherUserName': name,
            'otherUserAvatar': photoUrl,
            'isGroup': isGroup,
            'groupName': chat.groupName,
          }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10, left: 14, right: 14),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(color: context.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
                color: NexColors.indigo.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(
                radius: 24, photoUrl: photoUrl, name: name, isGroup: isGroup),
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
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: context.textPrimary,
                            letterSpacing: -0.2),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.receivedBubbleBg,
                          borderRadius: BorderRadius.circular(20),
                          border:
                          Border.all(color: context.cardBorder, width: 0.8),
                        ),
                        child: Text(timeStr,
                            style: TextStyle(
                                color: context.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _buildPreviewBubble(previewText, isSent: isSent),
                  if (unread > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [NexColors.violet, NexColors.indigo],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: NexColors.violet.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(unread.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3)),
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
              decoration: BoxDecoration(
                color: context.cardSurface,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                        color: context.cardBorder,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Search conversations',
                          style: TextStyle(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      cursorColor: NexColors.indigo,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: TextStyle(color: context.textMuted),
                        prefixIcon:
                        const Icon(Icons.search, color: NexColors.indigo),
                        filled: true,
                        fillColor: context.isDark
                            ? NexColors.darkSurface
                            : NexColors.lightCardSurface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: context.cardBorder, width: 1)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: context.cardBorder, width: 1)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: NexColors.indigo, width: 1.8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(
                      color: context.cardBorder.withValues(alpha: 0.5),
                      height: 1,
                      indent: 16,
                      endIndent: 16),
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
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: _buildAvatar(radius: 21, name: name),
      title: Text(name,
          style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14)),
      subtitle: Text('Tap to open chat',
          style: TextStyle(color: context.textMuted, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: context.cardBorder),
      onTap: () => Navigator.pop(context),
    );
  }

  // ─────────────────────────────────────────────
  //  Polished Drawer
  // ─────────────────────────────────────────────
  Widget _buildDrawer() {
    final isDark = context.isDark;

    return Drawer(
      backgroundColor:
      isDark ? NexColors.darkCard : const Color(0xFFF4F6FF),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────
          _DrawerHeader(),

          const SizedBox(height: 8),

          // ── Nav items ───────────────────────────────
          _drawerTile(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            sub: 'View & edit your profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          _drawerTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            sub: 'App preferences & theme',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),

          const Spacer(),

          // ── Footer ──────────────────────────────────
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.cardBorder.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [NexColors.indigo, NexColors.violet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NexChat',
                style: TextStyle(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String label,
    String? sub,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: NexColors.indigo.withValues(alpha: 0.08),
          highlightColor: NexColors.indigo.withValues(alpha: 0.04),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.cardBorder.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon container with left accent bar
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NexColors.indigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: NexColors.indigo, size: 20),
                    ),
                    // Left accent bar
                    Positioned(
                      left: 0,
                      top: 6,
                      bottom: 6,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [NexColors.indigo, NexColors.violet],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (sub != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: context.textMuted,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsStreamProvider);
    final isGroupsScreen = widget.filter == ChatType.group;

    return Scaffold(
      backgroundColor:
      context.isDark ? NexColors.darkPage : NexColors.lightPageDark,
      drawer: _buildDrawer(),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        height: 66,
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: context.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
                color: NexColors.indigo.withValues(alpha: 0.1),
                blurRadius: 28,
                offset: const Offset(0, 10))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.filter != ChatType.direct) {
                    Navigator.pushReplacementNamed(context, AppRoutes.chat);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_rounded,
                        color: !isGroupsScreen
                            ? NexColors.indigo
                            : context.textMuted,
                        size: 22),
                    const SizedBox(height: 3),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: !isGroupsScreen
                                ? NexColors.indigo
                                : Colors.transparent,
                            shape: BoxShape.circle)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openSearchSheet,
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [NexColors.indigo, NexColors.violet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: NexColors.violet.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child:
                  const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.filter != ChatType.group) {
                    Navigator.pushReplacementNamed(context, AppRoutes.groups);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_rounded,
                        color: isGroupsScreen
                            ? NexColors.indigo
                            : context.textMuted,
                        size: 22),
                    const SizedBox(height: 3),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: isGroupsScreen
                                ? NexColors.indigo
                                : Colors.transparent,
                            shape: BoxShape.circle)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: isGroupsScreen
          ? FloatingActionButton(
          onPressed: () => showCreateGroupSheet(context),
          backgroundColor: NexColors.indigo,
          child:
          const Icon(Icons.group_add_rounded, color: Colors.white))
          : null,

      body: Container(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ─────────────────────────────────
              _buildAppBar(),

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
                          style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5),
                        ),
                        Text(
                          '${filtered.length} ${isGroupsScreen ? 'group' : 'conversation'}${filtered.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              color: context.textMuted, fontSize: 12),
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
                      child: CircularProgressIndicator(
                          color: NexColors.indigo)),
                  error: (e, st) => Center(
                      child: Text('Could not load chats',
                          style: TextStyle(color: context.textMuted))),
                  data: (chats) {
                    final filtered = widget.filter == null
                        ? chats
                        : chats
                        .where((c) => c.type == widget.filter)
                        .toList();

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
                              color: context.cardBorder,
                            ),
                            const SizedBox(height: 16),
                            Text(_emptyMessage,
                                style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(_emptySubMessage,
                                style: TextStyle(
                                    color: context.textMuted, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                      const EdgeInsets.only(top: 4, bottom: 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final chat = filtered[index];
                        if (chat.type == ChatType.group) {
                          return _buildChatItem(
                              chat, chat.groupName ?? 'Group', '');
                        }
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

  // ─────────────────────────────────────────────
  //  AppBar — lean: hamburger | title | bell
  // ─────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      decoration: BoxDecoration(
        color: context.isDark ? NexColors.darkCard : NexColors.lightPageLight,
        border: Border(
            bottom: BorderSide(color: context.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Hamburger
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu_rounded, color: context.textPrimary),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),

          // Title block
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(
                  context, AppRoutes.dashboard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 32,
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [NexColors.indigo, NexColors.indigo200]),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notification bell only — no profile icon
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications_outlined,
                    color: context.textPrimary),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: NexColors.violet, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Drawer Header — self-contained widget, avoids BuildContext issues
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerHeader extends ConsumerWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    // Pull real user data if available
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Bilal';
    final photoUrl = user?.photoURL ?? '';
    final initial =
    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'B';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? NexColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? NexColors.darkBorder
                : NexColors.indigo200.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with gradient ring + online badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Gradient ring
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [NexColors.indigo, NexColors.violet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? NexColors.darkCard : Colors.white,
                  ),
                  child: ClipOval(
                    child: photoUrl.isNotEmpty
                        ? Image.network(photoUrl, fit: BoxFit.cover)
                        : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [NexColors.indigo, NexColors.violet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Online badge — bottom-right of avatar
              Positioned(
                bottom: 2,
                right: 0,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E), // green-500
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                      isDark ? NexColors.darkSurface : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Name
          Text(
            displayName,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 4),

          // Phone / email sub-line
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 12, color: context.textMuted),
              const SizedBox(width: 5),
              Text(
                user?.phoneNumber ?? '+1 234 567 8900',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
