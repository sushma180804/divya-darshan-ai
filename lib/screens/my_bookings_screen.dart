// lib/screens/my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:divya_darshan_ai/services/pdf_service.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Darshan Bookings'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDE68A), Color(0xFFB4AEE8), Color(0xFF89F7FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: user?.uid)
              .orderBy('darshanDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'You have no bookings yet.',
                  style: TextStyle(fontSize: 18, color: Colors.deepPurple),
                ),
              );
            }
            final docs = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return _BookingCard(bookingData: data);
              },
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const _BookingCard({required this.bookingData});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _isCancelling = false;
  bool _isDownloading = false;

  void _cancelBooking() async {
    setState(() => _isCancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingData['id']).delete();
        messenger.showSnackBar(const SnackBar(content: Text('Booking has been cancelled.')));
      } catch(e) {
        messenger.showSnackBar(SnackBar(content: Text('Could not cancel booking: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) {
      setState(() => _isCancelling = false);
    }
  }

  void _downloadTicket() async {
    setState(() => _isDownloading = true);
    final messenger = ScaffoldMessenger.of(context);
    if (!mounted) return;

    try {
      messenger.showSnackBar(const SnackBar(content: Text('Generating your ticket...'), duration: Duration(seconds: 1)));
      final pdfBytes = await PdfService.generateBookingPdf(widget.bookingData);
      await Printing.sharePdf(bytes: pdfBytes, filename: 'DivyaDarshan_Ticket_${widget.bookingData['id']}.pdf');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darshanDate = (widget.bookingData['darshanDate'] as Timestamp?)?.toDate();
    final dateString = darshanDate != null ? DateFormat('dd-MM-yyyy').format(darshanDate) : "N/A";
    final timeString = widget.bookingData['darshanTime']?.toString() ?? "N/A";
    final qrData = 'BookingID: ${widget.bookingData['id']}';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                QrImageView(data: qrData, version: QrVersions.auto, size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timeString, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
                      Text("On: $dateString"),
                      Text("Members: ${widget.bookingData['members']}"),
                    ],
                  ),
                ),
                _isCancelling 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      tooltip: 'Cancel Booking',
                      onPressed: _cancelBooking,
                    ),
              ],
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: _isDownloading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : ElevatedButton.icon(
                    icon: const Icon(Icons.download_for_offline),
                    label: const Text('Download Ticket'),
                    onPressed: _downloadTicket,
                  ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.5, curve: Curves.easeOut);
  }
}