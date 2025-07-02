// lib/services/pdf_service.dart

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  static Future<Uint8List> generateBookingPdf(Map<String, dynamic> bookingData) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/icon.png')).buffer.asUint8List(),
    );

    final primaryColor = PdfColor.fromHex('#6D28D9');
    final secondaryColor = PdfColor.fromHex('#F59E42');
    final lightGreyColor = PdfColor.fromHex('#F3F4F6');
    final darkGreyColor = PdfColor.fromHex('#4B5563');

    final darshanDate = (bookingData['darshanDate'] as Timestamp?)?.toDate();
    final dateString = darshanDate != null 
        ? "${darshanDate.day.toString().padLeft(2,'0')}-${darshanDate.month.toString().padLeft(2,'0')}-${darshanDate.year}"
        : "N/A";

    final slotTime = bookingData['darshanTime']?.toString() ?? 'N/A';
    final bookerName = bookingData['bookerName']?.toString() ?? 'Guest';
    final phone = bookingData['phone']?.toString() ?? 'N/A';
    final membersCount = bookingData['members']?.toString() ?? '1';
    final family = bookingData['family'] as List<dynamic>? ?? [];
    final duration = bookingData['darshanDurationSeconds']?.toString() ?? '60';
    final bookingId = bookingData['id']?.toString() ?? 'N/A';
    final qrData = 'BookingID: $bookingId\nSlot: $slotTime\nName: $bookerName';

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(height: 60, width: 60, child: pw.Image(logoImage)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Divya Darshan AI', style: pw.TextStyle(font: boldTtf, fontSize: 24, color: primaryColor)),
                      pw.Text('E-Ticket for Darshan', style: pw.TextStyle(fontSize: 16, color: darkGreyColor)),
                    ],
                  ),
                ],
              ),
              pw.Divider(height: 30, thickness: 2),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: lightGreyColor,
                  border: pw.Border.all(color: primaryColor, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Darshan Date:', dateString, boldTtf),
                          _buildDetailRow('Darshan Time:', slotTime, boldTtf),
                          _buildDetailRow('Est. Duration:', '$duration seconds / person', boldTtf),
                          _buildDetailRow('Booker Name:', bookerName, boldTtf),
                          _buildDetailRow('Contact Phone:', phone, boldTtf),
                          _buildDetailRow('Total Members:', membersCount, boldTtf),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                           pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: qrData,
                            width: 140,
                            height: 140,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text('Scan at Entry Gate', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: boldTtf, color: secondaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('List of Devotees', style: pw.TextStyle(font: boldTtf, fontSize: 18, color: primaryColor)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['S.No.', 'Name', 'Age'],
                headerStyle: pw.TextStyle(font: boldTtf, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellAlignment: pw.Alignment.center,
                data: List<List<String>>.generate(
                  family.length,
                  (index) => [
                    (index + 1).toString(),
                    family[index]['name']?.toString() ?? '',
                    family[index]['age']?.toString() ?? '',
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Divider(height: 20),
              pw.Center(
                child: pw.Text(
                  'May Lord Venkateswara bless you and your family. Have a divine darshan!',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: darkGreyColor),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildDetailRow(String title, String value, pw.Font boldFont) {
    // --- THIS IS THE FIX: Added 'pw.EdgeInsets.' before 'symmetric' ---
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 120, child: pw.Text(title, style: pw.TextStyle(font: boldFont))),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}