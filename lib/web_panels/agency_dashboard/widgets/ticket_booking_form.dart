import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'printer.dart';
import 'package:bus_service/core/models/models.dart';
import 'package:bus_service/features/seat_layout/widgets/sleeper_layout.dart';

class TicketBookingForm extends StatefulWidget {
  final String tenantId;
  final Color? themeColor;
  final VoidCallback? onTicketBooked;

  const TicketBookingForm({
    super.key,
    required this.tenantId,
    this.themeColor,
    this.onTicketBooked,
  });

  @override
  State<TicketBookingForm> createState() => _TicketBookingFormState();
}

class _TicketBookingFormState extends State<TicketBookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedTripId;
  String? _selectedSeatNumber;

  // List of mock booked seats for the selected trips
  final Map<String, List<String>> _bookedSeatsPerTrip = {
    'TR001': ['L1', 'L3', 'U5', 'U12'],
    'TR002': ['L2', 'L7', 'L10', 'U1', 'U8'],
    'TR003': ['L4', 'L9', 'U15'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Color get _primaryColor => widget.themeColor ?? Colors.indigo;

  bool get _isTesting => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a trip')),
      );
      return;
    }

    if (_selectedSeatNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sleeper seat')),
      );
      return;
    }

    try {
      // Generate a unique ticketId hash using SHA-256 of the JSON containing tenantId, tripId, and seatNumber
      final Map<String, String> payload = {
        'tenantId': widget.tenantId,
        'tripId': _selectedTripId!,
        'seatNumber': _selectedSeatNumber!,
      };
      final String jsonStr = jsonEncode(payload);
      final List<int> bytes = utf8.encode(jsonStr);
      final Digest digest = sha256.convert(bytes);
      final String ticketId = digest.toString();

      final ticket = Ticket(
        id: ticketId,
        tenantId: widget.tenantId,
        tripId: _selectedTripId!,
        passengerName: _nameController.text.trim(),
        passengerPhone: _phoneController.text.trim(),
        seatNumber: _selectedSeatNumber!,
        qrHash: ticketId,
        isScanned: false,
        bookedAt: DateTime.now(),
      );

      // Save to Cloud Firestore (safeguarded in test environments)
      if (!_isTesting) {
        await FirebaseFirestore.instance
            .collection('tickets')
            .doc(ticketId)
            .set(ticket.toJson());
      }

      // Trigger success callback if provided
      widget.onTicketBooked?.call();

      // Clear the form fields
      _nameController.clear();
      _phoneController.clear();
      final bookedSeat = _selectedSeatNumber;
      final tripId = _selectedTripId;
      
      setState(() {
        _selectedSeatNumber = null;
      });

      // Show Success Modal Dialog with QR Code
      if (mounted) {
        _showSuccessModal(ticketId, tripId!, bookedSeat!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book ticket: $e')),
        );
      }
    }
  }

  void _showSuccessModal(String ticketId, String tripId, String seatNo) {
    final qrPayload = jsonEncode({
      'tenantId': widget.tenantId,
      'tripId': tripId,
      'ticketId': ticketId,
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green verify check indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ticket Booked Successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ticket ID: $ticketId',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // High-resolution QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: QrImageView(
                    data: qrPayload,
                    version: QrVersions.auto,
                    size: 180.0,
                    gapless: false,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('SEAT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(seatNo, style: TextStyle(color: _primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('TRIP', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(tripId, style: TextStyle(color: _primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Print Ticket', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Printing ticket...')),
                          );
                          printTicket();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share to WA', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final String rawPhone = _phoneController.text.trim();
                          final String formattedPhone = rawPhone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
                          final String messageText = 
                              'નમસ્કાર! તમારી બસની ટિકિટ સફળતાપૂર્વક બુક થઈ ગઈ છે.\n'
                              'ટિકિટ ID (Hash): $ticketId\n'
                              'સીટ નંબર: $seatNo\n'
                              'ટ્રિપ ID: $tripId\n'
                              'લોકેશન ટ્રેક કરવા માટે અહીં ક્લિક કરો: https://bus-service-saas.web.app/passenger/trip-details/$ticketId';
                          
                          final String whatsappUrl = 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(messageText)}';
                          final Uri uri = Uri.parse(whatsappUrl);
                          
                          try {
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not launch WhatsApp.')),
                                );
                              }
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to trigger sharing action.')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Close Modal button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of fields for details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Passenger Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter passenger name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.trim().length < 8) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Trip Selector Dropdown
          DropdownButtonFormField<String>(
            value: _selectedTripId,
            decoration: const InputDecoration(
              labelText: 'Select Scheduled Trip Route',
              prefixIcon: Icon(Icons.route_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'TR001', child: Text('Delhi - Jaipur (Live)')),
              DropdownMenuItem(value: 'TR002', child: Text('Mumbai - Pune (Scheduled)')),
              DropdownMenuItem(value: 'TR003', child: Text('Bangalore - Chennai (Completed)')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTripId = value;
                _selectedSeatNumber = null; // Reset seat when trip changes
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Sleeper Seat Selector View (displays only when trip is selected)
          if (_selectedTripId != null) ...[
            Text(
              'Select Seat from Layout Berth',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Current selection display indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Seat No:',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      Chip(
                        backgroundColor: _selectedSeatNumber != null
                            ? _primaryColor.withOpacity(0.12)
                            : Colors.grey.shade100,
                        label: Text(
                          _selectedSeatNumber ?? 'None Selected',
                          style: TextStyle(
                            color: _selectedSeatNumber != null ? _primaryColor : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // Sleeper Seat layout widget
                  SleeperLayout(
                    bookedSeats: _bookedSeatsPerTrip[_selectedTripId!] ?? [],
                    themeColor: _primaryColor,
                    onSeatSelected: (seatLabel) {
                      setState(() {
                        if (_selectedSeatNumber == seatLabel) {
                          _selectedSeatNumber = null; // Toggle off selection
                        } else {
                          _selectedSeatNumber = seatLabel;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Submit Booking Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitForm,
              child: const Text(
                'Confirm Seat & Book Ticket',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
