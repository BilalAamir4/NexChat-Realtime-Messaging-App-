import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, voice, image }

class MessageModel {
  final String msgId;
  final String senderId;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final DateTime sentAt;
  final List<String> readBy;

  const MessageModel({
    required this.msgId,
    required this.senderId,
    required this.type,
    required this.content,
    this.mediaUrl,
    required this.sentAt,
    required this.readBy,
  });

  bool get isRead => readBy.length > 1;

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      msgId:    doc.id,
      senderId: data['senderId'] as String,
      type:     _typeFromString(data['type'] as String? ?? 'text'),
      content:  data['content'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      sentAt:   (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy:   List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'type':     _typeToString(type),
    'content':  content,
    'mediaUrl': mediaUrl,
    'sentAt':   FieldValue.serverTimestamp(),
    'readBy':   readBy,
  };

  MessageModel copyWith({List<String>? readBy}) => MessageModel(
    msgId:    msgId,
    senderId: senderId,
    type:     type,
    content:  content,
    mediaUrl: mediaUrl,
    sentAt:   sentAt,
    readBy:   readBy ?? this.readBy,
  );

  static MessageType _typeFromString(String s) => switch (s) {
    'voice' => MessageType.voice,
    'image' => MessageType.image,
    _       => MessageType.text,
  };

  static String _typeToString(MessageType t) => switch (t) {
    MessageType.voice => 'voice',
    MessageType.image => 'image',
    MessageType.text  => 'text',
  };
}