// lib/screens/support_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:divya_darshan_ai/screens/emergency_responder_registration.dart';
import 'package:divya_darshan_ai/screens/tour_guide_registration.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Navigation'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  const String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=13.6833,79.3484';
                  _launchUrl(googleMapsUrl);
                },
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(children: [
                      Icon(Icons.directions, color: Colors.blue, size: 40),
                      SizedBox(height: 8),
                      Text('Navigate to Temple', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Get live directions to the main entrance', textAlign: TextAlign.center),
                    ],),),),),
            const SizedBox(height: 24),

            _buildSectionHeader('Emergency Medical Help', Icons.medical_services, Colors.red),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Register to Provide Emergency Help'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyResponderRegistrationScreen()));
                },),),
            _buildFirestoreList(
              collection: 'emergencies', icon: Icons.local_hospital,
              titleField: 'name', subtitleField: 'location_description',
              contactField: 'contact', checkAvailableStatus: true,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Available Volunteers', Icons.support_agent, Colors.green),
            _buildFirestoreList(
              collection: 'volunteers', icon: Icons.support_agent,
              titleField: 'name', subtitleField: 'location',
              contactField: 'phone', checkAvailableStatus: true,
            ),
             const SizedBox(height: 24),

            _buildSectionHeader('Tour Guides', Icons.tour, Colors.orange),
             Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Register as a Tour Guide'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TourGuideRegistrationScreen()));
                },),),
            _buildFirestoreList(
              collection: 'tour_guides', icon: Icons.tour,
              titleField: 'name', subtitleField: 'languages',
              contactField: 'phone', checkAvailableStatus: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(children: [
          Icon(icon, color: color), const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],),);
  }

  Widget _buildFirestoreList({
    required String collection, required IconData icon, required String titleField,
    required String subtitleField, required String contactField, bool checkAvailableStatus = false,
  }) {
    Query query = FirebaseFirestore.instance.collection(collection);
    if (checkAvailableStatus) {
      query = query.where('available', isEqualTo: true);
    }
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        
        // --- THIS IS THE FIX: Added curly braces ---
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No ${collection.replaceAll('_', ' ')} currently available.'),
            ),
          );
        }
        
        final items = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index].data() as Map<String, dynamic>;
            final title = item[titleField] ?? 'N/A';
            dynamic subtitleData = item[subtitleField];
            String subtitle = subtitleData is List ? subtitleData.join(', ') : subtitleData?.toString() ?? 'N/A';
            final contact = item[contactField] ?? '';
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(child: Icon(icon)),
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: contact.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _launchUrl('tel:$contact'))
                    : null,
              ),
            ).animate().fade(delay: (100 * index).ms, duration: 400.ms).slideY(begin: 0.3);},);},);
  }
}