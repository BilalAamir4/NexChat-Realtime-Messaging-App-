import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService _instance = PresenceService._();
  static PresenceService get instance => _instance;

  final _auth = FirebaseAuth.instance;
  final _rtdb = FirebaseDatabase.instance;

  User? _lastKnownUser;

  void init() {
    WidgetsBinding.instance.addObserver(this);

    _auth.authStateChanges().listen((user) {
      if (user != null && user.uid != _lastKnownUser?.uid) {
        _lastKnownUser = user;
        _setOnline();
      } else if (user == null) {
        _lastKnownUser = null;
      }
    });
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _setOffline();
        break;
      default:
        break;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? get _uid => _auth.currentUser?.uid;

  DatabaseReference? get _rtdbRef {
    final uid = _uid;
    if (uid == null) return null;
    return _rtdb.ref('presence/$uid');
  }

  Future<void> _setOnline() async {
    final rtdbRef = _rtdbRef;
    if (rtdbRef == null) return;

    try {
      // Firebase server will automatically run this if connection drops
      await rtdbRef.onDisconnect().set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });

      await rtdbRef.set({
        'isOnline': true,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('PresenceService._setOnline error: $e');
    }
  }

  Future<void> _setOffline() async {
    final rtdbRef = _rtdbRef;

    try {
      // Cancel the disconnect handler since we're going offline gracefully
      await rtdbRef?.onDisconnect().cancel();

      await rtdbRef?.set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('PresenceService._setOffline error: $e');
    }
  }

  // Call this on logout instead of FirebaseAuth.instance.signOut() directly
  Future<void> signOut() async {
    await _setOffline();
    await _auth.signOut();
  }
}