// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:divya_darshan_ai/screens/home_screen.dart';
import 'package:divya_darshan_ai/screens/login_screen.dart';
import 'package:divya_darshan_ai/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DivyaDarshanApp());
}

class DivyaDarshanApp extends StatelessWidget {
  const DivyaDarshanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divya Darshan AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'OpenSans',
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // --- THIS IS THE FIX: Removed 'const' ---
          return HomeScreen(); 
        }
        return const LoginScreen();
      },
    );
  }
}