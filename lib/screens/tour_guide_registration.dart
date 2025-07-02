// lib/screens/tour_guide_registration.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TourGuideRegistrationScreen extends StatefulWidget {
  const TourGuideRegistrationScreen({super.key});

  @override
  State<TourGuideRegistrationScreen> createState() => _TourGuideRegistrationScreenState();
}

class _TourGuideRegistrationScreenState extends State<TourGuideRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _languagesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists && mounted) {
          setState(() {
            _nameController.text = doc.data()?['name'] ?? '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final languagesList = _languagesController.text.split(',').map((s) => s.trim()).toList();

      // 1. Create the public tour guide profile
      final guideRef = FirebaseFirestore.instance.collection('tour_guides').doc(user.uid);
      batch.set(guideRef, {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'languages': languagesList,
        'available': true, // Default to available
      });

      // 2. Update the user's role
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.set(userRef, {'role': 'tour_guide'}, SetOptions(merge: true));

      await batch.commit();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you! You are now a registered Tour Guide.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as a Tour Guide'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.tour, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Join as an official tour guide. Share your knowledge and help devotees understand the rich history and culture of Tirumala.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name / Business Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter your contact number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _languagesController,
                decoration: const InputDecoration(labelText: 'Languages Spoken (comma-separated)', hintText: 'e.g., Telugu, English, Hindi', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter languages' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Register as Guide'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}