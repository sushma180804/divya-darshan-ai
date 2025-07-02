// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:divya_darshan_ai/screens/login_screen.dart';
import 'package:divya_darshan_ai/widgets/booking_dialog.dart';
import 'package:divya_darshan_ai/screens/donation_screen.dart';
import 'package:divya_darshan_ai/screens/volunteer_registration_screen.dart';
import 'package:divya_darshan_ai/screens/support_screen.dart';
import 'package:divya_darshan_ai/widgets/volunteer_dashboard.dart';
import 'package:divya_darshan_ai/screens/my_bookings_screen.dart';

// NOTE: The import for 'language_test_screen.dart' has been removed.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showConfirmationDialog(BuildContext context, Map<String, dynamic> bookingData) {
    final darshanDate = (bookingData['darshanDate'] as Timestamp?)?.toDate();
    final dateString = darshanDate != null ? DateFormat('dd-MM-yyyy').format(darshanDate) : "N/A";
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Booking Confirmed!'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text('Slot booked for ${bookingData['darshanTime'] ?? 'N/A'}\non $dateString', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        actions: [
          TextButton(child: const Text('Close'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton.icon(
            icon: const Icon(Icons.receipt_long),
            label: const Text('View My Bookings'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  void _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is permanent and cannot be undone. All your bookings will be lost. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await user.delete();
        messenger.showSnackBar(const SnackBar(content: Text('Account deleted successfully.')));
        navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
      } on FirebaseAuthException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Error deleting account: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              accountName: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Devotee';
                    return Text(name, style: const TextStyle(color: Colors.white));
                  }
                  return const Text('Devotee', style: TextStyle(color: Colors.white));
                },
              ),
              accountEmail: Text(user?.email ?? '', style: const TextStyle(color: Colors.white)),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.deepPurple)),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.receipt_long, color: Colors.orange), title: const Text('My Bookings'), onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
            }),
            ListTile(leading: const Icon(Icons.help_outline, color: Colors.green), title: const Text('Find Help & Support'), onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
            }),
            ListTile(leading: const Icon(Icons.support_agent, color: Colors.blue), title: const Text('Become a Volunteer'), onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const VolunteerRegistrationScreen()));
            }),
            ListTile(leading: const Icon(Icons.volunteer_activism, color: Colors.pink), title: const Text('Make a Donation'), onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DonationScreen()));
            }),
            
            // --- THE LANGUAGE BUTTON HAS BEEN REMOVED FROM HERE ---

            const Divider(),
            ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('Delete Account'), onTap: () => _deleteAccount(context)),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            }),
          ],
        ),
      ),
      appBar: AppBar(title: const Text('Divya Darshan Home')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFB4AEE8), Color(0xFF89F7FE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _WelcomeCard(user: user),
                _CrowdStatusCard(),
                _MainContent(user: user),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final scaffoldContext = context;
          final result = await showDialog(context: scaffoldContext, builder: (dialogContext) => BookSlotDialog(user: user));
          if (result != null && result is Map<String, dynamic>) {
            _showConfirmationDialog(scaffoldContext, result);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Book Darshan Slot'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final User? user;
  const _WelcomeCard({required this.user});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        String displayName = user?.email ?? "Devotee";
        if (snapshot.hasData && snapshot.data!.exists) {
           final data = snapshot.data!.data() as Map<String, dynamic>;
           displayName = data['name'] ?? displayName;
        }
        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [
            Text('Welcome, $displayName!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('"May the divine blessings of Lord Venkateswara be with you always."', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
          ])),
        );
      },
    );
  }
}

class _CrowdStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.lightBlue.shade50,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('app_status').doc('live_updates').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: Text("Loading crowd status..."));
            final String crowdLevel = snapshot.data?['crowd_level'] ?? 'Normal';
            final Color statusColor;
            switch(crowdLevel.toLowerCase()) {
              case 'heavy': statusColor = Colors.red.shade700; break;
              case 'moderate': statusColor = Colors.orange.shade700; break;
              default: statusColor = Colors.green.shade700;
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Live Crowd Status:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(crowdLevel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final User? user;
  const _MainContent({this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No user profile found.")));
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final String role = userData['role'] ?? 'devotee';
        if (role != 'devotee') {
          String collectionName = (role == 'volunteer') ? 'volunteers' : (role == 'emergency_responder') ? 'emergencies' : 'tour_guides';
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection(collectionName).doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final bool isAvailable = snapshot.data?['available'] ?? false;
              return VolunteerDashboard(isInitiallyAvailable: isAvailable, userRole: role, collectionName: collectionName);
            });
        } else {
          return Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Welcome! Use the menu to see your bookings or find help.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.deepPurple[700]),
              ),
            ),
          );
        }
      },
    );
  }
}