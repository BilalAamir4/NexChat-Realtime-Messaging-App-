import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/chat/providers/chat_provider.dart';
import '../core/models/user_model.dart';

// ── Radar user — UserModel + radar position ───────────────────────────────────
class _RadarUser {
  final UserModel user;
  final double angle;
  final double distance;

  const _RadarUser({
    required this.user,
    required this.angle,
    required this.distance,
  });
}

// ── Radar Screen ──────────────────────────────────────────────────────────────
class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen>
    with TickerProviderStateMixin {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const _indigo      = Color(0xFF4F46E5);
  static const _violet      = Color(0xFF7C3AED);
  static const _indigo100   = Color(0xFFE0E7FF);
  static const _indigo200   = Color(0xFFC7D2FE);
  static const _cardSurface = Color(0xFFF7F8FF);
  static const _slateDark   = Color(0xFF1E1B4B);
  static const _slateMuted  = Color(0xFF94A3B8);

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _sweepCtrl;
  late final AnimationController _pulseCtrl;

  // ── State ──────────────────────────────────────────────────────────────────
  List<_RadarUser> _allUsers     = [];
  List<_RadarUser> _visibleUsers = [];
  List<UserModel>  _searchResults = [];
  _RadarUser?      _selectedRadar;
  bool _loading   = true;
  bool _searching = false;

  final _searchCtrl      = TextEditingController();
  final _sheetController = DraggableScrollableController();

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  // collapsed snap — just the handle; expanded snap — half screen
  static const double _collapsedSize = 0.08;
  static const double _expandedSize  = 0.55;

  @override
  void initState() {
    super.initState();

    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fetchAllUsers();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ── Fetch all users — reveal dots immediately ─────────────────────────────
  Future<void> _fetchAllUsers() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    final rand = math.Random(DateTime.now().millisecondsSinceEpoch);

    final users = snap.docs
        .where((doc) => doc.id != _myUid)
        .map((doc) => _RadarUser(
      user:     UserModel.fromMap(doc.data()),
      angle:    rand.nextDouble() * 2 * math.pi,
      distance: 0.25 + rand.nextDouble() * 0.55,
    ))
        .toList();

    if (mounted) {
      setState(() {
        _allUsers      = users;
        _visibleUsers  = List.from(users); // ✅ show all dots immediately
        _loading       = false;
      });
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────
  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);

    final q    = query.trim().toLowerCase();
    final qCap = query.trim()[0].toUpperCase() + query.trim().substring(1);

    final byUsername = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: q)
        .get();

    final byName = await FirebaseFirestore.instance
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query.trim())
        .where('displayName', isLessThanOrEqualTo: '${query.trim()}\uf8ff')
        .get();

    final byNameCap = await FirebaseFirestore.instance
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: qCap)
        .where('displayName', isLessThanOrEqualTo: '$qCap\uf8ff')
        .get();

    final seen   = <String>{};
    final merged = <UserModel>[];
    for (final doc in [...byUsername.docs, ...byName.docs, ...byNameCap.docs]) {
      if (doc.id == _myUid || seen.contains(doc.id)) continue;
      seen.add(doc.id);
      merged.add(UserModel.fromMap(doc.data()));
    }

    if (mounted) {
      setState(() {
        _searchResults = merged;
        _searching     = false;
        _selectedRadar = null;
      });

      // Expand sheet when results arrive
      if (merged.isNotEmpty) {
        _sheetController.animateTo(
          _expandedSize,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    }
  }

  // ── Start chat ────────────────────────────────────────────────────────────
  Future<void> _startChat(UserModel user) async {
    final chatId = await ref
        .read(chatServiceProvider)
        .getOrCreateDirectChat(user.uid);
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pushNamed(context, '/chat-room', arguments: {
      'chatId':          chatId,
      'otherUserName':   user.displayName,
      'otherUserAvatar': user.photoUrl,
    });
  }

  // ── Dot offset ────────────────────────────────────────────────────────────
  Offset _dotOffset(_RadarUser ru, double radarRadius) => Offset(
    math.cos(ru.angle) * ru.distance * radarRadius,
    math.sin(ru.angle) * ru.distance * radarRadius,
  );

  // ── Radar dot widget ──────────────────────────────────────────────────────
  Widget _buildUserDot(_RadarUser ru, Offset center, double radarRadius) {
    final offset     = _dotOffset(ru, radarRadius);
    final isSelected = _selectedRadar?.user.uid == ru.user.uid;

    return Positioned(
      left: center.dx + offset.dx - 22,
      top:  center.dy + offset.dy - 22,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRadar = isSelected ? null : ru;
          _searchCtrl.clear();
          _searchResults = [];
          // Collapse sheet when tapping dot
          _sheetController.animateTo(
            _collapsedSize,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeIn,
          );
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width:  isSelected ? 52 : 44,
          height: isSelected ? 52 : 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_indigo, _violet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isSelected ? Colors.white : _indigo200,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _indigo.withValues(alpha: isSelected ? 0.65 : 0.3),
                blurRadius: isSelected ? 20 : 8,
                spreadRadius: isSelected ? 3 : 0,
              ),
            ],
          ),
          child: ru.user.photoUrl.isNotEmpty
              ? ClipOval(
            child: Image.network(ru.user.photoUrl, fit: BoxFit.cover),
          )
              : Center(
            child: Text(
              ru.user.displayName.isNotEmpty
                  ? ru.user.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Compact floating profile card (shown above search bar when dot tapped) ─
  Widget _buildFloatingCard(UserModel user) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 80, // sits just above the search bar
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _cardSurface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _indigo200, width: 1),
            boxShadow: [
              BoxShadow(
                color: _indigo.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_indigo, _violet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: _indigo200, width: 1.5),
                ),
                child: user.photoUrl.isNotEmpty
                    ? ClipOval(
                  child: Image.network(user.photoUrl, fit: BoxFit.cover),
                )
                    : Center(
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: _slateDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        color: _slateMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Dismiss button
              GestureDetector(
                onTap: () => setState(() => _selectedRadar = null),
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _indigo100,
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: _indigo),
                ),
              ),

              // Chat button
              GestureDetector(
                onTap: () => _startChat(user),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_indigo, _violet],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _violet.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Draggable bottom sheet content ────────────────────────────────────────
  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _collapsedSize,
      minChildSize: _collapsedSize,
      maxChildSize: _expandedSize,
      snap: true,
      snapSizes: const [_collapsedSize, _expandedSize],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13103A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: _indigo200.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // ── Handle + search bar ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _indigo200.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // Search bar row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              cursorColor: _indigo200,
                              onChanged: (val) {
                                if (_selectedRadar != null) {
                                  setState(() => _selectedRadar = null);
                                }
                              },
                              onSubmitted: _search,
                              decoration: InputDecoration(
                                hintText: 'Search by name or @username...',
                                hintStyle: TextStyle(
                                  color: _indigo200.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: _indigo.withValues(alpha: 0.15),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: _indigo200.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: _indigo200.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: _indigo200.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: _indigo,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _searching
                                ? null
                                : () => _search(_searchCtrl.text),
                            child: Container(
                              width: 44,
                              height: 44,
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
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _searching
                                  ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Results header / empty state
                    if (_searchResults.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: _indigo200.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchResults = [];
                                  _searchCtrl.clear();
                                });
                                _sheetController.animateTo(
                                  _collapsedSize,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeIn,
                                );
                              },
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  color: _indigo200.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_searchResults.isEmpty && !_searching)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _loading
                              ? 'Scanning...'
                              : 'Pull up to search',
                          style: TextStyle(
                            color: _indigo200.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Results list ─────────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final user = _searchResults[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _indigo200.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [_indigo, _violet],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: _indigo200.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: user.photoUrl.isNotEmpty
                                  ? ClipOval(
                                child: Image.network(
                                  user.photoUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Center(
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '@${user.username}',
                                    style: TextStyle(
                                      color: _indigo200.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            GestureDetector(
                              onTap: () => _startChat(user),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_indigo, _violet],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _violet.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Chat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _searchResults.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final radarR  = size.width * 0.38;
    final center  = Offset(size.width / 2, size.height * 0.46);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B2A),
      body: Stack(
        children: [

          // ── Background gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF080720),
                  Color(0xFF1E1B4B),
                  Color(0xFF2D1B69),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── Radar canvas ─────────────────────────────────────────────────
          Positioned(
            left:   center.dx - radarR,
            top:    center.dy - radarR,
            width:  radarR * 2,
            height: radarR * 2,
            child: AnimatedBuilder(
              animation: Listenable.merge([_sweepCtrl, _pulseCtrl]),
              builder: (_, __) => CustomPaint(
                painter: _RadarPainter(
                  sweep:  _sweepCtrl.value,
                  pulse:  _pulseCtrl.value,
                  radius: radarR,
                ),
              ),
            ),
          ),

          // ── User dots ────────────────────────────────────────────────────
          ..._visibleUsers.map(
                (ru) => _buildUserDot(ru, center, radarR),
          ),

          // ── Draggable bottom sheet ────────────────────────────────────────
          _buildBottomSheet(),

          // ── Floating profile card (above sheet handle) ────────────────────
          if (_selectedRadar != null)
            _buildFloatingCard(_selectedRadar!.user),

          // ── AppBar ────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _indigo200,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Discover People',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _indigo.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _indigo200.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _loading ? '...' : '${_allUsers.length} users',
                      style: const TextStyle(
                        color: _indigo200,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Radar Painter ─────────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double sweep;
  final double pulse;
  final double radius;

  const _RadarPainter({
    required this.sweep,
    required this.pulse,
    required this.radius,
  });

  static const _indigo    = Color(0xFF4F46E5);
  static const _violet    = Color(0xFF7C3AED);
  static const _indigo200 = Color(0xFFC7D2FE);

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final center = Offset(cx, cy);

    // Grid rings
    for (int i = 1; i <= 4; i++) {
      final r = radius * i / 4;
      final pulseBump = i == 2
          ? math.sin(pulse * 2 * math.pi) * 1.5
          : 0.0;
      canvas.drawCircle(
        center,
        r + pulseBump,
        Paint()
          ..color = _indigo200.withValues(
            alpha: 0.12 + (i == 1 ? 0.04 : 0),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 1 ? 0.8 : 0.5,
      );
    }

    // Cross hairs
    final crossPaint = Paint()
      ..color = _indigo200.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(cx - radius, cy), Offset(cx + radius, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - radius), Offset(cx, cy + radius), crossPaint);

    // Sweep gradient fill + line — rotate canvas so gradient tail always
    // trails behind the sweep line with no angular reset artefact.
    final sweepAngle = sweep * 2 * math.pi - math.pi / 2;
    const trailAngle = 1.2; // radians of visible trail

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(sweepAngle); // align canvas so "right" = sweep line direction

    // Draw gradient in local space: trail goes from -trailAngle to 0 (right)
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = SweepGradient(
          startAngle: -trailAngle,
          endAngle:   0,
          colors: [
            Colors.transparent,
            _indigo.withValues(alpha: 0.0),
            _indigo.withValues(alpha: 0.18),
            _violet.withValues(alpha: 0.35),
          ],
          stops: const [0.0, 0.5, 0.85, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset.zero, radius: radius),
        ),
    );

    // Sweep line in local space always points right (angle 0)
    canvas.drawLine(
      Offset.zero,
      Offset(radius, 0),
      Paint()
        ..color = _indigo200.withValues(alpha: 0.55)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // Center dot
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..shader = const LinearGradient(
          colors: [_indigo, _violet],
        ).createShader(Rect.fromCircle(center: center, radius: 5)),
    );
    canvas.drawCircle(center, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.sweep != sweep || old.pulse != pulse;
}