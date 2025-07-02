// lib/widgets/booking_dialog.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookSlotDialog extends StatefulWidget {
  final User? user;
  const BookSlotDialog({super.key, required this.user});

  @override
  State<BookSlotDialog> createState() => _BookSlotDialogState();
}

class _BookSlotDialogState extends State<BookSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  String bookerName = '';
  String phone = '';
  int members = 1;
  List<Map<String, dynamic>> family = [{'name': '', 'age': 0, 'aadhaarProvided': false}];
  bool isHandicapped = false;
  bool isBooking = false;
  DateTime? selectedDate;

  bool get hasSenior => family.any((m) => (m['age'] ?? 0) >= 60);
  bool get hasToddler => family.any((m) => (m['age'] ?? 0) <= 5);

  // --- THIS IS THE NEW, SMARTER TIME ALLOTMENT FUNCTION ---
  Future<String> _getAvailableSlot(DateTime date, {required bool isPriority}) async {
    // Get all bookings for the selected date to find out how many are already there.
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final querySnapshot = await FirebaseFirestore.instance.collection('bookings')
        .where('darshanDate', isGreaterThanOrEqualTo: startOfDay)
        .where('darshanDate', isLessThan: endOfDay)
        .get();
        
    final int bookingsSoFar = querySnapshot.docs.length;

    // Define starting times and the interval between slots.
    final DateTime startTime;
    const int slotIntervalMinutes = 15; // Each new booking is 15 minutes after the last one

    // Priority bookings start earlier in the day
    if (isPriority) {
      startTime = DateTime(date.year, date.month, date.day, 8); // 8:00 AM
    } else {
      startTime = DateTime(date.year, date.month, date.day, 10); // 10:00 AM
    }
    
    // Calculate the next available time slot
    // Formula: Start Time + (Number of existing bookings * Interval)
    final DateTime nextSlotTime = startTime.add(Duration(minutes: bookingsSoFar * slotIntervalMinutes));
    
    // Check if the calculated time is past the closing time (e.g., 6 PM)
    final DateTime closingTime = DateTime(date.year, date.month, date.day, 18);
    if (nextSlotTime.isAfter(closingTime)) {
      return "Slots Full";
    }

    // Format the time into a readable string like "09:15 AM"
    return DateFormat('hh:mm a').format(nextSlotTime);
  }

  Future<void> _bookSlot() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a darshan date.')));
      return;
    }
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => isBooking = true);

    try {
      for (var member in family) {
        if ((member['age'] ?? 0) > 5 && member['aadhaarProvided'] != true) {
          throw Exception('Please provide Aadhaar proof for ${member['name']}');
        }
      }
      
      final bool isPriority = hasSenior || hasToddler || isHandicapped;
      final String darshanTime = await _getAvailableSlot(selectedDate!, isPriority: isPriority);

      if (darshanTime == "Slots Full") {
        throw Exception('Sorry, all slots are full for this date. Please try another day.');
      }
      
      final bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').where('darshanDate', isEqualTo: Timestamp.fromDate(selectedDate!)).get();
      final bool isRushHour = bookingsSnapshot.docs.length > 50;
      final int darshanDurationSeconds = isRushHour ? 30 : 60;

      final Map<String, dynamic> bookingData = {
        'userId': widget.user!.uid,
        'darshanDate': Timestamp.fromDate(selectedDate!),
        'darshanTime': darshanTime,
        'darshanDurationSeconds': darshanDurationSeconds,
        'email': widget.user!.email, 'bookerName': bookerName, 'phone': phone,
        'members': members, 'family': family.map((m) => {'name': m['name'], 'age': m['age']}).toList(),
        'isHandicapped': isHandicapped, 'hasSenior': hasSenior, 'hasToddler': hasToddler,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance.collection('bookings').add(bookingData);
      
      final savedDoc = await docRef.get();
      final finalBookingData = savedDoc.data() as Map<String, dynamic>;
      finalBookingData['id'] = docRef.id;

      if (!navigator.mounted) return;
      navigator.pop(finalBookingData);

    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Booking Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Book a Darshan Slot'),
      content: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
          title: Text(selectedDate == null ? 'Select Darshan Date' : DateFormat('dd-MM-yyyy').format(selectedDate!), style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (picked != null) setState(() => selectedDate = picked);
          },
        ),
        const Divider(),
        TextFormField(decoration: const InputDecoration(labelText: 'Your Full Name'), validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null, onChanged: (v) => bookerName = v),
        TextFormField(decoration: const InputDecoration(labelText: 'Your Phone Number'), keyboardType: TextInputType.phone, validator: (v) => v == null || v.length < 10 ? 'Enter a valid phone number' : null, onChanged: (v) => phone = v),
        TextFormField(decoration: const InputDecoration(labelText: 'Number of Members'), keyboardType: TextInputType.number, initialValue: '1',
          validator: (v) => v == null || int.tryParse(v) == null || int.parse(v) < 1 ? 'Enter a valid number' : null,
          onChanged: (v) {
            final n = int.tryParse(v) ?? 1;
            setState(() { members = n;
              if (family.length < n) { family.addAll(List.generate(n - family.length, (_) => {'name': '', 'age': 0, 'aadhaarProvided': false}));
              } else if (family.length > n) { family = family.sublist(0, n); }
            });
          },
        ),
        const SizedBox(height: 16), const Text("Member Details", style: TextStyle(fontWeight: FontWeight.bold)),
        ...List.generate(members, (i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Divider(),
          TextFormField(decoration: InputDecoration(labelText: 'Member ${i + 1} Name'), validator: (v) => v == null || v.isEmpty ? 'Enter name' : null, onChanged: (v) => family[i]['name'] = v),
          TextFormField(decoration: InputDecoration(labelText: 'Member ${i + 1} Age'), keyboardType: TextInputType.number,
            validator: (v) => v == null || int.tryParse(v) == null ? 'Enter age' : null,
            onChanged: (v) { final age = int.tryParse(v) ?? 0; setState(() => family[i]['age'] = age); },
          ),
          if ((family[i]['age'] ?? 0) > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton.icon(
                icon: Icon(family[i]['aadhaarProvided'] == true ? Icons.check_circle : Icons.upload_file, color: family[i]['aadhaarProvided'] == true ? Colors.green : Theme.of(context).colorScheme.primary),
                label: Text(family[i]['aadhaarProvided'] == true ? 'Aadhaar Provided' : 'Provide Aadhaar'),
                onPressed: () { setState(() { family[i]['aadhaarProvided'] = true; }); },
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('Toddler (Aadhaar not required)', style: TextStyle(color: Colors.blueAccent)),
            ),
        ])),
        const SizedBox(height: 16),
        CheckboxListTile(value: isHandicapped, onChanged: (v) => setState(() => isHandicapped = v ?? false), title: const Text('Any member physically handicapped?')),
        CheckboxListTile(value: hasSenior, onChanged: null, title: const Text('Senior citizen in group (auto-detected)')),
        CheckboxListTile(value: hasToddler, onChanged: null, title: const Text('Toddler in group (auto-detected)')),
      ]))),
      actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: isBooking ? null : _bookSlot,
          child: isBooking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirm Booking'),
        ),
      ],
    );
  }
}