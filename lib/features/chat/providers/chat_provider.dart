import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

// ── Service Provider ──────────────────────────────────────────────────────────

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// ── Chats Stream ──────────────────────────────────────────────────────────────

final chatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  return ref.watch(chatServiceProvider).chatsStream();
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
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(chatServiceProvider).sendMessage(
          chatId:   chatId,
          content:  content,
          type:     type,
          mediaUrl: mediaUrl,
        ),
    );
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