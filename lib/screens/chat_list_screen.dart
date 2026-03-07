import 'dart:async';

import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  // Wave dots animation for typing indicator
  final List<bool> _waveDots = [true, false, false];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        bool last = _waveDots.removeLast();
        _waveDots.insert(0, last);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: _waveDots[i] ? 6 : 3,
          decoration: BoxDecoration(
            color: Colors.teal.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget buildPreviewBubble(
    String text, {
    bool isSent = false,
    bool isTyping = false,
  }) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: isSent ? const Color(0xFF00B8D4) : const Color(0xFFE6E9F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: isTyping
            ? buildTypingIndicator()
            : Text(
                text,
                style: TextStyle(
                  color: isSent ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget buildChatItem({
    required String name,
    String? lastMessage,
    String? time,
    bool isTyping = false,
    int unreadCount = 0,
    bool lastMessageSent = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pushNamed(context, '/chat');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF00B8D4),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF00B8D4),
                        ),
                      ),
                      if (time != null)
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  buildPreviewBubble(
                    isTyping ? '' : (lastMessage ?? ''),
                    isSent: lastMessageSent,
                    isTyping: isTyping,
                  ),
                  if (unreadCount > 0)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B8D4),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B8D4).withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/search');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EBF1)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Tap here to search conversations',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EBF1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.white,
                elevation: 2,
                title: const Text(
                  "Chats",
                  style: TextStyle(
                    color: Color(0xFF00B8D4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    icon: const Icon(Icons.person, color: Color(0xFF00B8D4)),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    buildSearchBar(),
                    buildChatItem(
                      name: "Alex Morgan",
                      lastMessage: "Hey, are you coming today?",
                      time: "12:41",
                      unreadCount: 2,
                      lastMessageSent: false,
                    ),
                    buildChatItem(
                      name: "Sarah Lee",
                      lastMessage: "See you tomorrow!",
                      time: "11:05",
                      lastMessageSent: true,
                    ),
                    buildChatItem(
                      name: "Dev Team",
                      isTyping: true,
                      time: "10:15",
                      unreadCount: 3,
                    ),
                    buildChatItem(
                      name: "John Doe",
                      lastMessage: "Can you review the document?",
                      time: "09:50",
                      lastMessageSent: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
