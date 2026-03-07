import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),

      body: Column(
        children: [
          const TextField(decoration: InputDecoration(labelText: "Email")),

          const TextField(decoration: InputDecoration(labelText: "Password")),

          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/verify');
            },
            child: const Text("Create Account"),
          ),
        ],
      ),
    );
  }
}
