import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  // ── Cool Blue-White Palette (matches home screen) ─────────────────────────
  static const _indigo = Color(0xFF4F46E5);
  static const _violet = Color(0xFF7C3AED);
  static const _indigo100 = Color(0xFFE0E7FF);
  static const _indigo200 = Color(0xFFC7D2FE);
  static const _cardSurface = Color(0xFFF7F8FF);
  static const _pageDark = Color(0xFFE8EEFF);
  static const _pageLight = Color(0xFFF0F4FF);
  static const _slateDark = Color(0xFF1E1B4B);
  static const _slateMid = Color(0xFF475569);
  static const _slateMuted = Color(0xFF94A3B8);

  bool _isRecording = false;
  late AnimationController _waveController;

  final List<Message> messages = [
    Message(
      sender: "Anna",
      text: "Sent you the document.",
      avatar: "https://randomuser.me/api/portraits/women/44.jpg",
      isMe: false,
      time: "10:45 AM",
      status: MessageStatus.read,
    ),
    Message(
      sender: "Me",
      text: "Thanks! I'll check it out.",
      avatar: "https://randomuser.me/api/portraits/men/32.jpg",
      isMe: true,
      time: "10:47 AM",
      status: MessageStatus.read,
    ),
    Message(
      sender: "Anna",
      text: "Are we meeting later?",
      avatar: "https://randomuser.me/api/portraits/women/44.jpg",
      isMe: false,
      time: "11:00 AM",
      status: MessageStatus.read,
    ),
    Message(
      sender: "Me",
      text: "Yes, let's meet at 3 PM.",
      avatar: "https://randomuser.me/api/portraits/men/32.jpg",
      isMe: true,
      time: "11:02 AM",
      status: MessageStatus.delivered,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  // ── Read receipt widget ────────────────────────────────────────────────────
  Widget _buildReadReceipt(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 13, color: _slateMuted);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 13, color: _slateMuted);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 13, color: _indigo);
    }
  }

  // ── Animated waveform bars ─────────────────────────────────────────────────
  Widget _buildWaveform({bool isActive = false}) {
    final barHeights = [10.0, 18.0, 12.0, 22.0, 14.0, 20.0, 10.0, 16.0, 8.0];
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
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
                color: isActive ? Colors.white.withOpacity(0.85) : _indigo200,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Voice message bubble ───────────────────────────────────────────────────
  Widget _buildVoiceBubble({required bool isMe}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [_indigo, _violet],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isMe ? null : _indigo100,
        border: isMe ? null : Border.all(color: _indigo200, width: 0.8),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow_rounded,
            color: isMe ? Colors.white : _indigo,
            size: 20,
          ),
          const SizedBox(width: 6),
          _buildWaveform(isActive: isMe),
          const SizedBox(width: 8),
          Text(
            '0:12',
            style: TextStyle(
              color: isMe ? Colors.white70 : _slateMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Recording bar (replaces input when recording) ─────────────────────────
  Widget _buildRecordingBar() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
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
              // Pulsing red dot
              AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) {
                  final pulse =
                      0.6 + 0.4 * math.sin(_waveController.value * 2 * math.pi);
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withOpacity(pulse),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageDark,

      // ── AppBar ─────────────────────────────────────────────────────────────
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
                  // Back
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _indigo,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Avatar — network image with indigo-200 ring
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _indigo200, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _indigo.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 19,
                      backgroundImage: NetworkImage(
                        "https://randomuser.me/api/portraits/women/44.jpg",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Anna",
                          style: TextStyle(
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
                              "Online",
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
                  // Actions
                  IconButton(
                    icon: const Icon(
                      Icons.videocam_outlined,
                      color: _slateDark,
                    ),
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

      // ── Body ───────────────────────────────────────────────────────────────
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
            // ── Messages ────────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
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
                          border: Border.all(color: _indigo200, width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: _indigo.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Today",
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

                  final msg = messages[index - 1];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── LEFT ──────────────────────────────────────────
                        Expanded(
                          child: msg.isMe
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
                                            msg.time,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: _slateMuted,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          _buildReadReceipt(msg.status),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : _MessageCard(
                                  message: msg,
                                  alignRight: false,
                                  indigo: _indigo,
                                  violet: _violet,
                                  indigo100: _indigo100,
                                  indigo200: _indigo200,
                                  cardSurface: _cardSurface,
                                  slateDark: _slateDark,
                                  slateMuted: _slateMuted,
                                ),
                        ),

                        // ── TIMELINE ──────────────────────────────────────
                        SizedBox(
                          width: 28,
                          child: Column(
                            children: [
                              // Line above dot
                              Container(
                                width: 1.5,
                                height: 26,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _indigo200.withOpacity(0.2),
                                      _indigo200,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              // Dot — gradient
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
                                // Inner white ring for depth
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

                        // ── RIGHT ─────────────────────────────────────────
                        Expanded(
                          child: msg.isMe
                              ? _MessageCard(
                                  message: msg,
                                  alignRight: true,
                                  indigo: _indigo,
                                  violet: _violet,
                                  indigo100: _indigo100,
                                  indigo200: _indigo200,
                                  cardSurface: _cardSurface,
                                  slateDark: _slateDark,
                                  slateMuted: _slateMuted,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 30),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        msg.time,
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
                },
              ),
            ),

            // ── Input bar ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: _pageLight,
                border: const Border(
                  top: BorderSide(color: _indigo200, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _indigo.withOpacity(0.06),
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
                          // Attachment
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
                          // Text field
                          Expanded(
                            child: TextField(
                              cursorColor: _indigo,
                              style: const TextStyle(
                                color: _slateDark,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: "Type a message...",
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
                          // Mic button — hold to record
                          GestureDetector(
                            onLongPressStart: (_) =>
                                setState(() => _isRecording = true),
                            onLongPressEnd: (_) =>
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
                                    color: _violet.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
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
  final Message message;
  final bool alignRight;
  final Color indigo,
      violet,
      indigo100,
      indigo200,
      cardSurface,
      slateDark,
      slateMuted;

  const _MessageCard({
    required this.message,
    required this.alignRight,
    required this.indigo,
    required this.violet,
    required this.indigo100,
    required this.indigo200,
    required this.cardSurface,
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
            if (!alignRight)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: indigo200, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(message.avatar),
                ),
              ),
            if (!alignRight) const SizedBox(width: 6),
            Text(
              message.sender,
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
        // Bubble — card surface for received, gradient for sent
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
                    ? indigo.withOpacity(0.2)
                    : indigo200.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.text,
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

// ── Data models ───────────────────────────────────────────────────────────────
enum MessageStatus { sent, delivered, read }

class Message {
  final String sender;
  final String text;
  final String avatar;
  final bool isMe;
  final String time;
  final MessageStatus status;

  const Message({
    required this.sender,
    required this.text,
    required this.avatar,
    required this.isMe,
    required this.time,
    required this.status,
  });
}
