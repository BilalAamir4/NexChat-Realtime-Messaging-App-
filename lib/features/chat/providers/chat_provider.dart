import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

// ── Service Provider ──────────────────────────────────────────────────────────

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// ── Chats Stream ──────────────────────────────────────────────────────────────

final chatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  return ref.watch(chatServiceProvider).chatsStream()
      .handleError((_) => <ChatModel>[]);
});

// ── Messages Stream ───────────────────────────────────────────────────────────

final messagesStreamProvider =
StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatServiceProvider).messagesStream(chatId);
});

// ── Typing Stream ─────────────────────────────────────────────────────────────

final typingStreamProvider =
StreamProvider.family<Map<String, bool>, String>((ref, chatId) {
  return ref.watch(chatServiceProvider).typingStream(chatId);
});

// ── Send Message Notifier ─────────────────────────────────────────────────────

class SendMessageNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> send({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    String? replyToType,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(chatServiceProvider).sendMessage(
          chatId:            chatId,
          content:           content,
          type:              type,
          mediaUrl:          mediaUrl,
          replyToId:         replyToId,
          replyToContent:    replyToContent,
          replyToSenderName: replyToSenderName,
          replyToType:       replyToType,
        ));
  }
}

final sendMessageProvider =
AsyncNotifierProvider<SendMessageNotifier, void>(SendMessageNotifier.new);

// ── Mark As Read ──────────────────────────────────────────────────────────────

final markAsReadProvider =
FutureProvider.family<void, String>((ref, chatId) async {
  await ref.watch(chatServiceProvider).markAsRead(chatId);
});

// ── Create / Get Chat ─────────────────────────────────────────────────────────

final getOrCreateChatProvider =
FutureProvider.family<String, String>((ref, otherUid) async {
  return ref.watch(chatServiceProvider).getOrCreateDirectChat(otherUid);
});

// ── Typing Notifier ───────────────────────────────────────────────────────────

class TypingNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> setTyping(String chatId, {required bool isTyping}) async {
    await ref.read(chatServiceProvider).setTyping(chatId, isTyping);
  }
}

final typingNotifierProvider =
NotifierProvider<TypingNotifier, void>(TypingNotifier.new);

// ── Create Group ──────────────────────────────────────────────────────────────

class CreateGroupNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> createGroup({
    required List<String> memberUids,
    required String groupName,
  }) async {
    state = const AsyncLoading();
    String chatId = '';
    state = await AsyncValue.guard(() async {
      chatId = await ref.read(chatServiceProvider).createGroupChat(
        memberUids: memberUids,
        groupName:  groupName,
      );
    });
    return chatId;
  }
}

final createGroupProvider =
AsyncNotifierProvider<CreateGroupNotifier, void>(CreateGroupNotifier.new);

// ── Delete Message ────────────────────────────────────────────────────────────

class DeleteMessageNotifier {
  final Ref _ref;
  DeleteMessageNotifier(this._ref);

  Future<void> deleteForMe({
    required String chatId,
    required String messageId,
    String? mediaUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> deleteForEveryone({
    required String chatId,
    required String messageId,
    String? mediaUrl,
  }) async {
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(mediaUrl).delete();
      } catch (_) {}
    }
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedForEveryone': true,
      'content': '',
      'mediaUrl': null,
    });
  }
}

final deleteMessageProvider =
Provider<DeleteMessageNotifier>((ref) => DeleteMessageNotifier(ref));