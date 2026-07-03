import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// The Passenger Live Tracking Screen.
/// Listens to real-time location ticks from Firebase RTD, animates location changes
/// using linear interpolation, renders a custom bus icon, and shows ETA/staff details.
class PassengerMapScreen extends StatefulWidget {
  final String tripId;
  final String ticketHash;
  final Color? themeColor;

  const PassengerMapScreen({
    super.key,
    required this.tripId,
    required this.ticketHash,
    this.themeColor,
  });

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  BitmapDescriptor _busMarkerIcon = BitmapDescriptor.defaultMarker;
  
  // Animation & Interpolation States
  LatLng? _previousPosition;
  LatLng? _currentPosition;
  AnimationController? _markerAnimationController;
  Animation<double>? _markerAnimation;

  // UI state toggles
  bool _isFollowingBus = true;
  bool _hasInitiallyCentered = false;

  // Mock static trip details
  final String _driverName = 'Rajesh Kumar';
  final String _conductorName = 'Amit Sharma';
  final String _seatNumber = '15B';
  final String _etaText = '12 mins';

  @override
  void initState() {
    super.initState();
    _createCustomBusMarker();
  }

  @override
  void dispose() {
    _markerAnimationController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Color get _primaryColor => widget.themeColor ?? Colors.indigo;

  /// Generates a high-quality circular Bus Icon Marker dynamically at runtime
  /// matching the tenant's primary theme color.
  Future<void> _createCustomBusMarker() async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = 80.0;

      // Draw shadow circle
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, shadowPaint);

      // Draw border outer circle
      final borderPaint = Paint()..color = _primaryColor;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

      // Draw inner white fill circle
      final innerPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 8, innerPaint);

      // Draw custom bus icon character in the center
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: String.fromCharCode(Icons.directions_bus.codePoint),
        style: TextStyle(
          fontSize: 44,
          fontFamily: Icons.directions_bus.fontFamily,
          color: _primaryColor,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2),
      );

      final picture = pictureRecorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        setState(() {
          _busMarkerIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
        });
      }
    } catch (_) {
      // Graceful fallback to default marker
      if (mounted) {
        setState(() {
          _busMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        });
      }
    }
  }

  /// Handles incoming live location updates from the Firebase database.
  /// Sets up and starts the linear transition animation.
  void _onLocationUpdate(LatLng newPosition) {
    if (_currentPosition == null) {
      // First update: set position and center camera
      _currentPosition = newPosition;
      _previousPosition = newPosition;
      _centerCameraOnBus();
      return;
    }

    if (_currentPosition == newPosition) return;

    // Set up interpolation animation controller
    _previousPosition = _currentPosition;
    _currentPosition = newPosition;

    _markerAnimationController?.dispose();
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _markerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _markerAnimationController!, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {}); // redraw markers at interpolated step
        if (_isFollowingBus) {
          _centerCameraOnBus();
        }
      });

    _markerAnimationController!.forward();
  }

  /// Interpolates between previous and current coordinates.
  LatLng _getInterpolatedLatLng() {
    if (_previousPosition == null || _currentPosition == null) {
      return _currentPosition ?? const LatLng(0, 0);
    }
    if (_markerAnimation == null) {
      return _currentPosition!;
    }
    
    final t = _markerAnimation!.value;
    final lat = _previousPosition!.latitude + (_currentPosition!.latitude - _previousPosition!.latitude) * t;
    final lng = _previousPosition!.longitude + (_currentPosition!.longitude - _previousPosition!.longitude) * t;
    return LatLng(lat, lng);
  }

  void _centerCameraOnBus() {
    final pos = _getInterpolatedLatLng();
    if (_mapController != null) {
      if (!_hasInitiallyCentered) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pos, 15.5));
        _hasInitiallyCentered = true;
      } else {
        _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseStream = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))
        ? const Stream<DatabaseEvent>.empty()
        : FirebaseDatabase.instance
            .ref('trips/${widget.tripId}/currentLocation')
            .onValue;

    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: databaseStream,
        builder: (context, snapshot) {
          // If we have location data, process the updates
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            try {
              final rawVal = snapshot.data!.snapshot.value;
              if (rawVal is Map) {
                final data = Map<String, dynamic>.from(rawVal);
                final lat = (data['lat'] as num).toDouble();
                final lng = (data['lng'] as num).toDouble();
                
                // Enqueue post frame update to prevent triggering setState inside builder
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _onLocationUpdate(LatLng(lat, lng));
                });
              }
            } catch (_) {}
          }

          final interpolatedPos = _getInterpolatedLatLng();

          return Stack(
            children: [
              // 1. Google Map View
              (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Text('Map View Placeholder (Testing)'),
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: interpolatedPos,
                        zoom: 14,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (_currentPosition != null) {
                          _centerCameraOnBus();
                        }
                      },
                      onCameraMoveStarted: () {
                        // If passenger drags map, disable follow mode to prevent camera fights
                        setState(() {
                          _isFollowingBus = false;
                        });
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('bus_marker'),
                          position: interpolatedPos,
                          icon: _busMarkerIcon,
                          anchor: const Offset(0.5, 0.5),
                          infoWindow: const InfoWindow(title: 'Live Bus Position'),
                        ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),

              // 2. Header Status Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: _buildHeaderCard(),
              ),

              // 3. Floating Action Control Buttons
              Positioned(
                bottom: 210,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'follow_bus_btn',
                      mini: true,
                      backgroundColor: _isFollowingBus ? _primaryColor : Colors.white,
                      foregroundColor: _isFollowingBus ? Colors.white : Colors.grey.shade800,
                      onPressed: () {
                        setState(() {
                          _isFollowingBus = !_isFollowingBus;
                        });
                        if (_isFollowingBus) {
                          _centerCameraOnBus();
                        }
                      },
                      child: const Icon(Icons.navigation, size: 18),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'recenter_btn',
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey.shade800,
                      onPressed: _centerCameraOnBus,
                      child: const Icon(Icons.gps_fixed, size: 18),
                    ),
                  ],
                ),
              ),

              // 4. Passenger Details Sliding Bottom Sheet Panel
              _buildBottomDetailsPanel(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.radar, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Tracking Active',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 14),
                ),
                Text(
                  'Trip ID: ${widget.tripId}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDetailsPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.18,
      maxChildSize: 0.55,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  
                  // 1. ETA and Seat Number info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ESTIMATED ARRIVAL',
                            style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _etaText.split(' ')[0],
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _primaryColor),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _etaText.split(' ')[1],
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'YOUR SEAT',
                              style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _seatNumber,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(color: Colors.black12, height: 24),

                  // 2. Staff/Crew Details Row with Phone Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _primaryColor.withOpacity(0.1),
                              child: Icon(Icons.person, color: _primaryColor, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _driverName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis),
                                  ),
                                  const Text(
                                    'Driver',
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green, size: 18),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling Driver $_driverName (+91 9876543210)...')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _primaryColor.withOpacity(0.1),
                              child: Icon(Icons.person, color: _primaryColor, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _conductorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis),
                                  ),
                                  const Text(
                                    'Conductor',
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green, size: 18),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling Conductor $_conductorName (+91 8765432109)...')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(color: Colors.black12, height: 24),

                  // 3. Interactive Call Support button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connecting to Agency Helpline Support for Seat $_seatNumber...')),
                        );
                      },
                      icon: const Icon(Icons.support_agent_rounded, size: 20),
                      label: const Text('Call Support (સહાયતા મેળવો)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
