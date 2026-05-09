import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService _instance = PresenceService._();
  static PresenceService get instance => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _rtdb = FirebaseDatabase.instance;

  User? _lastKnownUser; // ← fix for auth re-emission bug

  void init() {
    WidgetsBinding.instance.addObserver(this);

    _auth.authStateChanges().listen((user) {
      // Only call _setOnline for a genuinely new login, not token refreshes
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
        break; // ← ignore inactive/hidden — they fire during normal use
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  DatabaseReference? get _rtdbRef {
    final uid = _uid;
    if (uid == null) return null;
    return _rtdb.ref('presence/$uid');
  }

  Future<void> _setOnline() async {
    final rtdbRef = _rtdbRef;
    if (rtdbRef == null) return;

    try {
      // Tell RTDB: "if I disconnect for any reason, write this automatically"
      await rtdbRef.onDisconnect().set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });

      // Now mark as online in RTDB
      await rtdbRef.set({
        'isOnline': true,
        'lastSeen': ServerValue.timestamp,
      });

      // Mirror to Firestore (your presenceProvider reads from here)
      await _userDoc?.set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('PresenceService._setOnline error: $e');
    }
  }

  Future<void> _setOffline() async {
    final rtdbRef = _rtdbRef;

    try {
      // Cancel the onDisconnect handler since we're going offline gracefully
      await rtdbRef?.onDisconnect().cancel();

      await rtdbRef?.set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });

      await _userDoc?.set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('PresenceService._setOffline error: $e');
    }
  }

  Future<void> signOut() async {
    await _setOffline();
    await _auth.signOut();
  }
}