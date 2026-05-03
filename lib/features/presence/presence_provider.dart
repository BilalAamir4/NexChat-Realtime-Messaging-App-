import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class UserPresence {
  final bool isOnline;
  final DateTime? lastSeen;

  const UserPresence({required this.isOnline, this.lastSeen});

  /// Returns a human-readable "last seen" string, e.g. "last seen 3 min ago".
  String get lastSeenLabel {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final diff = DateTime.now().difference(lastSeen!);

    if (diff.inSeconds < 60) return 'last seen just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'last seen $m min${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'last seen $h hr${h == 1 ? '' : 's'} ago';
    }
    final d = diff.inDays;
    return 'last seen $d day${d == 1 ? '' : 's'} ago';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Stream the presence of any user by their UID.
/// Usage:  ref.watch(presenceProvider('uid_here'))
final presenceProvider =
StreamProvider.family<UserPresence, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
    final data = snap.data();
    if (data == null) return const UserPresence(isOnline: false);

    final isOnline = data['isOnline'] as bool? ?? false;
    final ts = data['lastSeen'];
    final lastSeen = ts is Timestamp ? ts.toDate() : null;

    return UserPresence(isOnline: isOnline, lastSeen: lastSeen);
  });
});