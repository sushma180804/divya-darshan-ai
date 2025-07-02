// lib/screens/emergency_responder_registration.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyResponderRegistrationScreen extends StatefulWidget {
  const EmergencyResponderRegistrationScreen({super.key});

  @override
  State<EmergencyResponderRegistrationScreen> createState() => _EmergencyResponderRegistrationScreenState();
}

class _EmergencyResponderRegistrationScreenState extends State<EmergencyResponderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  final _typeController = TextEditingController();
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
    _contactController.dispose();
    _locationController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Create the public emergency responder profile
      final responderRef = FirebaseFirestore.instance.collection('emergencies').doc(user.uid);
      batch.set(responderRef, {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'location_description': _locationController.text.trim(),
        'type': _typeController.text.trim(),
        'available': true,
      });

      // 2. Update the user's role
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.set(userRef, {'role': 'emergency_responder'}, SetOptions(merge: true));

      await batch.commit();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you! You are now a registered emergency responder.'), backgroundColor: Colors.green),
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
        title: const Text('Register for Emergency Help'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.medical_services, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Register if you can provide First-Aid or medical assistance in an emergency. Your help can be invaluable.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter your contact number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Your General Location', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter your location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type of Help (e.g., "First Aid", "Doctor")', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter type of help' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Register as Responder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}