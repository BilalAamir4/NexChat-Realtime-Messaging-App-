import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),

      body: Column(
        children: [
          const Text("Check your email for verification"),

          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/chats');
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}
