// lib/screens/donation_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill user details from Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
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
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // This function simulates a successful payment
  Future<void> _simulateDonation() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty || (double.tryParse(amountText) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Pretend we are talking to a payment gateway for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // Create a fake payment ID for our records
    final fakePaymentId = 'SIM_${DateTime.now().millisecondsSinceEpoch}';

    // Save the successful donation to Firestore
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('donations').add({
      'userId': user?.uid,
      'userName': _nameController.text,
      'userEmail': _emailController.text,
      'amount': amountText,
      'paymentId': fakePaymentId,
      'status': 'SUCCESS (Simulated)',
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _isProcessing = false);

    // Show success message and navigate back
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation Successful! Thank you for your contribution.'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  void _setAmount(String amount) {
    _amountController.text = amount;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make a Donation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.volunteer_activism, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              'Your contribution helps in maintaining the temple and supporting its charitable activities. Every donation matters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Enter Amount (INR)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(onPressed: () => _setAmount('101'), child: const Text('₹ 101')),
                OutlinedButton(onPressed: () => _setAmount('251'), child: const Text('₹ 251')),
                OutlinedButton(onPressed: () => _setAmount('501'), child: const Text('₹ 501')),
                OutlinedButton(onPressed: () => _setAmount('1001'), child: const Text('₹ 1001')),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _simulateDonation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: _isProcessing 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) 
                  : const Text('Proceed to Donate'),
            ),
          ],
        ),
      ),
    );
  }
}