import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/chat/providers/chat_provider.dart';
import '../routes/app_routes.dart';

// ── Helper: fetch users from existing chats ───────────────────────────────────

Future<List<Map<String, String>>> fetchChattedUsers() async {
  final myUid = FirebaseAuth.instance.currentUser!.uid;
  final firestore = FirebaseFirestore.instance;

  // Get all chats the current user is in
  final chatsSnap = await firestore
      .collection('chats')
      .where('participants', arrayContains: myUid)
      .get();

  // Collect unique UIDs that aren't the current user
  final uids = <String>{};
  for (final doc in chatsSnap.docs) {
    final participants = List<String>.from(doc.data()['participants'] ?? []);
    for (final uid in participants) {
      if (uid != myUid) uids.add(uid);
    }
  }

  // Fetch user info for each UID
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

// ── Entry point: show the bottom sheet ───────────────────────────────────────

void showCreateGroupSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CreateGroupSheet(),
  );
}

// ── Sheet widget ─────────────────────────────────────────────────────────────

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const _indigo      = Color(0xFF4F46E5);
  static const _violet      = Color(0xFF7C3AED);
  static const _indigo100   = Color(0xFFE0E7FF);
  static const _indigo200   = Color(0xFFC7D2FE);
  static const _cardSurface = Color(0xFFF7F8FF);
  static const _pageLight   = Color(0xFFF0F4FF);
  static const _slateDark   = Color(0xFF1E1B4B);
  static const _slateMid    = Color(0xFF475569);
  static const _slateMuted  = Color(0xFF94A3B8);

  // ── State ──────────────────────────────────────────────────────────────────
  int _step = 1; // 1 = pick participants, 2 = group details
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

  // ── Create group ───────────────────────────────────────────────────────────
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
        Navigator.pop(context); // close sheet
        Navigator.pushNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId':          chatId,
            'otherUserName':   name,
            'otherUserAvatar': '',
          },
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create group. Try again.')),
        );
      }
    }
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar({
    required double radius,
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
            color: _indigo.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
          : Center(
        child: isGroup
            ? Icon(Icons.group_rounded, color: Colors.white, size: radius * 0.85)
            : name != null && name.isNotEmpty
            ? Text(
          name[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w700,
          ),
        )
            : Icon(Icons.person, color: Colors.white, size: radius * 0.85),
      ),
    );
  }

  // ── Step 1: Participant picker ─────────────────────────────────────────────
  Widget _buildStep1(ScrollController scrollController) {
    return Column(
      children: [
        // ── Handle + header ────────────────────────────────────────────────
        const SizedBox(height: 12),
        Container(
          width: 44, height: 4,
          decoration: BoxDecoration(
            color: _indigo200,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_indigo, _violet]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'New Group',
                style: TextStyle(
                  color: _slateDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Step 1 of 2',
                style: TextStyle(color: _slateMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Select participants to add to the group',
            style: TextStyle(color: _slateMuted, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),

        // ── Selected chips ─────────────────────────────────────────────────
        if (_selectedUids.isNotEmpty) ...[
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _selectedUids.map((uid) {
                final user = _users.firstWhere(
                      (u) => u['uid'] == uid,
                  orElse: () => {'uid': uid, 'name': '?', 'photo': ''},
                );
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_indigo, _violet],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _indigo.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user['name'] ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
          Divider(color: _indigo200.withValues(alpha: 0.5), height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
        ],

        // ── User list ──────────────────────────────────────────────────────
        Expanded(
          child: _loadingUsers
              ? const Center(child: CircularProgressIndicator(color: _indigo))
              : _users.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 48, color: _indigo200),
                const SizedBox(height: 12),
                const Text(
                  'No contacts yet',
                  style: TextStyle(color: _slateDark, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Start a 1-on-1 chat first',
                  style: TextStyle(color: _slateMuted, fontSize: 13),
                ),
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
                  if (isSelected) {
                    _selectedUids.remove(uid);
                  } else {
                    _selectedUids.add(uid);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                      colors: [_indigo, _violet],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                        : null,
                    color: isSelected ? null : _cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _violet : _indigo200,
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? _indigo.withValues(alpha: 0.25)
                            : const Color(0x0F4F46E5),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildAvatar(radius: 22, photoUrl: photo, name: name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : _slateDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? Colors.white : _indigo200,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: _indigo, size: 14)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Next button ────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
          child: GestureDetector(
            onTap: _selectedUids.isEmpty ? null : () => setState(() => _step = 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: _selectedUids.isNotEmpty
                    ? const LinearGradient(
                  colors: [_indigo, _violet],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : null,
                color: _selectedUids.isEmpty ? _indigo100 : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedUids.isNotEmpty
                    ? [
                  BoxShadow(
                    color: _violet.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedUids.isEmpty
                        ? 'Select at least 1 person'
                        : 'Next  (${_selectedUids.length} selected)',
                    style: TextStyle(
                      color: _selectedUids.isEmpty ? _slateMuted : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
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

  // ── Step 2: Group details ──────────────────────────────────────────────────
  Widget _buildStep2() {
    final groupName = _groupNameController.text.trim();
    final initial   = groupName.isNotEmpty ? groupName[0].toUpperCase() : null;

    return Column(
      children: [
        // ── Handle + header ────────────────────────────────────────────────
        const SizedBox(height: 12),
        Container(
          width: 44, height: 4,
          decoration: BoxDecoration(
            color: _indigo200,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
                    color: _indigo100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _indigo200),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: _indigo, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Group Details',
                style: TextStyle(
                  color: _slateDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Step 2 of 2',
                style: TextStyle(color: _slateMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Group avatar placeholder ───────────────────────────────────────
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_indigo, _violet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _indigo200, width: 3),
            boxShadow: [
              BoxShadow(
                color: _indigo.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: initial != null
                ? Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            )
                : const Icon(Icons.group_rounded, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Avatar coming soon',
          style: TextStyle(color: _slateMuted, fontSize: 12),
        ),
        const SizedBox(height: 28),

        // ── Selected members preview ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '${_selectedUids.length} member${_selectedUids.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: _slateMid,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _step = 1),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: _indigo,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Members row
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _selectedUids.map((uid) {
              final user = _users.firstWhere(
                    (u) => u['uid'] == uid,
                orElse: () => {'uid': uid, 'name': '?', 'photo': ''},
              );
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  children: [
                    _buildAvatar(radius: 18, photoUrl: user['photo'], name: user['name']),
                    const SizedBox(height: 3),
                    Text(
                      (user['name'] ?? '?').split(' ').first,
                      style: const TextStyle(color: _slateMuted, fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // ── Group name field ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _groupNameController,
            cursorColor: _indigo,
            onChanged: (_) => setState(() {}), // rebuild for initial letter
            style: const TextStyle(color: _slateDark, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Group name...',
              hintStyle: const TextStyle(color: _slateMuted),
              prefixIcon: const Icon(Icons.edit_rounded, color: _indigo, size: 20),
              filled: true,
              fillColor: _cardSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _indigo200, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _indigo200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _indigo, width: 1.8),
              ),
            ),
          ),
        ),
        const Spacer(),

        // ── Create button ──────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
          child: GestureDetector(
            onTap: (!_isCreating && groupName.isNotEmpty) ? _createGroup : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: groupName.isNotEmpty
                    ? const LinearGradient(
                  colors: [_indigo, _violet],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : null,
                color: groupName.isEmpty ? _indigo100 : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: groupName.isNotEmpty
                    ? [
                  BoxShadow(
                    color: _violet.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: Center(
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                  groupName.isEmpty ? 'Enter a group name' : 'Create Group',
                  style: TextStyle(
                    color: groupName.isEmpty ? _slateMuted : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize:     0.95,
      minChildSize:     0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF0F4FF), Color(0xFFF7F8FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
            child: _step == 1
                ? KeyedSubtree(
              key: const ValueKey(1),
              child: _buildStep1(scrollController),
            )
                : KeyedSubtree(
              key: const ValueKey(2),
              child: _buildStep2(),
            ),
          ),
        );
      },
    );
  }
}