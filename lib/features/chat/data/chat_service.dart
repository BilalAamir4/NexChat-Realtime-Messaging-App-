import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  // ── Streams ───────────────────────────────────────────────────────────────

  // Stream all chats the current user is part of, ordered by last message time
  Stream<List<ChatModel>> chatsStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .orderBy('lastMessage.sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatModel.fromDoc).toList());
  }

  // Stream all messages in a chat, ordered oldest → newest
  Stream<List<MessageModel>> messagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromDoc).toList());
  }

  // ── Send Message ──────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    final batch = _firestore.batch();

    // 1. Add message to subcollection
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': currentUid,
      'type':     _typeToString(type),
      'content':  content,
      'mediaUrl': mediaUrl,
      'sentAt':   FieldValue.serverTimestamp(),
      'readBy':   [currentUid],
    });

    // 2. Update lastMessage + increment unread for other participants
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatSnap = await chatRef.get();
    final participants = List<String>.from(
      (chatSnap.data()?['participants'] ?? []),
    );

    // Build unreadCount increments for everyone except sender
    final unreadIncrements = <String, dynamic>{};
    for (final uid in participants) {
      if (uid != currentUid) {
        unreadIncrements['unreadCount.$uid'] = FieldValue.increment(1);
      }
    }

    batch.update(chatRef, {
      'lastMessage': {
        'text':     content,
        'senderId': currentUid,
        'sentAt':   FieldValue.serverTimestamp(),
      },
      ...unreadIncrements,
    });

    await batch.commit();
  }

  // ── Mark Messages as Read ─────────────────────────────────────────────────

  Future<void> markAsRead(String chatId) async {
    final batch = _firestore.batch();

    // Get all unread messages (those where currentUid is not in readBy)
    final unreadSnap = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('readBy', arrayContainsAny: ['__placeholder__'])
        .get();

    // Fallback: get recent messages and filter client-side
    final recentSnap = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .get();

    for (final doc in recentSnap.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      if (!readBy.contains(currentUid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUid]),
        });
      }
    }

    // Reset unread count for current user
    batch.update(
      _firestore.collection('chats').doc(chatId),
      {'unreadCount.$currentUid': 0},
    );

    await batch.commit();
  }

  // ── Create Chat ───────────────────────────────────────────────────────────

  // Returns existing chatId if a direct chat already exists, else creates one
  Future<String> getOrCreateDirectChat(String otherUid) async {
    // Check if a direct chat already exists between the two users
    final existing = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'direct')
        .where('participants', arrayContains: currentUid)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUid)) {
        return doc.id;
      }
    }

    // No existing chat — create one
    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'type':         'direct',
      'participants': [currentUid, otherUid],
      'lastMessage':  null,
      'createdAt':    FieldValue.serverTimestamp(),
      'unreadCount':  {currentUid: 0, otherUid: 0},
      'groupName':    null,
    });

    return chatRef.id;
  }

  // ── Typing Indicator ──────────────────────────────────────────────────────

  Future<void> setTyping(String chatId, bool isTyping) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({'typing.$currentUid': isTyping});
  }

  Stream<Map<String, bool>> typingStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return {};
      final typingMap = data['typing'] as Map<String, dynamic>? ?? {};
      return typingMap.map((k, v) => MapEntry(k, v as bool));
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _typeToString(MessageType t) => switch (t) {
    MessageType.voice => 'voice',
    MessageType.image => 'image',
    MessageType.text  => 'text',
  };
}