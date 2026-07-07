import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:bus_service/core/config/app_config.dart';
import 'package:bus_service/core/models/models.dart';
import 'package:bus_service/core/services/eta_service.dart';
import 'package:bus_service/core/services/firestore_service.dart';
import 'package:bus_service/core/services/seed_data_service.dart';

class PassengerMapScreen extends StatefulWidget {
  final String tripId;
  final String ticketHash;
  final Color? themeColor;
  final Ticket? ticket;

  const PassengerMapScreen({
    super.key,
    required this.tripId,
    required this.ticketHash,
    this.themeColor,
    this.ticket,
  });

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  LatLng? _previousPosition;
  LatLng? _currentPosition;
  AnimationController? _markerAnimationController;
  Animation<double>? _markerAnimation;

  bool _isFollowingBus = true;
  bool _hasInitiallyCentered = false;

  Bus? _bus;
  UserStaff? _driver;
  UserStaff? _conductor;
  BusRoute? _route;
  String _etaText = 'Calculating...';

  // Live status tracked from stream
  double _speed = 0.0;
  int _activeStopIndex = 0;
  bool _isGpsLost = false;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    if (_isTesting) {
      setState(() {
        _bus = SeedDataService.defaultBuses.first;
        _driver = SeedDataService.defaultStaff.firstWhere((s) => s.role == UserRole.driver);
        _conductor = SeedDataService.defaultStaff.firstWhere((s) => s.role == UserRole.conductor);
        _route = SeedDataService.suratRirampurRoute;
      });
      return;
    }

    final fs = FirestoreService.instance;
    final tripVal = await fs.getTrip(widget.tripId);
    final trip = tripVal ?? Trip(
      id: widget.tripId.isNotEmpty ? widget.tripId : 'TR001',
      tenantId: SeedDataService.defaultTenantId,
      busId: 'B1',
      driverId: 'D101',
      conductorId: 'C201',
      routeId: 'SURAT_RIRAMPUR',
      status: TripStatus.live,
      startDateTime: DateTime.now(),
    );

    final bus = (await fs.getBuses(trip.tenantId))
            .where((b) => b.id == trip.busId)
            .firstOrNull ??
        SeedDataService.defaultBuses.first;
    final driver = (await fs.getStaffById(trip.driverId)) ??
        SeedDataService.defaultStaff.firstWhere((s) => s.role == UserRole.driver);
    final conductor = trip.conductorId.isNotEmpty
        ? (await fs.getStaffById(trip.conductorId))
        : null;
    final route = (await fs.getRoute(trip.routeId)) ?? SeedDataService.suratRirampurRoute;

    if (mounted) {
      setState(() {
        _bus = bus;
        _driver = driver;
        _conductor = conductor;
        _route = route ?? SeedDataService.suratRirampurRoute;
      });
      _recalculateEta();
    }
  }

  void _recalculateEta() {
    if (_currentPosition == null || _route == null) return;
    final dropName = widget.ticket?.dropPoint ?? '';
    final dropStop = _route!.stopByName(dropName) ??
        _route!.stops.where((s) => s.isDropPoint).lastOrNull;
    if (dropStop == null) return;

    final mins = EtaService.estimateMinutes(
      busLat: _currentPosition!.latitude,
      busLng: _currentPosition!.longitude,
      destLat: dropStop.latitude,
      destLng: dropStop.longitude,
    );
    setState(() {
      _etaText = EtaService.formatEta(mins);
    });
  }

  @override
  void dispose() {
    _markerAnimationController?.dispose();
    super.dispose();
  }

  Color get _primaryColor => widget.themeColor ?? Colors.indigo;
  String get _seatNumber => widget.ticket?.seatNumber ?? '—';
  String get _driverName => _driver?.name ?? 'Driver';
  String get _conductorName => _conductor?.name ?? 'Conductor';
  String get _driverPhone => _driver?.phone ?? '';
  String get _conductorPhone => _conductor?.phone ?? '';
  String get _trackingUrl =>
      widget.ticket?.trackingUrl.isNotEmpty == true
          ? widget.ticket!.trackingUrl
          : AppConfig.trackingUrl(widget.ticketHash);

  bool get _isTesting => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  void _onLocationUpdate(LatLng newPosition) {
    if (_currentPosition == null) {
      if (mounted) {
        setState(() {
          _currentPosition = newPosition;
          _previousPosition = newPosition;
        });
      }
      _centerCameraOnBus();
      _recalculateEta();
      return;
    }
    if (_currentPosition == newPosition) return;
    _previousPosition = _currentPosition;
    _currentPosition = newPosition;
    _markerAnimationController?.dispose();
    _markerAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _markerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _markerAnimationController!, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
        if (_isFollowingBus) _centerCameraOnBus();
      });
    _markerAnimationController!.forward();
    _recalculateEta();
  }

  LatLng _getInterpolatedLatLng() {
    if (_previousPosition == null || _currentPosition == null) {
      return _currentPosition ?? const LatLng(21.2294, 72.8258);
    }
    if (_markerAnimation == null) return _currentPosition!;
    final t = _markerAnimation!.value;
    return LatLng(
      _previousPosition!.latitude + (_currentPosition!.latitude - _previousPosition!.latitude) * t,
      _previousPosition!.longitude + (_currentPosition!.longitude - _previousPosition!.longitude) * t,
    );
  }

  void _centerCameraOnBus() {
    try {
      final pos = _getInterpolatedLatLng();
      if (!_hasInitiallyCentered) {
        _mapController.move(pos, 14.5);
        _hasInitiallyCentered = true;
      } else {
        _mapController.move(pos, _mapController.camera.zoom);
      }
    } catch (_) {
      // Map controller is not yet mounted/initialized
    }
  }

  Future<void> _callPhone(String phone, String label) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No phone number for $label')));
      return;
    }
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareWhatsApp() async {
    final drop = widget.ticket?.dropPoint ?? 'destination';
    final message =
        '🚌 મારી બસ હાલ લાઇવ ટ્રેક થઈ રહી છે!\n'
        'ઉતરવાનું: $drop\n'
        'ETA: $_etaText\n'
        'લાઇવ જોવા: $_trackingUrl';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showBusGallery() {
    if (_bus == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Bus Gallery (બસ ફોટો)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_bus!.exteriorPhotoUrl.isNotEmpty) ...[
              const Text('Exterior', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_bus!.exteriorPhotoUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            if (_bus!.interiorPhotoUrl.isNotEmpty) ...[
              const Text('Interior / Cleanliness', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_bus!.interiorPhotoUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            if (_bus!.berthPhotoUrls.isNotEmpty) ...[
              const Text('Sleeper Berths', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._bus!.berthPhotoUrls.map((url) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url, height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStopTimeline() {
    final route = _route ?? SeedDataService.suratRirampurRoute;
    final busPos = _getInterpolatedLatLng();

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: route.stops.length,
        itemBuilder: (_, i) {
          final stop = route.stops[i];
          final status = _currentPosition != null
              ? EtaService.stopStatus(
                  stop: stop,
                  busLat: busPos.latitude,
                  busLng: busPos.longitude,
                  allStops: route.stops,
                )
              : StopStatus.upcoming;

          final color = switch (status) {
            StopStatus.passed => Colors.green,
            StopStatus.current => Colors.red,
            StopStatus.upcoming => Colors.grey.shade400,
          };

          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                status == StopStatus.current
                    ? const BlinkingActiveStop(color: Colors.red)
                    : Icon(
                        status == StopStatus.passed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: color,
                        size: 22,
                      ),
                const SizedBox(height: 4),
                Text(
                  stop.nameGuj,
                  style: TextStyle(
                    fontSize: 9, 
                    fontWeight: status == StopStatus.current ? FontWeight.bold : FontWeight.normal, 
                    color: status == StopStatus.current ? Colors.red.shade800 : color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stream complete trip location object from database
    Stream<DatabaseEvent>? databaseStream;
    if (!_isTesting) {
      try {
        databaseStream = FirebaseDatabase.instance.ref('trips/${widget.tripId}').onValue;
      } catch (e) {
        print("FirebaseDatabase initialization failed: $e");
      }
    }
    databaseStream ??= const Stream<DatabaseEvent>.empty();

    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: databaseStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            try {
              final rawVal = snapshot.data!.snapshot.value;
              if (rawVal is Map) {
                final data = Map<String, dynamic>.from(rawVal);
                
                // Extract coordinates
                if (data['currentLocation'] != null) {
                  final loc = Map<String, dynamic>.from(data['currentLocation'] as Map);
                  final lat = (loc['latitude'] ?? loc['lat'] as num).toDouble();
                  final lng = (loc['longitude'] ?? loc['lng'] as num).toDouble();
                  
                  if (_currentPosition == null ||
                      _currentPosition!.latitude != lat ||
                      _currentPosition!.longitude != lng) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _onLocationUpdate(LatLng(lat, lng));
                    });
                  }
                }
                
                // Extract metrics
                final speed = (data['speed'] as num? ?? 0.0).toDouble();
                final stopIdx = data['currentActiveStopIndex'] as int? ?? 0;
                final gpsLost = data['isGpsLost'] as bool? ?? false;
                
                if (_speed != speed || _activeStopIndex != stopIdx || _isGpsLost != gpsLost) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _speed = speed;
                        _activeStopIndex = stopIdx;
                        _isGpsLost = gpsLost;
                      });
                    }
                  });
                }
              }
            } catch (_) {}
          }

          final interpolatedPos = _getInterpolatedLatLng();
          final route = _route ?? SeedDataService.suratRirampurRoute;
          final polylinePoints = route.stops.map((s) => LatLng(s.latitude, s.longitude)).toList();
          final stopMarkers = route.stops.map((stop) {
            return Marker(
              point: LatLng(stop.latitude, stop.longitude),
              width: 30,
              height: 30,
              child: const Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 20,
              ),
            );
          }).toList();

          return Stack(
            children: [
              _isTesting
                  ? Container(color: Colors.grey.shade200, child: const Center(child: Text('Map View (Testing)')))
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: interpolatedPos,
                        initialZoom: 14.0,
                        onPositionChanged: (pos, hasGesture) {
                          if (hasGesture) {
                            setState(() => _isFollowingBus = false);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.mytravels.app',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              color: _primaryColor.withOpacity(0.5),
                              strokeWidth: 5.0,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            ...stopMarkers,
                            if (_currentPosition != null && !_isGpsLost)
                              Marker(
                                point: interpolatedPos,
                                width: 50,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: _buildHeaderCard(),
              ),
              Positioned(
                bottom: 280,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Route Timeline (રૂટ)', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 12)),
                        const SizedBox(height: 8),
                        _buildStopTimeline(),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 240,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: _isFollowingBus ? _primaryColor : Colors.white,
                  onPressed: () {
                    setState(() => _isFollowingBus = !_isFollowingBus);
                    if (_isFollowingBus) _centerCameraOnBus();
                  },
                  child: Icon(Icons.navigation, color: _isFollowingBus ? Colors.white : Colors.grey),
                ),
              ),
              _buildBottomPanel(),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(Icons.radar, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Live Tracking Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Trip: ${widget.tripId}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
          if (_isGpsLost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('GPS LOST', style: TextStyle(color: Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('LIVE', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ESTIMATED ARRIVAL (ETA)', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _etaText.split(' ').first,
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _primaryColor),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _etaText.contains(' ') ? _etaText.substring(_etaText.indexOf(' ') + 1) : '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (widget.ticket?.dropPoint.isNotEmpty == true)
                          Text('to ${widget.ticket!.dropPoint}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        if (!_isGpsLost) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text('SPEED', style: TextStyle(color: Colors.indigo, fontSize: 8, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_speed.toStringAsFixed(1)} km/h',
                                  style: TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              const Text('SEAT', style: TextStyle(color: Colors.white70, fontSize: 8)),
                              Text(
                                _seatNumber,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(child: _crewTile(_driverName, 'Driver', _driverPhone)),
                    const SizedBox(width: 8),
                    Expanded(child: _crewTile(_conductorName, 'Conductor', _conductorPhone)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Bus Photos', style: TextStyle(fontSize: 12)),
                        onPressed: _showBusGallery,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share Live Link', style: TextStyle(fontSize: 12)),
                        onPressed: _shareWhatsApp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _crewTile(String name, String role, String phone) {
    return Row(
      children: [
        CircleAvatar(radius: 18, backgroundColor: _primaryColor.withOpacity(0.1), child: Icon(Icons.person, color: _primaryColor, size: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              Text(role, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone_in_talk, color: Colors.green, size: 20),
          onPressed: () => _callPhone(phone, role),
        ),
      ],
    );
  }
}

class BlinkingActiveStop extends StatefulWidget {
  final Color color;
  const BlinkingActiveStop({super.key, required this.color});

  @override
  State<BlinkingActiveStop> createState() => _BlinkingActiveStopState();
}

class _BlinkingActiveStopState extends State<BlinkingActiveStop> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 2),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
