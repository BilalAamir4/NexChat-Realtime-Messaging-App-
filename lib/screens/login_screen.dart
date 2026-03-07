import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TextField(decoration: InputDecoration(labelText: "Email")),

            const TextField(decoration: InputDecoration(labelText: "Password")),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/chats');
              },
              child: const Text("Login"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}
