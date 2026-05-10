import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Null-safe UID ─────────────────────────────────────────────────────────

  String get currentUid => _auth.currentUser?.uid ?? '';

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<List<ChatModel>> chatsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final chats = snap.docs.map(ChatModel.fromDoc).toList();
      chats.sort((a, b) {
        final aTime = a.lastMessage?.sentAt ?? a.createdAt;
        final bTime = b.lastMessage?.sentAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      return chats;
    });
  }

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
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    String? replyToType,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) throw Exception('Not authenticated');

    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': uid,
      'type':     _typeToString(type),
      'content':  content,
      'mediaUrl': mediaUrl,
      'sentAt':   FieldValue.serverTimestamp(),
      'readBy':   [uid],
      'deletedForEveryone': false,
      'deletedFor': [],
      if (replyToId != null)         'replyToId':         replyToId,
      if (replyToContent != null)    'replyToContent':    replyToContent,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToType != null)       'replyToType':       replyToType,
    });

    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatSnap = await chatRef.get();
    final participants = List<String>.from(
      (chatSnap.data()?['participants'] ?? []),
    );

    final unreadIncrements = <String, dynamic>{};
    for (final p in participants) {
      if (p != uid) {
        unreadIncrements['unreadCount.$p'] = FieldValue.increment(1);
      }
    }

    batch.update(chatRef, {
      'lastMessage': {
        'text':     content,
        'senderId': uid,
        'sentAt':   FieldValue.serverTimestamp(),
      },
      ...unreadIncrements,
    });

    await batch.commit();
  }

  // ── Mark Messages as Read ─────────────────────────────────────────────────

  Future<void> markAsRead(String chatId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final batch = _firestore.batch();

    final recentSnap = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .get();

    for (final doc in recentSnap.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      if (!readBy.contains(uid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([uid]),
        });
      }
    }

    batch.update(
      _firestore.collection('chats').doc(chatId),
      {'unreadCount.$uid': 0},
    );

    await batch.commit();
  }

  // ── Create / Get Chat ─────────────────────────────────────────────────────

  Future<String> getOrCreateDirectChat(String otherUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) throw Exception('Not authenticated');

    final existing = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'direct')
        .where('participants', arrayContains: uid)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUid)) {
        return doc.id;
      }
    }

    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'type':         'direct',
      'participants': [uid, otherUid],
      'lastMessage':  null,
      'createdAt':    FieldValue.serverTimestamp(),
      'unreadCount':  {uid: 0, otherUid: 0},
      'groupName':    null,
    });

    return chatRef.id;
  }

  // ── Typing Indicator ──────────────────────────────────────────────────────

  Future<void> setTyping(String chatId, bool isTyping) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({'typing.$uid': isTyping});
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

  Future<void> sendImageMessage({
    required String chatId,
    required File imageFile,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    String? replyToType,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) throw Exception('Not authenticated');

    // Upload to Firebase Storage
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child(chatId)
        .child('${DateTime.now().millisecondsSinceEpoch}_$uid.jpg');

    await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();

    await sendMessage(
      chatId: chatId,
      content: '📷 Photo',
      type: MessageType.image,
      mediaUrl: url,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
      replyToType: replyToType,
    );
  }

  // ── Create Group ──────────────────────────────────────────────────────────

  Future<String> createGroupChat({
    required List<String> memberUids,
    required String groupName,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) throw Exception('Not authenticated');

    final allMembers = [...memberUids, uid].toSet().toList();
    final unreadCount = {for (final m in allMembers) m: 0};

    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'type':         'group',
      'participants': allMembers,
      'groupName':    groupName,
      'lastMessage':  null,
      'createdAt':    FieldValue.serverTimestamp(),
      'unreadCount':  unreadCount,
      'admins':       [uid],
      'typing':       {},
    });

    return chatRef.id;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _typeToString(MessageType t) => switch (t) {
    MessageType.voice => 'voice',
    MessageType.image => 'image',
    MessageType.text  => 'text',
  };
}

