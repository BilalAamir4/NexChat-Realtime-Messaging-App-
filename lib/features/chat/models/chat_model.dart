import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType { direct, group }

class LastMessage {
  final String text;
  final String senderId;
  final DateTime sentAt;

  const LastMessage({
    required this.text,
    required this.senderId,
    required this.sentAt,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) => LastMessage(
    text:     map['text'] as String? ?? '',
    senderId: map['senderId'] as String? ?? '',
    sentAt:   (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'text':     text,
    'senderId': senderId,
    'sentAt':   FieldValue.serverTimestamp(),
  };
}

class ChatModel {
  final String chatId;
  final ChatType type;
  final List<String> participants;
  final LastMessage? lastMessage;
  final DateTime createdAt;
  final Map<String, int> unreadCount;
  final String? groupName;

  const ChatModel({
    required this.chatId,
    required this.type,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.unreadCount,
    this.groupName,
  });

  // Returns the other participant's UID in a direct chat
  String otherUserId(String myUid) =>
      participants.firstWhere((id) => id != myUid, orElse: () => '');

  // Unread count for a specific user
  int unreadFor(String uid) => unreadCount[uid] ?? 0;

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final lastMsgData = data['lastMessage'] as Map<String, dynamic>?;

    return ChatModel(
      chatId:       doc.id,
      type:         data['type'] == 'group' ? ChatType.group : ChatType.direct,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage:  lastMsgData != null ? LastMessage.fromMap(lastMsgData) : null,
      createdAt:    (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount:  Map<String, int>.from(
        (data['unreadCount'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      ),
      groupName: data['groupName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'type':         type == ChatType.group ? 'group' : 'direct',
    'participants': participants,
    'lastMessage':  lastMessage?.toMap(),
    'createdAt':    FieldValue.serverTimestamp(),
    'unreadCount':  unreadCount,
    'groupName':    groupName,
  };
}