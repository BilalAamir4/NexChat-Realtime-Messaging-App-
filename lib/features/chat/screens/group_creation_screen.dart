import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/chat_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

Future<List<Map<String, String>>> fetchChattedUsers() async {
  final myUid = FirebaseAuth.instance.currentUser!.uid;
  final firestore = FirebaseFirestore.instance;

  final chatsSnap = await firestore
      .collection('chats')
      .where('participants', arrayContains: myUid)
      .get();

  final uids = <String>{};
  for (final doc in chatsSnap.docs) {
    final participants = List<String>.from(doc.data()['participants'] ?? []);
    for (final uid in participants) {
      if (uid != myUid) uids.add(uid);
    }
  }

  final users = <Map<String, String>>[];
  for (final uid in uids) {
    try {
      final userDoc = await firestore.collection('users').doc(uid).get();
      final data = userDoc.data();
      if (data != null) {
        users.add({
          'uid':   uid,
          'name':  data['displayName'] as String? ?? 'Unknown',
          'photo': data['photoURL']    as String? ?? '',
        });
      }
    } catch (_) {}
  }

  return users;
}

void showCreateGroupSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CreateGroupSheet(),
  );
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  int _step = 1;
  final Set<String> _selectedUids = {};
  List<Map<String, String>> _users = [];
  bool _loadingUsers = true;

  final _groupNameController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await fetchChattedUsers();
    if (mounted) setState(() { _users = users; _loadingUsers = false; });
  }

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty || _selectedUids.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final chatId = await ref.read(createGroupProvider.notifier).createGroup(
        memberUids: _selectedUids.toList(),
        groupName:  name,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamed(context, AppRoutes.chatRoom, arguments: {
          'chatId':          chatId,
          'otherUserName':   name,
          'otherUserAvatar': '',
        });
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to create group. Try again.')));
      }
    }
  }

  Widget _buildAvatar({required double radius, String? photoUrl, String? name, bool isGroup = false}) {
    return Container(
      width: radius * 2, height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: photoUrl == null || photoUrl.isEmpty
            ? const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
            begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        border: Border.all(color: context.cardBorder, width: 2),
        boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
          : Center(
        child: isGroup
            ? Icon(Icons.group_rounded, color: Colors.white, size: radius * 0.85)
            : name != null && name.isNotEmpty
            ? Text(name[0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontSize: radius * 0.75, fontWeight: FontWeight.w700))
            : Icon(Icons.person, color: Colors.white, size: radius * 0.85),
      ),
    );
  }

  Widget _buildStep1(ScrollController scrollController) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 44, height: 4,
            decoration: BoxDecoration(color: context.cardBorder, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [NexColors.indigo, NexColors.violet]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text('New Group',
                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3)),
              const SizedBox(width: 8),
              Text('Step 1 of 2', style: TextStyle(color: context.textMuted, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Select participants to add to the group',
              style: TextStyle(color: context.textMuted, fontSize: 13)),
        ),
        const SizedBox(height: 16),

        if (_selectedUids.isNotEmpty) ...[
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _selectedUids.map((uid) {
                final user = _users.firstWhere((u) => u['uid'] == uid,
                    orElse: () => {'uid': uid, 'name': '?', 'photo': ''});
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                        begin: Alignment.centerLeft, end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user['name'] ?? '?',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _selectedUids.remove(uid)),
                        child: const Icon(Icons.close, color: Colors.white70, size: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: context.cardBorder.withValues(alpha: 0.5), height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
        ],

        Expanded(
          child: _loadingUsers
              ? const Center(child: CircularProgressIndicator(color: NexColors.indigo))
              : _users.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 48, color: context.cardBorder),
                const SizedBox(height: 12),
                Text('No contacts yet', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Start a 1-on-1 chat first', style: TextStyle(color: context.textMuted, fontSize: 13)),
              ],
            ),
          )
              : ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final uid  = user['uid']!;
              final name = user['name']!;
              final photo = user['photo']!;
              final isSelected = _selectedUids.contains(uid);

              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) _selectedUids.remove(uid); else _selectedUids.add(uid);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                        begin: Alignment.centerLeft, end: Alignment.centerRight)
                        : null,
                    color: isSelected ? null : context.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? NexColors.violet : context.cardBorder,
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? NexColors.indigo.withValues(alpha: 0.25) : NexColors.indigo.withValues(alpha: 0.06),
                        blurRadius: isSelected ? 12 : 8, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildAvatar(radius: 22, photoUrl: photo, name: name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(name,
                            style: TextStyle(
                                color: isSelected ? Colors.white : context.textPrimary,
                                fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : Colors.transparent,
                          border: Border.all(color: isSelected ? Colors.white : context.cardBorder, width: 2),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: NexColors.indigo, size: 14)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
          child: GestureDetector(
            onTap: _selectedUids.isEmpty ? null : () => setState(() => _step = 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                gradient: _selectedUids.isNotEmpty
                    ? const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                    begin: Alignment.centerLeft, end: Alignment.centerRight)
                    : null,
                color: _selectedUids.isEmpty ? context.receivedBubbleBg : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedUids.isNotEmpty
                    ? [BoxShadow(color: NexColors.violet.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedUids.isEmpty ? 'Select at least 1 person' : 'Next  (${_selectedUids.length} selected)',
                    style: TextStyle(
                        color: _selectedUids.isEmpty ? context.textMuted : Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  if (_selectedUids.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final groupName = _groupNameController.text.trim();
    final initial   = groupName.isNotEmpty ? groupName[0].toUpperCase() : null;

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 44, height: 4,
            decoration: BoxDecoration(color: context.cardBorder, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _step = 1),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: context.receivedBubbleBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: NexColors.indigo, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text('Group Details',
                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3)),
              const Spacer(),
              Text('Step 2 of 2', style: TextStyle(color: context.textMuted, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: context.cardBorder, width: 3),
            boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Center(
            child: initial != null
                ? Text(initial, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800))
                : const Icon(Icons.group_rounded, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 8),
        Text('Avatar coming soon', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 28),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('${_selectedUids.length} member${_selectedUids.length == 1 ? '' : 's'}',
                  style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _step = 1),
                child: const Text('Edit', style: TextStyle(color: NexColors.indigo, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _selectedUids.map((uid) {
              final user = _users.firstWhere((u) => u['uid'] == uid,
                  orElse: () => {'uid': uid, 'name': '?', 'photo': ''});
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  children: [
                    _buildAvatar(radius: 18, photoUrl: user['photo'], name: user['name']),
                    const SizedBox(height: 3),
                    Text((user['name'] ?? '?').split(' ').first,
                        style: TextStyle(color: context.textMuted, fontSize: 10)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _groupNameController,
            cursorColor: NexColors.indigo,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: context.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Group name...',
              hintStyle: TextStyle(color: context.textMuted),
              prefixIcon: const Icon(Icons.edit_rounded, color: NexColors.indigo, size: 20),
              filled: true,
              fillColor: context.cardSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.cardBorder, width: 1)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.cardBorder, width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: NexColors.indigo, width: 1.8)),
            ),
          ),
        ),
        const Spacer(),

        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
          child: GestureDetector(
            onTap: (!_isCreating && groupName.isNotEmpty) ? _createGroup : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                gradient: groupName.isNotEmpty
                    ? const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                    begin: Alignment.centerLeft, end: Alignment.centerRight)
                    : null,
                color: groupName.isEmpty ? context.receivedBubbleBg : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: groupName.isNotEmpty
                    ? [BoxShadow(color: NexColors.violet.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                  groupName.isEmpty ? 'Enter a group name' : 'Create Group',
                  style: TextStyle(
                      color: groupName.isEmpty ? context.textMuted : Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
              child: child,
            ),
            child: _step == 1
                ? KeyedSubtree(key: const ValueKey(1), child: _buildStep1(scrollController))
                : KeyedSubtree(key: const ValueKey(2), child: _buildStep2()),
          ),
        );
      },
    );
  }
}