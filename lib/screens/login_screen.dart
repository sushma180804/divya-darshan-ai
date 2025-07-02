// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:divya_darshan_ai/main.dart'; // For RootScreen

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFDE68A), Color(0xFFB4AEE8), Color(0xFF89F7FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: Colors.white.withAlpha(245),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sign in to Divya Darshan AI',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 32),
                      
                      // --- Register New User Button ---
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Register New User'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          String email = '';
                          String password = '';
                          String name = ''; // <-- Variable for the name

                          await showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Register New User'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // <-- New TextField for the name -->
                                      TextField(
                                        decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Enter your name'),
                                        onChanged: (value) => name = value,
                                        textCapitalization: TextCapitalization.words,
                                      ),
                                      TextField(
                                        decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
                                        onChanged: (value) => email = value,
                                        keyboardType: TextInputType.emailAddress,
                                      ),
                                      TextField(
                                        decoration: const InputDecoration(labelText: 'Password'),
                                        onChanged: (value) => password = value,
                                        obscureText: true,
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () => Navigator.pop(dialogContext),
                                  ),
                                  ElevatedButton(
                                    child: const Text('Register'),
                                    onPressed: () async {
                                      if (name.isEmpty || email.isEmpty || password.isEmpty) {
                                        scaffoldMessengerKey.currentState?.showSnackBar(
                                          const SnackBar(content: Text('Please fill all fields.')),
                                        );
                                        return;
                                      }
                                      Navigator.pop(dialogContext); // Close the dialog
                                      try {
                                        // 1. Create the user in Firebase Auth
                                        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                          email: email.trim(),
                                          password: password,
                                        );

                                        // 2. Save the user's name and email in our 'users' collection
                                        if (userCredential.user != null) {
                                          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                                            'name': name,
                                            'email': email.trim(),
                                            'uid': userCredential.user!.uid,
                                            'createdAt': FieldValue.serverTimestamp(),
                                          });
                                        }

                                        if (!context.mounted) return;
                                        // Navigate to home after successful registration
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (context) => const RootScreen()),
                                          (route) => false
                                        );
                                      } on FirebaseAuthException catch (e) {
                                        scaffoldMessengerKey.currentState?.showSnackBar(
                                          SnackBar(content: Text('Registration failed: ${e.message}')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- Sign in with Email Button ---
                      OutlinedButton.icon(
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Sign in with Email'),
                         style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                           String email = '';
                           String password = '';
                           await showDialog(
                             context: context,
                             builder: (dialogContext) => AlertDialog(
                               title: const Text('Email Login'),
                               content: Column(mainAxisSize: MainAxisSize.min, children: [
                                 TextField(decoration: const InputDecoration(labelText: 'Email'), onChanged: (v)=>email=v),
                                 TextField(decoration: const InputDecoration(labelText: 'Password'), obscureText: true, onChanged: (v)=>password=v),
                               ]),
                               actions: [
                                 TextButton(onPressed: ()=>Navigator.pop(dialogContext), child: const Text('Cancel')),
                                 ElevatedButton(onPressed: () async {
                                   Navigator.pop(dialogContext);
                                   try {
                                     await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password);
                                     if(!context.mounted) return;
                                     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c)=>const RootScreen()), (r)=>false);
                                   } on FirebaseAuthException catch(e) {
                                     scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
                                   }
                                 }, child: const Text('Login'))
                               ],
                             ),
                           );
                        }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}