import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/app_routes.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('notifications');

  Future<void> _markRead(String docId) async {
    await _col.doc(docId).update({'read': true});
  }

  Future<void> _clearAll() async {
    final snap = await _col.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _relativeTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  void _onTap(BuildContext context, Map<String, dynamic> data, String docId) {
    _markRead(docId);
    final chatId = data['chatId'] as String?;
    if (chatId == null || chatId.isEmpty) return;

    FirebaseFirestore.instance.collection('chats').doc(chatId).get().then((snap) {
      if (!snap.exists) return;
      final chatData = snap.data()!;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final participants = List<String>.from(chatData['participants'] ?? []);
      final isGroup = chatData['type'] == 'group';
      final otherUid =
      participants.firstWhere((id) => id != uid, orElse: () => '');

      Navigator.pushNamed(
        context,
        AppRoutes.chatRoom,
        arguments: {
          'chatId': chatId,
          'otherUserId': isGroup ? '' : otherUid,
          'otherUserName': data['senderName'] ?? '',
          'otherUserAvatar': data['senderAvatar'] ?? '',
          'isGroup': isGroup,
          'groupName': chatData['groupName'] as String?,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      context.isDark ? NexColors.darkPage : NexColors.lightPageDark,
      body: Container(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? NexColors.darkCard
                      : NexColors.lightPageLight,
                  border: Border(
                      bottom:
                      BorderSide(color: context.cardBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: context.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
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
                              gradient: LinearGradient(colors: [
                                NexColors.indigo,
                                NexColors.indigo200
                              ]),
                              borderRadius:
                              BorderRadius.all(Radius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          color: NexColors.indigo,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── List ─────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _col
                      .orderBy('createdAt', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: NexColors.indigo));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 56, color: context.cardBorder),
                            const SizedBox(height: 16),
                            Text('No notifications yet',
                                style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text('Messages will show up here',
                                style: TextStyle(
                                    color: context.textMuted, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                      const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final data = doc.data();
                        final isRead = data['read'] as bool? ?? false;
                        final senderName =
                            data['senderName'] as String? ?? 'Someone';
                        final senderAvatar =
                            data['senderAvatar'] as String? ?? '';
                        final body =
                            data['body'] as String? ?? 'New message';
                        final ts = data['createdAt'] as Timestamp?;
                        final isGroup =
                            data['isGroup'] as bool? ?? false;
                        final groupName =
                        data['groupName'] as String?;

                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.white, size: 22),
                          ),
                          onDismissed: (_) => _col.doc(doc.id).delete(),
                          child: GestureDetector(
                            onTap: () => _onTap(context, data, doc.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? context.cardSurface
                                    : context.isDark
                                    ? NexColors.indigo
                                    .withValues(alpha: 0.08)
                                    : NexColors.indigo
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isRead
                                      ? context.cardBorder
                                      : NexColors.indigo
                                      .withValues(alpha: 0.35),
                                  width: isRead ? 1 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: NexColors.indigo
                                        .withValues(alpha: isRead ? 0.04 : 0.10),
                                    blurRadius: 16,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  _NotifAvatar(
                                    photoUrl: senderAvatar,
                                    name: senderName,
                                    isGroup: isGroup,
                                  ),
                                  const SizedBox(width: 12),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                isGroup && groupName != null
                                                    ? groupName
                                                    : senderName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.5,
                                                  color: context.textPrimary,
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              _relativeTime(ts),
                                              style: TextStyle(
                                                color: context.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isGroup && groupName != null) ...[
                                          const SizedBox(height: 1),
                                          Text(
                                            senderName,
                                            style: TextStyle(
                                              color: NexColors.indigo,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 5),
                                        // Message preview bubble
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 11, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: context.receivedBubbleBg,
                                            borderRadius:
                                            const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                              bottomLeft: Radius.circular(4),
                                            ),
                                            border: Border.all(
                                                color:
                                                context.receivedBubbleBorder,
                                                width: 0.8),
                                          ),
                                          child: Text(
                                            body,
                                            style: TextStyle(
                                              color: context.textPrimary,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Unread dot
                                  if (!isRead)
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(left: 8, top: 2),
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              NexColors.indigo,
                                              NexColors.violet
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
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
}

// ── Avatar widget ─────────────────────────────────────────────────────────────
class _NotifAvatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final bool isGroup;

  const _NotifAvatar({
    required this.photoUrl,
    required this.name,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: photoUrl.isEmpty
            ? const LinearGradient(
          colors: [NexColors.indigo, NexColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        border: Border.all(color: context.cardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: NexColors.indigo.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: photoUrl.isNotEmpty
          ? ClipOval(
          child: Image.network(photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(context, radius)))
          : _fallback(context, radius),
    );
  }

  Widget _fallback(BuildContext context, double radius) {
    return Center(
      child: isGroup
          ? Icon(Icons.group_rounded,
          color: Colors.white, size: radius * 0.85)
          : name.isNotEmpty
          ? Text(
        name[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w700,
        ),
      )
          : Icon(Icons.person, color: Colors.white, size: radius * 0.85),
    );
  }
}