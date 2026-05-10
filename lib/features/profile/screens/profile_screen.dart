import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/edit_profile_sheet.dart';
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
  List<DeviceInfo> _devices = [];
  bool _loadingDevices = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingUser = false);
      return;
    }

    final results = await Future.wait([
      FirebaseFirestore.instance.collection('users').doc(uid).get(),
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('devices')
          .orderBy('lastActive', descending: true)
          .get(),
    ]);

    if (!mounted) return;

    final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final devicesSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;

    setState(() {
      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data()!);
      }
      _devices = devicesSnap.docs
          .map((d) => DeviceInfo.fromMap(d.data()))
          .toList();
      _loadingUser = false;
      _loadingDevices = false;
    });
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
    }
    return count.toString();
  }

  String _formatLastActive(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Last active: just now';
    if (diff.inMinutes < 60) return 'Last active: ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last active: ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Last active: yesterday';
    return 'Last active: ${diff.inDays}d ago';
  }

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'tablet':
        return Icons.tablet_android_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'desktop':
        return Icons.desktop_windows_rounded;
      default:
        return Icons.smartphone_rounded;
    }
  }

  // ─── Open edit sheet ─────────────────────────────────────────────────────

  Future<void> _openEditSheet() async {
    if (_user == null) return;
    final updated = await showEditProfileSheet(context, _user!);
    if (updated != null && mounted) {
      setState(() => _user = updated);
    }
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: NexColors.indigo,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: context.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title,
      {String? action, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action,
                  style: const TextStyle(
                      color: NexColors.indigo,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _pillButton(
      {required IconData icon,
        required String label,
        bool filled = false,
        VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
              colors: [NexColors.indigo, NexColors.violet],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight)
              : null,
          color: filled ? null : context.cardSurface,
          borderRadius: BorderRadius.circular(30),
          border: filled
              ? null
              : Border.all(color: context.cardBorder, width: 1),
          boxShadow: filled
              ? [
            BoxShadow(
                color: NexColors.violet.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]
              : [
            BoxShadow(
                color: NexColors.indigo.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: filled ? Colors.white : NexColors.indigo),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: filled ? Colors.white : NexColors.indigo,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(DeviceInfo device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.receivedBubbleBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorder, width: 1),
            ),
            child:
            Icon(_deviceIcon(device.type), color: NexColors.indigo, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name,
                    style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(_formatLastActive(device.lastActive),
                    style: TextStyle(color: context.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: device.isCurrentDevice
                  ? NexColors.indigo.withValues(alpha: 0.12)
                  : context.receivedBubbleBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: device.isCurrentDevice
                      ? NexColors.indigo.withValues(alpha: 0.3)
                      : context.cardBorder,
                  width: 0.8),
            ),
            child: Text(
              device.isCurrentDevice ? 'This device' : 'Active',
              style: const TextStyle(
                  color: NexColors.indigo,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaTile(int index, String? url) {
    final gradients = [
      [NexColors.indigo, NexColors.violet],
      [NexColors.violet, const Color(0xFFEC4899)],
      [const Color(0xFF0EA5E9), NexColors.indigo],
      [NexColors.indigo, const Color(0xFF06B6D4)],
      [NexColors.violet, NexColors.indigo],
      [const Color(0xFF6366F1), NexColors.violet],
      [NexColors.indigo, const Color(0xFF8B5CF6)],
      [NexColors.violet, const Color(0xFF3B82F6)],
    ];

    final decoration = BoxDecoration(
      gradient: url == null
          ? LinearGradient(
          colors: gradients[index % gradients.length],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight)
          : null,
      color: url != null ? context.cardSurface : null,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.cardBorder, width: 1),
      boxShadow: [
        BoxShadow(
            color: NexColors.indigo.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3))
      ],
    );

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 10),
      decoration: decoration,
      child: url != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(url,
            width: 80,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 26),
            )),
      )
          : Center(
        child: Icon(
          index % 3 == 0
              ? Icons.image_outlined
              : index % 3 == 1
              ? Icons.videocam_outlined
              : Icons.mic_outlined,
          color: Colors.white.withValues(alpha: 0.75),
          size: 26,
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasMedia = (_user?.mediaUrls.isNotEmpty ?? false);
    final mediaTileCount = hasMedia ? _user!.mediaUrls.length : 8;

    return Scaffold(
      backgroundColor:
      context.isDark ? NexColors.darkPage : NexColors.lightPageDark,
      body: Container(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: context.isDark
                  ? NexColors.darkCard
                  : NexColors.lightPageLight,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: NexColors.indigo, size: 20),
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
                    // Gradient banner
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
                          Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white
                                          .withValues(alpha: 0.06)))),
                          Positioned(
                              bottom: -20,
                              left: 40,
                              child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white
                                          .withValues(alpha: 0.05)))),
                        ],
                      ),
                    ),
                    // Avatar — tappable with camera badge
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _openEditSheet,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Avatar circle
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient:
                                    (_user?.photoUrl.isNotEmpty ?? false)
                                        ? null
                                        : const LinearGradient(
                                        colors: [
                                          NexColors.indigo,
                                          NexColors.violet
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight),
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                          color: NexColors.indigo
                                              .withValues(alpha: 0.35),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6))
                                    ],
                                  ),
                                  child: (_user?.photoUrl.isNotEmpty ?? false)
                                      ? ClipOval(
                                      child: Image.network(
                                          _user!.photoUrl,
                                          width: 88,
                                          height: 88,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person,
                                              color: Colors.white,
                                              size: 44)))
                                      : const Icon(Icons.person,
                                      color: Colors.white, size: 44),
                                ),
                                // Camera badge
                                Positioned(
                                  bottom: 0,
                                  right: -2,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [
                                            NexColors.indigo,
                                            NexColors.violet
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                            color: NexColors.indigo
                                                .withValues(alpha: 0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 14),

                  // Name / username / online badge
                  if (_loadingUser)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: NexColors.indigo),
                    )
                  else ...[
                    Text(_user?.displayName ?? 'Unknown',
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(_user != null ? '@${_user!.username}' : '',
                        style: TextStyle(
                            color: context.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.receivedBubbleBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: context.cardBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: (_user?.isOnline ?? false)
                                      ? const Color(0xFF22C55E)
                                      : context.textMuted,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                              (_user?.isOnline ?? false) ? 'Online' : 'Offline',
                              style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _pillButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Message',
                          filled: true,
                          onTap: () =>
                              Navigator.pushNamed(context, '/chat')),
                      const SizedBox(width: 10),
                      _pillButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: _openEditSheet,
                      ),
                      const SizedBox(width: 10),
                      _pillButton(
                          icon: Icons.share_outlined, label: 'Share'),
                    ],
                  ),

                  // ── ABOUT ────────────────────────────────────────────
                  _sectionHeader('ABOUT'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: context.cardBorder, width: 1),
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
                          Container(
                            width: 3,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    NexColors.indigo,
                                    NexColors.violet
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _loadingUser
                                ? const SizedBox(
                              height: 60,
                              child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: NexColors.indigo),
                              ),
                            )
                                : Text(
                              _user?.bio.isNotEmpty == true
                                  ? _user!.bio
                                  : 'No bio yet.',
                              style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 13.5,
                                  height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── PINNED ───────────────────────────────────────────
                  if (!_loadingUser &&
                      (_user?.pinnedQuote.isNotEmpty ?? false)) ...[
                    _sectionHeader('PINNED'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: context.cardBorder, width: 1),
                          boxShadow: [
                            BoxShadow(
                                color:
                                NexColors.violet.withValues(alpha: 0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 6))
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
                                    colors: [
                                      NexColors.indigo,
                                      NexColors.violet
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.format_quote_rounded,
                                  color: Colors.white,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _user!.pinnedQuote,
                                style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 13.5,
                                    fontStyle: FontStyle.italic,
                                    height: 1.55,
                                    letterSpacing: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── STATS ────────────────────────────────────────────
                  _sectionHeader('STATS'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _loadingUser
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: NexColors.indigo),
                      ),
                    )
                        : Row(
                      children: [
                        _statCard(
                            _formatCount(_user?.messageCount ?? 0),
                            'Messages'),
                        const SizedBox(width: 10),
                        _statCard(
                            _formatCount(_user?.groupCount ?? 0),
                            'Groups'),
                        const SizedBox(width: 10),
                        _statCard(
                            _formatCount(_user?.friendCount ?? 0),
                            'Friends'),
                      ],
                    ),
                  ),

                  // ── MEDIA ────────────────────────────────────────────
                  _sectionHeader('MEDIA', action: 'See all'),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: mediaTileCount,
                      itemBuilder: (context, index) {
                        final url = hasMedia &&
                            index < _user!.mediaUrls.length
                            ? _user!.mediaUrls[index]
                            : null;
                        return _mediaTile(index, url);
                      },
                    ),
                  ),

                  // ── ACTIVE DEVICES ────────────────────────────────────
                  _sectionHeader('ACTIVE DEVICES'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _loadingDevices
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: NexColors.indigo),
                      ),
                    )
                        : _devices.isEmpty
                        ? Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No active devices found.',
                          style: TextStyle(
                              color: context.textMuted,
                              fontSize: 13)),
                    )
                        : Column(
                      children: _devices
                          .map((d) => _deviceCard(d))
                          .toList(),
                    ),
                  ),

                  // ── LOGOUT ───────────────────────────────────────────
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: _isLoggingOut ? null : _handleLogout,
                      child: Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? const Color(0xFF2A1515)
                              : context.cardSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                              Colors.redAccent.withValues(alpha: 0.35),
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.redAccent
                                    .withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoggingOut)
                              const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.redAccent))
                            else
                              const Icon(Icons.logout_rounded,
                                  color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                                _isLoggingOut
                                    ? 'Logging out...'
                                    : 'Logout',
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
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