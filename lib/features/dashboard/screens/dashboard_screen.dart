import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../chat/models/chat_model.dart';
import '../../chat/providers/chat_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _radarCtrl;
  late final Animation<double> _radarPulse;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _radarPulse = CurvedAnimation(parent: _radarCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      return {
        'name':  data?['displayName'] as String? ?? 'Unknown',
        'photo': data?['photoURL']    as String? ?? '',
      };
    } catch (_) {
      return {'name': 'Unknown', 'photo': ''};
    }
  }

  Widget _buildAvatar({double radius = 21}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [NexColors.indigo, NexColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: context.cardBorder, width: 2),
        boxShadow: [
          BoxShadow(color: NexColors.indigo.withValues(alpha: 0.22), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(Icons.person, color: Colors.white, size: radius * 0.85),
    );
  }

  Widget _buildPreviewBubble(String text, {bool isSent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: isSent
            ? const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
            begin: Alignment.centerLeft, end: Alignment.centerRight)
            : null,
        color: isSent ? null : context.receivedBubbleBg,
        border: isSent ? null : Border.all(color: context.receivedBubbleBorder, width: 0.8),
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
          color: isSent ? Colors.white : context.textPrimary,
          fontSize: 12.5, height: 1.3,
        ),
      ),
    );
  }

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
                      child: Text(name,
                          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700,
                              fontSize: 13.5, letterSpacing: -0.2)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.receivedBubbleBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.cardBorder, width: 0.8),
                      ),
                      child: Text(time,
                          style: TextStyle(color: context.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildPreviewBubble(message, isSent: isSent)),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [NexColors.violet, NexColors.indigo],
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: NexColors.violet.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Text(unread.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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

  List<Widget> _buildRealPreviews(List<ChatModel> chats) {
    if (chats.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Text('No conversations yet', style: TextStyle(color: context.textMuted, fontSize: 13)),
        ),
      ];
    }

    final preview = chats.take(2).toList();

    return [
      ...preview.map((chat) {
        final lastMsg = chat.lastMessage;
        final isSent  = lastMsg?.senderId == _myUid;
        final unread  = chat.unreadFor(_myUid);
        final timeStr = _formatTime(lastMsg?.sentAt);
        final msgText = lastMsg?.text ?? '';

        if (chat.type == ChatType.group) {
          return Column(children: [
            _buildPreviewRow(name: chat.groupName ?? 'Group', message: msgText,
                time: timeStr, isSent: isSent, unread: unread),
            const SizedBox(height: 2),
          ]);
        }

        final otherUid = chat.otherUserId(_myUid);
        return FutureBuilder<Map<String, String>>(
          future: _fetchUserInfo(otherUid),
          builder: (context, snapshot) {
            final name = snapshot.data?['name'] ?? '…';
            return Column(children: [
              _buildPreviewRow(name: name, message: msgText,
                  time: timeStr, isSent: isSent, unread: unread),
              const SizedBox(height: 2),
            ]);
          },
        );
      }),
      const SizedBox(height: 6),
    ];
  }

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
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(color: context.cardBorder, width: 1),
          boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800,
                            fontSize: 16, letterSpacing: -0.3)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                          begin: Alignment.centerLeft, end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(countLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  ),
                ],
              ),
            ),
            Divider(color: context.cardBorder.withValues(alpha: 0.6), height: 1, indent: 14, endIndent: 14),
            ...previews,
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text('View all', style: TextStyle(color: NexColors.indigo, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, color: NexColors.indigo, size: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.discover),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          gradient: const LinearGradient(
            colors: [Color(0xFF3730A3), NexColors.indigo, NexColors.violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _radarPulse,
                  builder: (_, __) => CustomPaint(painter: _RadarMiniPainter(progress: _radarPulse.value)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.radar_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Discover People',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                                  fontSize: 17, letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text('Find & connect with new users',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15)),
                      child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
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

  /// Builds a styled AppBar icon button with an optional notification dot.
  Widget _appBarIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.receivedBubbleBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cardBorder, width: 1),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: context.textPrimary, size: 20)),
            if (showDot)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: NexColors.violet,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync  = ref.watch(chatsStreamProvider);
    final currentUser = ref.watch(currentUserProvider);

    final firstName = currentUser.when(
      data:    (u) => u?.displayName.split(' ').first ?? 'there',
      loading: () => '…',
      error:   (_, __) => 'there',
    );

    final directChats = chatsAsync.when(
      data:    (list) => list.where((c) => c.type == ChatType.direct).toList(),
      loading: () => <ChatModel>[],
      error:   (_, __) => <ChatModel>[],
    );

    final groupChats = chatsAsync.when(
      data:    (list) => list.where((c) => c.type == ChatType.group).toList(),
      loading: () => <ChatModel>[],
      error:   (_, __) => <ChatModel>[],
    );

    final chatCount  = chatsAsync.maybeWhen(data: (list) => list.where((c) => c.type == ChatType.direct).length, orElse: () => null);
    final groupCount = chatsAsync.maybeWhen(data: (list) => list.where((c) => c.type == ChatType.group).length, orElse: () => null);

    String chatLabel(int? count)  => count == null ? '…' : '$count ${count == 1 ? 'chat' : 'chats'}';
    String groupLabel(int? count) => count == null ? '…' : '$count ${count == 1 ? 'group' : 'groups'}';

    return Scaffold(
      backgroundColor: context.isDark ? NexColors.darkPage : NexColors.lightPageDark,
      body: Container(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
                decoration: BoxDecoration(
                  color: context.isDark ? NexColors.darkCard : NexColors.lightPageLight,
                  border: Border(bottom: BorderSide(color: context.cardBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    // Brand
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NexChat',
                              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800,
                                  fontSize: 22, letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          Container(
                            width: 40, height: 3,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [NexColors.indigo, NexColors.indigo200]),
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notification bell
                    _appBarIconButton(
                      icon: Icons.notifications_outlined,
                      showDot: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),

                    // Settings
                    _appBarIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                    const SizedBox(width: 8),

                    // Profile avatar
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [NexColors.indigo, NexColors.violet],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: context.cardBorder, width: 2),
                          boxShadow: [
                            BoxShadow(color: NexColors.indigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ──────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good morning, $firstName 👋',
                              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800,
                                  fontSize: 20, letterSpacing: -0.4)),
                          const SizedBox(height: 4),
                          Text("Here's what's waiting for you",
                              style: TextStyle(color: context.textMuted, fontSize: 13.5)),
                        ],
                      ),
                    ),

                    chatsAsync.when(
                      loading: () => _buildSectionCard(context: context, icon: Icons.chat_bubble_rounded,
                          title: 'Chats', countLabel: '…', route: AppRoutes.chat,
                          previews: [const Padding(padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
                              child: Center(child: SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(color: NexColors.indigo, strokeWidth: 2))))]),
                      error: (e, _) => _buildSectionCard(context: context, icon: Icons.chat_bubble_rounded,
                          title: 'Chats', countLabel: '0 chats', route: AppRoutes.chat, previews: _buildRealPreviews([])),
                      data: (_) => _buildSectionCard(context: context, icon: Icons.chat_bubble_rounded,
                          title: 'Chats', countLabel: chatLabel(chatCount), route: AppRoutes.chat,
                          previews: _buildRealPreviews(directChats)),
                    ),

                    const SizedBox(height: 14),

                    chatsAsync.when(
                      loading: () => _buildSectionCard(context: context, icon: Icons.group_rounded,
                          title: 'Group Chats', countLabel: '…', route: AppRoutes.groups,
                          previews: [const Padding(padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
                              child: Center(child: SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(color: NexColors.indigo, strokeWidth: 2))))]),
                      error: (e, _) => _buildSectionCard(context: context, icon: Icons.group_rounded,
                          title: 'Group Chats', countLabel: '0 groups', route: AppRoutes.groups, previews: _buildRealPreviews([])),
                      data: (_) => _buildSectionCard(context: context, icon: Icons.group_rounded,
                          title: 'Group Chats', countLabel: groupLabel(groupCount), route: AppRoutes.groups,
                          previews: _buildRealPreviews(groupChats)),
                    ),

                    const SizedBox(height: 14),
                    _buildDiscoverCard(context),
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

// ── Radar mini painter ────────────────────────────────────────────────────────
class _RadarMiniPainter extends CustomPainter {
  final double progress;
  const _RadarMiniPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.85;
    final cy = size.height / 2;
    final maxR = size.height * 1.1;

    for (int i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final r = t * maxR;
      final opacity = (1 - t) * 0.18;
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()..color = Colors.white.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }

    final sweepAngle = progress * 2 * math.pi;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + math.cos(sweepAngle) * maxR * 0.6, cy + math.sin(sweepAngle) * maxR * 0.6),
      Paint()..color = Colors.white.withValues(alpha: 0.12)..strokeWidth = 1.5..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarMiniPainter old) => old.progress != progress;
}