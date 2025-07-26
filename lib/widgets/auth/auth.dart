import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quizcraft/services/auth_service.dart';
import 'package:quizcraft/widgets/auth/login.dart';
import 'package:quizcraft/widgets/dashboard/home.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return AuthScreen();
        } else {
          return HomeScreen();
        }
      },
    );
  }
}
