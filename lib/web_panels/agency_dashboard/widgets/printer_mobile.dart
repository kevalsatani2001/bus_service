import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:bus_service/web_panels/agency_dashboard/widgets/ticket_print_data.dart';

Future<void> printTicketImpl(TicketPrintData? data) async {
  if (data == null) return;

  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text('Bus Ticket', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 4),
          pw.Center(child: pw.Text(data.ticketId, style: const pw.TextStyle(fontSize: 10))),
          pw.Divider(),
          _row('Passenger', data.passengerName),
          _row('Phone', data.passengerPhone),
          _row('Seat', data.seatNumber),
          _row('Trip', data.tripId),
          _row('Boarding', data.boardingPoint),
          _row('Drop', data.dropPoint),
          pw.SizedBox(height: 8),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: data.qrData,
            width: 120,
            height: 120,
          ),
          pw.SizedBox(height: 8),
          pw.Text(data.trackingUrl, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    ),
  );

  if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;

  await Printing.layoutPdf(onLayout: (_) async => pdf.save());
}

pw.Widget _row(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}
