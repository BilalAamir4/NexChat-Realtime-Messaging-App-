import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_routes.dart';

class GroupInfoScreen extends StatefulWidget {
  final String chatId;

  const GroupInfoScreen({super.key, required this.chatId});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const _indigo      = Color(0xFF4F46E5);
  static const _violet      = Color(0xFF7C3AED);
  static const _indigo100   = Color(0xFFE0E7FF);
  static const _indigo200   = Color(0xFFC7D2FE);
  static const _indigo50    = Color(0xFFEEF2FF);
  static const _cardSurface = Color(0xFFF7F8FF);
  static const _pageDark    = Color(0xFFE8EEFF);
  static const _pageLight   = Color(0xFFF0F4FF);
  static const _slateDark   = Color(0xFF1E1B4B);
  static const _slateMuted  = Color(0xFF94A3B8);

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _leaving = false;
  String _groupName = '';
  List<Map<String, String>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  // ── Load group data ────────────────────────────────────────────────────────
  Future<void> _loadGroupInfo() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      final data = chatDoc.data();
      if (data == null) return;

      final groupName    = data['groupName'] as String? ?? 'Group';
      final participants = List<String>.from(data['participants'] ?? []);

      // Fetch each member's info
      final members = <Map<String, String>>[];
      for (final uid in participants) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          final userData = userDoc.data();
          members.add({
            'uid':   uid,
            'name':  userData?['displayName'] as String? ?? 'Unknown',
            'photo': userData?['photoURL']    as String? ?? '',
          });
        } catch (_) {
          members.add({'uid': uid, 'name': 'Unknown', 'photo': ''});
        }
      }

      if (mounted) {
        setState(() {
          _groupName = groupName;
          _members   = members;
          _loading   = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Leave group ────────────────────────────────────────────────────────────
  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave Group',
          style: TextStyle(
            color: _slateDark,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Are you sure you want to leave "$_groupName"?',
          style: const TextStyle(color: _slateDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _slateMuted)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Leave',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _leaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'participants':           FieldValue.arrayRemove([_myUid]),
        'unreadCount.$_myUid':    FieldValue.delete(),
        'typing.$_myUid':         FieldValue.delete(),
      });

      if (mounted) {
        // Pop all the way back to groups list
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.groups,
              (route) => route.settings.name == AppRoutes.groups || route.isFirst,
        );
      }
    } catch (_) {
      setState(() => _leaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to leave group. Try again.')),
        );
      }
    }
  }

  Future<void> _editGroupName() async {
    final controller = TextEditingController(text: _groupName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Group Name',
          style: TextStyle(
            color: _slateDark,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: TextField(
          controller: controller,
          cursorColor: _indigo,
          autofocus: true,
          style: const TextStyle(color: _slateDark),
          decoration: InputDecoration(
            hintText: 'Group name...',
            hintStyle: const TextStyle(color: _slateMuted),
            filled: true,
            fillColor: _indigo50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _indigo200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _indigo200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _indigo, width: 1.8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _slateMuted)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context, controller.text.trim()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_indigo, _violet]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == _groupName) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({'groupName': newName});

      setState(() => _groupName = newName);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update group name.')),
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
            color: _indigo.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
          : Center(
        child: isGroup
            ? (name != null && name.isNotEmpty
            ? Text(
          name[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w800,
          ),
        )
            : Icon(Icons.group_rounded,
            color: Colors.white, size: radius * 0.8))
            : (name != null && name.isNotEmpty
            ? Text(
          name[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w700,
          ),
        )
            : Icon(Icons.person,
            color: Colors.white, size: radius * 0.8)),
      ),
    );
  }

  // ── Member tile ────────────────────────────────────────────────────────────
  Widget _buildMemberTile(Map<String, String> member) {
    final isMe = member['uid'] == _myUid;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _indigo200, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F4F46E5),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(
            radius: 22,
            photoUrl: member['photo'],
            name: member['name'],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? '${member['name']} (You)' : member['name'] ?? 'Unknown',
              style: const TextStyle(
                color: _slateDark,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _indigo100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _indigo200, width: 0.8),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  color: _indigo,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _indigo))
              : Column(
            children: [
              // ── AppBar ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: _pageLight,
                  border: Border(
                    bottom: BorderSide(color: _indigo200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _indigo,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Group Info',
                        style: TextStyle(
                          color: _slateDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                  children: [
                    // ── Group avatar + name ────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          _buildAvatar(
                            radius: 46,
                            name: _groupName,
                            isGroup: true,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _groupName,
                                style: const TextStyle(
                                  color: _slateDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _editGroupName,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _indigo100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _indigo200, width: 1),
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: _indigo, size: 15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_indigo, _violet],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_members.length} member${_members.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Members label ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _indigo100,
                              borderRadius: BorderRadius.circular(8),
                              border:
                              Border.all(color: _indigo200, width: 1),
                            ),
                            child: const Icon(Icons.people_rounded,
                                color: _indigo, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Members',
                            style: TextStyle(
                              color: _slateDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Members list ───────────────────────────────────
                    ..._members.map(_buildMemberTile),

                    const SizedBox(height: 32),

                    // ── Leave group button ─────────────────────────────
                    GestureDetector(
                      onTap: _leaving ? null : _leaveGroup,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFCA5A5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _leaving
                              ? const CircularProgressIndicator(
                            color: Color(0xFFEF4444),
                            strokeWidth: 2,
                          )
                              : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.exit_to_app_rounded,
                                color: Color(0xFFEF4444),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Leave Group',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}