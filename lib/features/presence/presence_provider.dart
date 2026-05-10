import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class UserPresence {
  final bool isOnline;
  final DateTime? lastSeen;

  const UserPresence({required this.isOnline, this.lastSeen});

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

final presenceProvider =
StreamProvider.family<UserPresence, String>((ref, uid) {
  return FirebaseDatabase.instance
      .ref('presence/$uid')
      .onValue
      .map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return const UserPresence(isOnline: false);

    final isOnline = data['isOnline'] as bool? ?? false;
    final lastSeenMs = data['lastSeen'] as int?;
    final lastSeen = lastSeenMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastSeenMs)
        : null;

    return UserPresence(isOnline: isOnline, lastSeen: lastSeen);
  });
});