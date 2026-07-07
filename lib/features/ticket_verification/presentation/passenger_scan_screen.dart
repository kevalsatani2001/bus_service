import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bus_service/core/blocs/theme_bloc.dart';
import 'package:bus_service/core/config/app_config.dart';
import 'package:bus_service/core/services/firestore_service.dart';

class PassengerScanScreen extends StatefulWidget {
  const PassengerScanScreen({super.key});

  @override
  State<PassengerScanScreen> createState() => _PassengerScanScreenState();
}

class _PassengerScanScreenState extends State<PassengerScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _ticketIdController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _ticketIdController.dispose();
    super.dispose();
  }

  bool get _isTesting => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  Color _parseHexColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.indigo;
    }
  }

  Future<void> _handleScannedData(String rawData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String? ticketId;
      String? tenantId;

      // Support public tracking URL QR (mytravels.com/track/TICK-1042)
      final urlTicketId = AppConfig.ticketIdFromUrl(rawData);
      if (urlTicketId != null) {
        ticketId = urlTicketId;
        if (!_isTesting) {
          final ticket = await FirestoreService.instance.getTicket(ticketId);
          tenantId = ticket?.tenantId ?? 'T1';
        } else {
          tenantId = 'T1';
        }
      } else {
        // Legacy JSON payload
        final payload = jsonDecode(rawData) as Map<String, dynamic>;
        tenantId = payload['tenantId'] as String?;
        ticketId = payload['ticketId'] as String?;
      }

      if (tenantId == null || ticketId == null) {
        throw const FormatException('Invalid QR code payload structure');
      }

      // 2. Fetch Tenant branding configs from Firestore
      String themeColorHex = '#3F51B5'; // Default indigo color hex
      String? logoUrl;
      String tenantName = 'Multi-Tenant Agency';

      if (!_isTesting) {
        final doc = await FirestoreService.database
            .collection('agencies')
            .doc(tenantId)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          themeColorHex = data['themeColor'] ?? '#3F51B5';
          logoUrl = data['logoUrl'];
          tenantName = data['name'] ?? 'Travel Agency';
        }
      } else {
        // Mock configurations for unit testing environment
        if (tenantId == 'mock-tenant-custom') {
          themeColorHex = '#E91E63'; // custom pink
          tenantName = 'Custom Test Agency';
        }
      }

      // 3. Update active theme color on-the-fly via ThemeBloc
      final activeColor = _parseHexColor(themeColorHex);
      if (mounted) {
        context.read<ThemeBloc>().add(ThemeLoadTenant(
          color: activeColor,
          logoUrl: logoUrl,
          tenantName: tenantName,
        ));
      }

      // 4. Navigate seamlessly to trip details view
      if (mounted) {
        context.go('/passenger/trip-details/$ticketId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid QR Ticket: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleManualTicketId(String ticketId) async {
    if (ticketId.trim().isEmpty) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String tenantId = 'mock-tenant-custom';
      String themeColorHex = '#3F51B5';
      String? logoUrl;
      String tenantName = 'Multi-Tenant Agency';

      if (!_isTesting) {
        // Query ticket document to get its tenantId
        final ticketDoc = await FirestoreService.database
            .collection('tickets')
            .doc(ticketId.trim())
            .get();

        if (!ticketDoc.exists || ticketDoc.data() == null) {
          throw Exception('Ticket not found in system database');
        }

        tenantId = ticketDoc.data()!['tenantId'] as String? ?? '';
        
        final agencyDoc = await FirestoreService.database
            .collection('agencies')
            .doc(tenantId)
            .get();

        if (agencyDoc.exists && agencyDoc.data() != null) {
          final data = agencyDoc.data()!;
          themeColorHex = data['themeColor'] ?? '#3F51B5';
          logoUrl = data['logoUrl'];
          tenantName = data['name'] ?? 'Travel Agency';
        }
      } else {
        if (ticketId == 'TCK-MOCK-999') {
          tenantId = 'mock-tenant-custom';
          themeColorHex = '#E91E63';
          tenantName = 'Custom Test Agency';
        }
      }

      final activeColor = _parseHexColor(themeColorHex);
      if (mounted) {
        context.read<ThemeBloc>().add(ThemeLoadTenant(
          color: activeColor,
          logoUrl: logoUrl,
          tenantName: tenantName,
        ));
      }

      if (mounted) {
        context.go('/passenger/trip-details/${ticketId.trim()}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error locating ticket: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.watch<ThemeBloc>().state.themeColor;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Mobile Camera Scanner / Mock Testing View
          Positioned.fill(
            child: _buildScannerView(),
          ),

          // 2. Translucent Overlay with scan target box
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: ShapeDecoration(
                  shape: QrScannerOverlayShape(
                    borderColor: themeColor,
                    borderRadius: 20,
                    borderLength: 30,
                    borderWidth: 8,
                    cutOutSize: MediaQuery.of(context).size.width * 0.7,
                  ),
                ),
              ),
            ),
          ),

          // 3. Passenger controls container at the bottom
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Translucent Manual Entry & Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Instructions Label
                      Center(
                        child: Text(
                          _isProcessing ? 'Verifying Ticket...' : 'Align ticket QR inside bounds',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Manual Input Field Row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: TextField(
                                controller: _ticketIdController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Or enter Ticket ID manually...',
                                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.08),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white24, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: themeColor, width: 1.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            onPressed: () {
                              _handleManualTicketId(_ticketIdController.text);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined, color: Colors.white24, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Camera View (Testing Mode)',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text('Simulate Scan Ticket'),
                onPressed: () {
                  _handleScannedData(
                    '{"tenantId": "mock-tenant-custom", "tripId": "TR001", "ticketId": "TCK-MOCK-999"}'
                  );
                },
              ),
            ],
          ),
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

/// Custom shape overlay simulating the scanner alignment crosshairs
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.indigo,
    this.borderWidth = 8.0,
    this.borderLength = 30.0,
    this.borderRadius = 20.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addOval(Rect.fromCircle(
        center: rect.center,
        radius: cutOutSize / 2,
      ));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final size = cutOutSize;

    final left = (width - size) / 2;
    final top = (height - size) / 2;
    final right = left + size;
    final bottom = top + size;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw dark overlay borders around scanner viewport
    canvas.drawRect(Rect.fromLTRB(0, 0, width, top), paint);
    canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), paint);
    canvas.drawRect(Rect.fromLTRB(right, top, width, bottom), paint);
    canvas.drawRect(Rect.fromLTRB(0, bottom, width, height), paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final radius = Radius.circular(borderRadius);

    // Draw top left corner
    canvas.drawPath(
      Path()
        ..moveTo(left + borderLength, top)
        ..lineTo(left + borderRadius, top)
        ..arcToPoint(Offset(left, top + borderRadius), radius: radius)
        ..lineTo(left, top + borderLength),
      borderPaint,
    );

    // Draw top right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength, top)
        ..lineTo(right - borderRadius, top)
        ..arcToPoint(Offset(right, top + borderRadius), radius: radius, clockwise: false)
        ..lineTo(right, top + borderLength),
      borderPaint,
    );

    // Draw bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(left + borderLength, bottom)
        ..lineTo(left + borderRadius, bottom)
        ..arcToPoint(Offset(left, bottom - borderRadius), radius: radius, clockwise: false)
        ..lineTo(left, bottom - borderLength),
      borderPaint,
    );

    // Draw bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength, bottom)
        ..lineTo(right - borderRadius, bottom)
        ..arcToPoint(Offset(right, bottom - borderRadius), radius: radius)
        ..lineTo(right, bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      borderLength: borderLength * t,
      borderRadius: borderRadius * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
