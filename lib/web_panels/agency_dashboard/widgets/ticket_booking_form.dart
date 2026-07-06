import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';
import 'printer.dart';
import 'package:bus_service/core/config/app_config.dart';
import 'package:bus_service/core/models/models.dart';
import 'package:bus_service/core/services/firestore_service.dart';
import 'package:bus_service/core/services/seed_data_service.dart';
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
  String? _selectedBoarding;
  String? _selectedDrop;
  List<Trip> _trips = [];
  List<String> _bookedSeats = [];
  bool _loadingTrips = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Color get _primaryColor => widget.themeColor ?? Colors.indigo;
  bool get _isTesting => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> _loadTrips() async {
    final trips = await FirestoreService.instance.getTrips(widget.tenantId);
    if (mounted) {
      setState(() {
        _trips = trips;
        _loadingTrips = false;
      });
    }
  }

  Future<void> _loadBookedSeats(String tripId) async {
    final seats = await FirestoreService.instance.getBookedSeats(tripId);
    if (mounted) setState(() => _bookedSeats = seats);
  }

  String _tripLabel(Trip trip) {
    final route = trip.routeId == 'RT001' ? 'સુરત - બારડોલી - વ્યારા' : trip.routeId;
    final status = trip.status == TripStatus.live ? 'Live' : trip.status.name;
    return '$route ($status)';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTripId == null) {
      _showSnack('Please select a trip');
      return;
    }
    if (_selectedSeatNumber == null) {
      _showSnack('Please select a sleeper seat');
      return;
    }
    if (_selectedBoarding == null) {
      _showSnack('Please select boarding point');
      return;
    }
    if (_selectedDrop == null) {
      _showSnack('Please select drop point');
      return;
    }

    try {
      final ticketId = _isTesting
          ? 'TICK-${DateTime.now().millisecondsSinceEpoch % 100000}'
          : await FirestoreService.instance.generateTicketId();

      final trackingUrl = AppConfig.trackingUrl(ticketId);

      final ticket = Ticket(
        id: ticketId,
        tenantId: widget.tenantId,
        tripId: _selectedTripId!,
        passengerName: _nameController.text.trim(),
        passengerPhone: _phoneController.text.trim(),
        seatNumber: _selectedSeatNumber!,
        boardingPoint: _selectedBoarding!,
        dropPoint: _selectedDrop!,
        qrHash: ticketId,
        trackingUrl: trackingUrl,
        isScanned: false,
        bookedAt: DateTime.now(),
      );

      if (!_isTesting) {
        await FirestoreService.instance.saveTicket(ticket);
      }

      widget.onTicketBooked?.call();

      final bookedSeat = _selectedSeatNumber!;
      final tripId = _selectedTripId!;
      final passengerName = _nameController.text.trim();
      final passengerPhone = _phoneController.text.trim();
      final boarding = _selectedBoarding!;
      final drop = _selectedDrop!;

      _nameController.clear();
      _phoneController.clear();
      setState(() {
        _selectedSeatNumber = null;
        _selectedBoarding = null;
        _selectedDrop = null;
      });

      if (mounted) {
        _showSuccessModal(
          ticketId: ticketId,
          tripId: tripId,
          seatNo: bookedSeat,
          trackingUrl: trackingUrl,
          passengerName: passengerName,
          passengerPhone: passengerPhone,
          boarding: boarding,
          drop: drop,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to book ticket: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccessModal({
    required String ticketId,
    required String tripId,
    required String seatNo,
    required String trackingUrl,
    required String passengerName,
    required String passengerPhone,
    required String boarding,
    required String drop,
  }) {
    final printData = TicketPrintData(
      ticketId: ticketId,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      seatNumber: seatNo,
      tripId: tripId,
      boardingPoint: boarding,
      dropPoint: drop,
      trackingUrl: trackingUrl,
      qrData: trackingUrl,
    );

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ticket Booked Successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(ticketId, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: QrImageView(
                    data: trackingUrl,
                    version: QrVersions.auto,
                    size: 180.0,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  trackingUrl,
                  style: TextStyle(color: _primaryColor, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Seat', seatNo),
                      _detailRow('Trip', tripId),
                      _detailRow('Boarding', boarding),
                      _detailRow('Drop', drop),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Print Ticket', style: TextStyle(fontSize: 12)),
                        onPressed: () => printTicket(printData),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share to WA', style: TextStyle(fontSize: 12)),
                        onPressed: () => _shareWhatsApp(
                          phone: passengerPhone,
                          ticketId: ticketId,
                          seatNo: seatNo,
                          tripId: tripId,
                          trackingUrl: trackingUrl,
                          boarding: boarding,
                          drop: drop,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _shareWhatsApp({
    required String phone,
    required String ticketId,
    required String seatNo,
    required String tripId,
    required String trackingUrl,
    required String boarding,
    required String drop,
  }) async {
    final formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message =
        'નમસ્કાર! તમારી બસની ટિકિટ સફળતાપૂર્વક બુક થઈ ગઈ છે.\n'
        'ટિકિટ ID: $ticketId\n'
        'સીટ: $seatNo | ટ્રિપ: $tripId\n'
        'બેસવાનું: $boarding\n'
        'ઉતરવાનું: $drop\n'
        'લાઇવ ટ્રેકિંગ: $trackingUrl';

    final uri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardingPoints = SeedDataService.boardingPoints;
    final dropPoints = SeedDataService.dropPoints;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Passenger Name (પેસેન્જર નામ)',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter passenger name' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (મોબાઇલ)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter phone number';
                    if (v.trim().length < 8) return 'Enter a valid phone number';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBoarding,
                  decoration: const InputDecoration(
                    labelText: 'Boarding Point (બેસવાનું)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: boardingPoints
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBoarding = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDrop,
                  decoration: const InputDecoration(
                    labelText: 'Drop Point (ઉતરવાનું ગામ)',
                    prefixIcon: Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: dropPoints
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDrop = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingTrips)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<String>(
              value: _selectedTripId,
              decoration: const InputDecoration(
                labelText: 'Select Scheduled Trip Route',
                prefixIcon: Icon(Icons.route_outlined),
                border: OutlineInputBorder(),
              ),
              items: _trips
                  .map((t) => DropdownMenuItem(value: t.id, child: Text(_tripLabel(t))))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTripId = value;
                  _selectedSeatNumber = null;
                });
                if (value != null) _loadBookedSeats(value);
              },
            ),
          if (_selectedTripId != null) ...[
            const SizedBox(height: 24),
            Text(
              'Select Seat from Layout Berth (2x1 Sleeper)',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Selected Seat No:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                  SleeperLayout(
                    bookedSeats: _bookedSeats,
                    themeColor: _primaryColor,
                    onSeatSelected: (seatLabel) {
                      setState(() {
                        _selectedSeatNumber =
                            _selectedSeatNumber == seatLabel ? null : seatLabel;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
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
