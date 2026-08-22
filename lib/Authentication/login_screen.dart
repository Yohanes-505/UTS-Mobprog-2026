import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 30, 
              width: double.infinity, 
              color: Colors.purple,
            ),

            const SizedBox(
              height: 320
            ),

            Image.asset(
              "images/logo.png",
              height: 120,
              fit: BoxFit.contain,
            ),

            const SizedBox(
              height: 30
            ),

            const Text(
              "Welcome To Bamble!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Let's start your match up!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
                                        