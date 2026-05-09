import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, voice, image }

class MessageModel {
  final String id;            // renamed from msgId to match ChatScreen usage
  final String senderId;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final DateTime sentAt;
  final List<String> readBy;
  final int? duration;

  // Delete fields
  final bool deletedForEveryone;
  final List<String> deletedFor;

  // Reply fields
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;
  final MessageType? replyToType;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.duration,
    required this.sentAt,
    required this.readBy,
    this.deletedForEveryone = false,
    this.deletedFor = const [],
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    this.replyToType,
  });

  bool get isRead => readBy.length > 1;

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromMap(data, id: doc.id);
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return MessageModel(
      id:       id,
      senderId: map['senderId'] as String,
      type:     _typeFromString(map['type'] as String? ?? 'text'),
      content:  map['content'] as String? ?? '',
      mediaUrl: map['mediaUrl'] as String?,
      sentAt:   (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy:   List<String>.from(map['readBy'] ?? []),
      duration: map['duration'] as int?,
      deletedForEveryone: map['deletedForEveryone'] as bool? ?? false,
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
      replyToId:         map['replyToId'] as String?,
      replyToContent:    map['replyToContent'] as String?,
      replyToSenderName: map['replyToSenderName'] as String?,
      replyToType: map['replyToType'] == 'voice'
          ? MessageType.voice
          : map['replyToType'] == 'text'
          ? MessageType.text
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'type':     _typeToString(type),
    'content':  content,
    'mediaUrl': mediaUrl,
    'sentAt':   FieldValue.serverTimestamp(),
    'readBy':   readBy,
    'duration': duration,
    'deletedForEveryone': deletedForEveryone,
    'deletedFor': deletedFor,
    if (replyToId != null) 'replyToId': replyToId,
    if (replyToContent != null) 'replyToContent': replyToContent,
    if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
    if (replyToType != null) 'replyToType': replyToType!.name,
  };

  MessageModel copyWith({List<String>? readBy}) => MessageModel(
    id:       id,
    senderId: senderId,
    type:     type,
    content:  content,
    mediaUrl: mediaUrl,
    sentAt:   sentAt,
    readBy:   readBy ?? this.readBy,
    duration: duration,
    deletedForEveryone: deletedForEveryone,
    deletedFor: deletedFor,
    replyToId:         replyToId,
    replyToContent:    replyToContent,
    replyToSenderName: replyToSenderName,
    replyToType:       replyToType,
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