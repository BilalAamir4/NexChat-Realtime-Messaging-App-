import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Call [PresenceService.init] once in [main] (after Firebase.initializeApp).
/// It self-registers as a [WidgetsBindingObserver] so it reacts to
/// foreground / background transitions for the lifetime of the app.
class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService _instance = PresenceService._();
  static PresenceService get instance => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Call once after [Firebase.initializeApp], before [runApp].
  void init() {
    WidgetsBinding.instance.addObserver(this);

    // Mark online when the auth state is first resolved (covers cold-start).
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _setOnline();
      }
    });
  }

  // ── AppLifecycleState ─────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setOffline();
        break;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  Future<void> _setOnline() async {
    try {
      await _userDoc?.set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // ← won't overwrite other fields
    } catch (_) {}
  }

  Future<void> _setOffline() async {
    try {
      await _userDoc?.set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // ← same as _setOnline
    } catch (_) {}
  }

  /// Call from your sign-out flow so the user is marked offline immediately.
  Future<void> signOut() async {
    await _setOffline();
    await _auth.signOut();
  }
}