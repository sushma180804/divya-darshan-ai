// lib/widgets/volunteer_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerDashboard extends StatefulWidget {
  final bool isInitiallyAvailable;
  final String userRole;
  final String collectionName;

  const VolunteerDashboard({
    super.key,
    required this.isInitiallyAvailable,
    required this.userRole,
    required this.collectionName,
  });

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.isInitiallyAvailable;
  }

  Future<void> _updateAvailability(bool newStatus) async {
    // Store the messenger before the async call
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() => _isAvailable = newStatus);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection(widget.collectionName).doc(user.uid).update({'available': newStatus});
      
      messenger.showSnackBar(
        SnackBar(content: Text('Status set to: ${newStatus ? "Available" : "Off Duty"}'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if(mounted) {
        setState(() => _isAvailable = !newStatus);
        // We can use the original context here because we checked if the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = "Control Panel";
    if (widget.userRole == 'volunteer') title = "Volunteer Control Panel";
    if (widget.userRole == 'emergency_responder') title = "Emergency Responder Panel";
    if (widget.userRole == 'tour_guide') title = "Tour Guide Panel";
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 16),
            const Text('Use this switch to set your availability. Devotees can only see you when you are available.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 20),
            SwitchListTile.adaptive(
              title: Text(_isAvailable ? 'I am Available' : 'I am Off Duty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(_isAvailable ? 'Visible to devotees' : 'Hidden from devotees'),
              value: _isAvailable,
              onChanged: _updateAvailability,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}