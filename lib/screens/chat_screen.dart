import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = [
      Message(
        sender: "Anna",
        text: "Sent you the document.",
        avatar: "https://randomuser.me/api/portraits/women/44.jpg",
        isMe: false,
        time: "10:45 AM",
      ),
      Message(
        sender: "Me",
        text: "Thanks! I'll check it out.",
        avatar: "https://randomuser.me/api/portraits/men/32.jpg",
        isMe: true,
        time: "10:47 AM",
      ),
      Message(
        sender: "Anna",
        text: "Are we meeting later?",
        avatar:
            "https://randomuser.me/api/portraits/women/44.jpg", // Kept consistency with Anna
        isMe: false,
        time: "11:00 AM",
      ),
      Message(
        sender: "Me",
        text: "Yes, let's meet at 3 PM.",
        avatar: "https://randomuser.me/api/portraits/men/32.jpg",
        isMe: true,
        time: "11:00 AM",
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                "https://randomuser.me/api/portraits/women/44.jpg",
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Anna",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Online",
                  style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [
          /// Messages Area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: messages.length + 1, // +1 for the Date Divider
              itemBuilder: (context, index) {
                // DATE DIVIDER (Top of the chat)
                if (index == 0) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Today",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                // Adjust index for messages array
                final msg = messages[index - 1];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// LEFT SIDE: Either Anna's message OR "Me" timestamp
                      Expanded(
                        child: msg.isMe
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const SizedBox(
                                    height: 28,
                                  ), // Aligns time with the dot
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Text(
                                      msg.time,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _MessageCard(message: msg, alignRight: false),
                      ),

                      /// TIMELINE (Center)
                      SizedBox(
                        width: 30, // Narrowed since time is gone
                        child: Column(
                          children: [
                            Container(
                              width: 2,
                              height: 30,
                              color: Colors.grey.shade300,
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            ),
                            // Removed time from here!
                          ],
                        ),
                      ),

                      /// RIGHT SIDE: Either "Me" message OR Anna's timestamp
                      Expanded(
                        child: msg.isMe
                            ? _MessageCard(message: msg, alignRight: true)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 28,
                                  ), // Aligns time with the dot
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      msg.time,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
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

          /// INPUT BAR (Polished)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue, size: 28),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(
                          Icons.sentiment_satisfied_alt,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.mic, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Message message;
  final bool alignRight;

  const _MessageCard({required this.message, required this.alignRight});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight)
              CircleAvatar(
                radius: 12, // Slightly smaller avatar to fit nicely
                backgroundImage: NetworkImage(message.avatar),
              ),
            if (!alignRight) const SizedBox(width: 6),
            Text(
              message.sender,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: alignRight ? Colors.blue.shade200 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(message.text),
        ),
      ],
    );
  }
}

class Message {
  final String sender;
  final String text;
  final String avatar;
  final bool isMe;
  final String time;

  Message({
    required this.sender,
    required this.text,
    required this.avatar,
    required this.isMe,
    required this.time,
  });
}
