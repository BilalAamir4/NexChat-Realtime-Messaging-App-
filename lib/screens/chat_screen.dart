import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../features/chat/models/message_model.dart';
import '../features/chat/providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _indigo      = Color(0xFF4F46E5);
  static const _violet      = Color(0xFF7C3AED);
  static const _indigo100   = Color(0xFFE0E7FF);
  static const _indigo200   = Color(0xFFC7D2FE);
  static const _cardSurface = Color(0xFFF7F8FF);
  static const _pageDark    = Color(0xFFE8EEFF);
  static const _pageLight   = Color(0xFFF0F4FF);
  static const _slateDark   = Color(0xFF1E1B4B);
  static const _slateMuted  = Color(0xFF94A3B8);

  bool _isRecording = false;
  late AnimationController _waveController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Mark messages as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(markAsReadProvider(widget.chatId));
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    await ref.read(sendMessageProvider.notifier).send(
      chatId:  widget.chatId,
      content: text,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // ── Read receipt ──────────────────────────────────────────────────────────
  Widget _buildReadReceipt(MessageModel msg) {
    final isRead = msg.readBy.length > 1;
    if (isRead) {
      return const Icon(Icons.done_all, size: 13, color: _indigo);
    }
    return const Icon(Icons.done_all, size: 13, color: _slateMuted);
  }

  // ── Waveform ──────────────────────────────────────────────────────────────
  Widget _buildWaveform({bool isActive = false}) {
    final barHeights = [10.0, 18.0, 12.0, 22.0, 14.0, 20.0, 10.0, 16.0, 8.0];
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barHeights.length, (i) {
            final phase =
            ((_waveController.value + i / barHeights.length) % 1.0);
            final scale = isActive
                ? 0.4 + 0.6 * math.sin(phase * math.pi)
                : 1.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: barHeights[i] * scale,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.85)
                    : _indigo200,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Recording bar ─────────────────────────────────────────────────────────
  Widget _buildRecordingBar() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_indigo, _violet],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final pulse = 0.6 +
                      0.4 * math.sin(_waveController.value * 2 * math.pi);
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withValues(alpha: pulse),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              const Text(
                'Recording...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildWaveform(isActive: true)),
              GestureDetector(
                onTap: () => setState(() => _isRecording = false),
                child: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Message bubble ────────────────────────────────────────────────────────
  Widget _buildBubble(MessageModel msg) {
    final isMe = msg.senderId == _myUid;
    final timeStr = DateFormat('h:mm a').format(msg.sentAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LEFT ────────────────────────────────────────────────────────
          Expanded(
            child: isMe
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _slateMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildReadReceipt(msg),
                    ],
                  ),
                ),
              ],
            )
                : _MessageCard(
              text:        msg.content,
              senderName:  widget.otherUserName,
              avatarUrl:   widget.otherUserAvatar,
              alignRight:  false,
              indigo:      _indigo,
              violet:      _violet,
              indigo100:   _indigo100,
              indigo200:   _indigo200,
              slateDark:   _slateDark,
              slateMuted:  _slateMuted,
            ),
          ),

          // ── TIMELINE ────────────────────────────────────────────────────
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 1.5,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _indigo200.withValues(alpha: 0.2),
                        _indigo200,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_indigo, _violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── RIGHT ───────────────────────────────────────────────────────
          Expanded(
            child: isMe
                ? _MessageCard(
              text:        msg.content,
              senderName:  'Me',
              avatarUrl:   '',
              alignRight:  true,
              indigo:      _indigo,
              violet:      _violet,
              indigo100:   _indigo100,
              indigo200:   _indigo200,
              slateDark:   _slateDark,
              slateMuted:  _slateMuted,
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _slateMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatId));

    // Scroll to bottom when new messages arrive
    ref.listen(messagesStreamProvider(widget.chatId), (prev, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: _pageDark,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: _pageLight,
            border: Border(bottom: BorderSide(color: _indigo200, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _indigo,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _indigo200, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _indigo.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 19,
                      backgroundImage: widget.otherUserAvatar.isNotEmpty
                          ? NetworkImage(widget.otherUserAvatar)
                          : null,
                      backgroundColor: _indigo100,
                      child: widget.otherUserAvatar.isEmpty
                          ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: _indigo,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.otherUserName,
                          style: const TextStyle(
                            color: _slateDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Online',
                              style: TextStyle(
                                color: Color(0xFF22C55E),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam_outlined, color: _slateDark),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, color: _slateDark),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: _slateDark),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_pageDark, _pageLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [

            // ── Messages list ──────────────────────────────────────────────
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _indigo),
                ),
                error: (e, st) => Center(
                  child: Text(
                    'Something went wrong',
                    style: TextStyle(color: _slateMuted),
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet\nSay hello!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _slateMuted,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      // Date divider
                      if (index == 0) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _cardSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _indigo200,
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _indigo.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 12,
                                color: _slateMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        );
                      }

                      return _buildBubble(messages[index - 1]);
                    },
                  );
                },
              ),
            ),

            // ── Input bar ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: _pageLight,
                border: const Border(
                  top: BorderSide(color: _indigo200, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _indigo.withValues(alpha: 0.06),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: _isRecording
                    ? _buildRecordingBar()
                    : Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _indigo100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _indigo200, width: 1),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: _indigo,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        cursorColor: _indigo,
                        style: const TextStyle(
                          color: _slateDark,
                          fontSize: 14,
                        ),
                        onChanged: (val) {
                          ref
                              .read(typingNotifierProvider.notifier)
                              .setTyping(
                            widget.chatId,
                            isTyping: val.isNotEmpty,
                          );
                        },
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(
                            color: _slateMuted,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: _cardSurface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: _indigo200,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: _indigo200,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: _indigo,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: const Icon(
                            Icons.sentiment_satisfied_alt_rounded,
                            color: _slateMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button (shows when text is entered)
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder: (context, value, child) {
                        final hasText = value.text.trim().isNotEmpty;
                        return GestureDetector(
                          onTap: hasText ? _sendMessage : null,
                          onLongPressStart: hasText
                              ? null
                              : (_) => setState(() => _isRecording = true),
                          onLongPressEnd: hasText
                              ? null
                              : (_) =>
                              setState(() => _isRecording = false),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [_indigo, _violet],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _violet.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              hasText
                                  ? Icons.send_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message card ──────────────────────────────────────────────────────────────
class _MessageCard extends StatelessWidget {
  final String text;
  final String senderName;
  final String avatarUrl;
  final bool alignRight;
  final Color indigo, violet, indigo100, indigo200, slateDark, slateMuted;

  const _MessageCard({
    required this.text,
    required this.senderName,
    required this.avatarUrl,
    required this.alignRight,
    required this.indigo,
    required this.violet,
    required this.indigo100,
    required this.indigo200,
    required this.slateDark,
    required this.slateMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // Sender row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight && avatarUrl.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: indigo200, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              senderName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: alignRight ? indigo : slateDark,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: alignRight
                ? LinearGradient(
              colors: [indigo, violet],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
                : null,
            color: alignRight ? null : indigo100,
            border: alignRight
                ? null
                : Border.all(color: indigo200, width: 0.8),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(alignRight ? 16 : 4),
              bottomRight: Radius.circular(alignRight ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: alignRight
                    ? indigo.withValues(alpha: 0.2)
                    : indigo200.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: alignRight ? Colors.white : slateDark,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}