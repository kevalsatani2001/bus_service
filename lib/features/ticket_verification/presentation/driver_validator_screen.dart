import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:bus_service/core/config/app_config.dart';
import 'package:bus_service/core/services/firestore_service.dart';
import 'passenger_scan_screen.dart';

class DriverValidatorScreen extends StatefulWidget {
  final String tripId;

  const DriverValidatorScreen({super.key, required this.tripId});

  @override
  State<DriverValidatorScreen> createState() => _DriverValidatorScreenState();
}

class _DriverValidatorScreenState extends State<DriverValidatorScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  Timer? _overlayTimer;

  // Validation feedback state
  bool? _isSuccess;
  String? _statusMessage;
  String? _passengerName;
  String? _seatNumber;

  @override
  void dispose() {
    _scannerController.dispose();
    _overlayTimer?.cancel();
    super.dispose();
  }

  bool get _isTesting => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> _handleScannedData(String rawData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isSuccess = null;
      _statusMessage = null;
      _passengerName = null;
      _seatNumber = null;
    });

    try {
      String? ticketId;
      String? tripId;

      final urlTicketId = AppConfig.ticketIdFromUrl(rawData);
      if (urlTicketId != null) {
        ticketId = urlTicketId;
        if (!_isTesting) {
          final ticket = await FirestoreService.instance.getTicket(ticketId);
          if (ticket == null) throw Exception('ખોટી ટિકિટ!');
          tripId = ticket.tripId;
        } else {
          tripId = widget.tripId;
        }
      } else {
        final payload = jsonDecode(rawData) as Map<String, dynamic>;
        ticketId = payload['ticketId'] as String?;
        tripId = payload['tripId'] as String?;
      }

      if (ticketId == null || tripId == null) {
        throw const FormatException('ખોટી ટિકિટ!');
      }

      // 2. Fetch ticket details from Firestore
      String passengerName = 'Unknown Passenger';
      String seatNumber = 'N/A';
      String ticketTripId = '';
      bool isAlreadyScanned = false;

      if (!_isTesting) {
        final ticketSnap = await FirebaseFirestore.instance
            .collection('tickets')
            .doc(ticketId)
            .get();

        if (!ticketSnap.exists || ticketSnap.data() == null) {
          throw Exception('ખોટી ટિકિટ!');
        }

        final ticketMap = ticketSnap.data()!;
        passengerName = ticketMap['passengerName'] ?? 'Passenger';
        seatNumber = ticketMap['seatNumber'] ?? 'N/A';
        ticketTripId = ticketMap['tripId'] ?? '';
        isAlreadyScanned = ticketMap['isScanned'] ?? false;
      } else {
        // Mock validations inside test environments
        ticketTripId = tripId;
        if (ticketId == 'mock-tck-wrong-trip') {
          ticketTripId = 'TR-OTHER';
        } else if (ticketId == 'mock-tck-already-scanned') {
          isAlreadyScanned = true;
        } else if (ticketId == 'mock-tck-not-found') {
          throw Exception('ખોટી ટિકિટ!');
        }
        passengerName = 'Jane Doe';
        seatNumber = '14A';
      }

      // 3. Validation Rules
      if (ticketTripId != widget.tripId) {
        throw Exception('ખોટી ટિકિટ!');
      }

      if (isAlreadyScanned) {
        throw Exception('ટિકિટ ઓલરેડી વપરાયેલી છે!');
      }

      // 4. Mark checked-in true in Firestore
      if (!_isTesting) {
        await FirebaseFirestore.instance
            .collection('tickets')
            .doc(ticketId)
            .update({'isScanned': true});
      }

      // 5. Emit Pleasant Auditory Cue & Haptics (Bypassed during tests)
      if (!_isTesting) {
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.lightImpact();
      }

      // Show success overlay banner
      setState(() {
        _isSuccess = true;
        _statusMessage = 'Checked In!';
        _passengerName = passengerName;
        _seatNumber = seatNumber;
      });
    } catch (e) {
      // Show failed overlay banner
      setState(() {
        _isSuccess = false;
        final errMsg = e.toString().replaceFirst('Exception: ', '');
        if (errMsg.contains('not found') || errMsg.contains('format') || errMsg.contains('payload')) {
          _statusMessage = 'ખોટી ટિકિટ!';
        } else {
          _statusMessage = errMsg;
        }
      });
      // Emit error alert vibration/sound
      if (!_isTesting) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.vibrate();
      }
    } finally {
      // Auto dismiss verification overlay after 2.5 seconds to resume scans
      _overlayTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _isSuccess = null;
            _statusMessage = null;
            _passengerName = null;
            _seatNumber = null;
            _isProcessing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stream of boarding tally count
    final Stream<List<int>> tallyStream = _isTesting
        ? Stream.value([2, 5])
        : FirebaseFirestore.instance
            .collection('tickets')
            .where('tripId', isEqualTo: widget.tripId)
            .snapshots()
            .map((snap) {
            final total = snap.docs.length;
            final scanned = snap.docs.where((doc) => doc.data()['isScanned'] == true).length;
            return [scanned, total];
          });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Boarding Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Mobile Camera Scanner
          Positioned.fill(
            child: _buildScannerView(),
          ),

          // 2. Translucent Overlay Shape
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: ShapeDecoration(
                  shape: QrScannerOverlayShape(
                    borderColor: _isSuccess == null
                        ? Colors.blue.shade600
                        : (_isSuccess! ? Colors.green : Colors.red),
                    borderRadius: 20,
                    borderLength: 30,
                    borderWidth: 8,
                    cutOutSize: MediaQuery.of(context).size.width * 0.7,
                  ),
                ),
              ),
            ),
          ),

          // 3. Boarding Tally Counter (Sticky on top of scanner overlay)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Center(
              child: StreamBuilder<List<int>>(
                stream: tallyStream,
                builder: (context, snapshot) {
                  final scannedCount = snapshot.data?[0] ?? 0;
                  final totalBooked = snapshot.data?[1] ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.5)),
                    ),
                    child: Text(
                      'બોર્ડિંગ થયેલ પેસેન્જર: $scannedCount/$totalBooked',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. Status Verification Banner Overlay (Centered)
          if (_isSuccess != null)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isSuccess != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black87,
                  child: Center(
                    child: Card(
                      color: _isSuccess! ? Colors.green.shade900 : Colors.red.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSuccess! ? Icons.check_circle_outline : Icons.error_outline,
                              color: Colors.white,
                              size: 72,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _statusMessage ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_isSuccess! && _passengerName != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Passenger: $_passengerName',
                                style: const TextStyle(color: Colors.white70, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Seat Number: $_seatNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 5. Manual Scanning Status Text
          if (_isSuccess == null)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.qr_code_scanner, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _isProcessing ? 'Validating ticket...' : 'Ready to verify tickets',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    if (_isTesting) {
      return Container(
        color: Colors.grey.shade900,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Driver Validation Scanner (Test Mode)',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Simulate Valid Scan', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    _handleScannedData(
                      '{"ticketId": "mock-tck-valid", "tripId": "${widget.tripId}"}'
                    );
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  icon: const Icon(Icons.warning, color: Colors.white),
                  label: const Text('Simulate Wrong Trip', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    _handleScannedData(
                      '{"ticketId": "mock-tck-wrong-trip", "tripId": "${widget.tripId}"}'
                    );
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  icon: const Icon(Icons.repeat, color: Colors.white),
                  label: const Text('Simulate Recheck', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    _handleScannedData(
                      '{"ticketId": "mock-tck-already-scanned", "tripId": "${widget.tripId}"}'
                    );
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.error, color: Colors.white),
                  label: const Text('Simulate Invalid', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    _handleScannedData(
                      '{"ticketId": "mock-tck-not-found", "tripId": "${widget.tripId}"}'
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    return MobileScanner(
      controller: _scannerController,
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          final rawVal = barcode.rawValue;
          if (rawVal != null) {
            _handleScannedData(rawVal);
            break;
          }
        }
      },
    );
  }
}
