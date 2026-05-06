import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;
  UserModel? _user;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loadingUser = false); return; }
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted && doc.exists) {
      setState(() { _user = UserModel.fromMap(doc.data()!); _loadingUser = false; });
    } else {
      setState(() => _loadingUser = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(color: context.cardBorder, width: 1),
          boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(color: NexColors.indigo, fontSize: 22,
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(color: context.textSecondary, fontSize: 13,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          if (action != null)
            Text(action, style: const TextStyle(color: NexColors.indigo, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _pillButton({required IconData icon, required String label, bool filled = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
              begin: Alignment.centerLeft, end: Alignment.centerRight)
              : null,
          color: filled ? null : context.cardSurface,
          borderRadius: BorderRadius.circular(30),
          border: filled ? null : Border.all(color: context.cardBorder, width: 1),
          boxShadow: filled
              ? [BoxShadow(color: NexColors.violet.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : NexColors.indigo),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(color: filled ? Colors.white : NexColors.indigo,
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(IconData icon, String name, String lastActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: context.cardBorder, width: 1),
        boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: context.receivedBubbleBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorder, width: 1),
            ),
            child: Icon(icon, color: NexColors.indigo, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(lastActive, style: TextStyle(color: context.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.receivedBubbleBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.cardBorder, width: 0.8),
            ),
            child: const Text('Active',
                style: TextStyle(color: NexColors.indigo, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? NexColors.darkPage : NexColors.lightPageDark,
      body: Container(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: context.isDark ? NexColors.darkCard : NexColors.lightPageLight,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: NexColors.indigo, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.more_vert, color: context.textPrimary),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient banner — theme-invariant
                    Container(
                      height: 170,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [NexColors.indigo, NexColors.violet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(top: -30, right: -30,
                              child: Container(width: 130, height: 130,
                                  decoration: BoxDecoration(shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.06)))),
                          Positioned(bottom: -20, left: 40,
                              child: Container(width: 80, height: 80,
                                  decoration: BoxDecoration(shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.05)))),
                        ],
                      ),
                    ),
                    // Avatar
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 88, height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))],
                            ),
                            child: (_user?.photoUrl.isNotEmpty ?? false)
                                ? ClipOval(child: Image.network(_user!.photoUrl, width: 88, height: 88, fit: BoxFit.cover))
                                : const Icon(Icons.person, color: Colors.white, size: 44),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 14),

                  if (_loadingUser)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: NexColors.indigo),
                    )
                  else ...[
                    Text(_user?.displayName ?? 'Unknown',
                        style: TextStyle(color: context.textPrimary, fontSize: 24,
                            fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(_user != null ? '@${_user!.username}' : '',
                        style: TextStyle(color: context.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.receivedBubbleBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.cardBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 7, height: 7,
                              decoration: BoxDecoration(
                                  color: (_user?.isOnline ?? false) ? const Color(0xFF22C55E) : context.textMuted,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text((_user?.isOnline ?? false) ? 'Online' : 'Offline',
                              style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _pillButton(icon: Icons.chat_bubble_outline_rounded, label: 'Message',
                          filled: true, onTap: () => Navigator.pushNamed(context, '/chat')),
                      const SizedBox(width: 10),
                      _pillButton(icon: Icons.edit_outlined, label: 'Edit'),
                      const SizedBox(width: 10),
                      _pillButton(icon: Icons.share_outlined, label: 'Share'),
                    ],
                  ),

                  _sectionHeader('ABOUT'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.cardBorder, width: 1),
                        boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3, height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Flutter dev by day, dark mode enjoyer by night. Building NexChat — because every chat app deserves a little more personality.',
                              style: TextStyle(color: context.textSecondary, fontSize: 13.5, height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _sectionHeader('PINNED'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.cardBorder, width: 1),
                        boxShadow: [BoxShadow(color: NexColors.violet.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [NexColors.indigo, NexColors.violet],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.format_quote_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '"Code is like humor. When you have to explain it, it\'s bad."',
                              style: TextStyle(color: context.textPrimary, fontSize: 13.5,
                                  fontStyle: FontStyle.italic, height: 1.55, letterSpacing: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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

                  _sectionHeader('MEDIA', action: 'See all'),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final colors = [
                          [NexColors.indigo, NexColors.violet],
                          [NexColors.violet, const Color(0xFFEC4899)],
                          [const Color(0xFF0EA5E9), NexColors.indigo],
                          [NexColors.indigo, const Color(0xFF06B6D4)],
                          [NexColors.violet, NexColors.indigo],
                          [const Color(0xFF6366F1), NexColors.violet],
                          [NexColors.indigo, const Color(0xFF8B5CF6)],
                          [NexColors.violet, const Color(0xFF3B82F6)],
                        ];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors[index % colors.length],
                                begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.cardBorder, width: 1),
                            boxShadow: [BoxShadow(color: NexColors.indigo.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Center(
                            child: Icon(
                              index % 3 == 0 ? Icons.image_outlined
                                  : index % 3 == 1 ? Icons.videocam_outlined : Icons.mic_outlined,
                              color: Colors.white.withValues(alpha: 0.75), size: 26,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  _sectionHeader('ACTIVE DEVICES'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _deviceCard(Icons.smartphone_rounded, 'iPhone 14 Pro', 'Last active: just now'),
                        _deviceCard(Icons.laptop_rounded, 'MacBook Pro', 'Last active: 2 hours ago'),
                        _deviceCard(Icons.tablet_android_rounded, 'iPad Air', 'Last active: yesterday'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: _isLoggingOut ? null : _handleLogout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: context.isDark ? const Color(0xFF2A1515) : context.cardSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35), width: 1),
                          boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoggingOut)
                              const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                            else
                              const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(_isLoggingOut ? 'Logging out...' : 'Logout',
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 14)),
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