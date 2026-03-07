/*class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Hero(
              tag: "nexchat_logo",
              child: Icon(
                Icons.chat_bubble_rounded,
                color: isDark
                    ? const Color(0xFF00F5FF)
                    : const Color(0xFF2962FF),
              ),
            ),
            const SizedBox(width: 10),
            const Text("NexChat"),
          ],
        ),
      ),
      body: const Center(child: Text("Home Screen")),
    );
  }
}*/
