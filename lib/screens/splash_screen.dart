// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:divya_darshan_ai/main.dart'; // We need this to navigate to the RootScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // This function will run after the screen is built
    _navigateToHome();
  }

  void _navigateToHome() async {
    // Wait for 3 seconds
    await Future.delayed(const Duration(seconds: 3), () {});
    
    // After 3 seconds, replace the splash screen with the RootScreen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RootScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is the UI of our splash screen
    return Scaffold(
      body: Container(
        // Use the deep blue color from your beautiful logo
        color: const Color(0xFF2a405c), 
        child: Center(
          // Display your full floral logo
          child: Image.asset(
            'assets/splash.png', // Make sure your floral logo is named this
            width: MediaQuery.of(context).size.width * 0.8, // Use 80% of screen width
          ),
        ),
      ),
    );
  }
}