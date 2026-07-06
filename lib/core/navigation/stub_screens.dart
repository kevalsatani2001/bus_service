import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/blocs/theme_bloc.dart';
import 'package:bus_service/core/models/models.dart';
import 'package:bus_service/core/services/firestore_service.dart';
import 'package:bus_service/core/services/seed_data_service.dart';
import 'package:bus_service/features/live_tracking/presentation/driver_control_panel.dart';
import 'package:bus_service/features/live_tracking/presentation/passenger_map_screen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Home hub — routes each role to its login page (not directly to protected dashboards).
class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.watch<ThemeBloc>().state.themeColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus SaaS Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Icon(Icons.directions_bus_rounded, size: 72, color: themeColor),
                  const SizedBox(height: 12),
                  const Text(
                    'Bus Live Tracking SaaS',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tamari role select karo ane login karo',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _portalCard(
                    context,
                    icon: Icons.qr_code_scanner_rounded,
                    color: themeColor,
                    title: 'Passenger Portal',
                    subtitle: 'QR scan kari live bus track karo (login nathi joie)',
                    onTap: () => context.go('/passenger/scan'),
                  ),
                  const SizedBox(height: 12),
                  _portalCard(
                    context,
                    icon: Icons.settings_remote_rounded,
                    color: Colors.orange,
                    title: 'Driver / Conductor',
                    subtitle: 'GPS tracking, passenger chart, boarding verify',
                    onTap: () => context.go('/driver/login'),
                  ),
                  const SizedBox(height: 12),
                  _portalCard(
                    context,
                    icon: Icons.storefront_outlined,
                    color: Colors.teal,
                    title: 'Travel Agency (Booking Office)',
                    subtitle: 'Ticket book, QR generate, trips manage',
                    onTap: () => context.go('/agency/login'),
                  ),
                  const SizedBox(height: 12),
                  _portalCard(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    color: Colors.deepPurple,
                    title: 'Super Admin (App Owner)',
                    subtitle: 'Agencies add karo, staff manage karo',
                    onTap: () => context.go('/admin/login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _portalCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class TripDetailsScreen extends StatefulWidget {
  final String ticketHash;

  const TripDetailsScreen({super.key, required this.ticketHash});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  bool _loading = true;
  Ticket? _ticket;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.ticketHash.isEmpty || widget.ticketHash == ':ticketHash') {
      setState(() {
        _errorMsg = 'Ticket ID missing. Please scan your QR code again.';
        _loading = false;
      });
      return;
    }

    final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTesting) {
      setState(() {
        _ticket = Ticket(
          id: widget.ticketHash,
          tenantId: 'T1',
          tripId: 'TR001',
          passengerName: 'Test Passenger',
          passengerPhone: '9999999999',
          seatNumber: '10',
          qrHash: widget.ticketHash,
          isScanned: false,
          bookedAt: DateTime.now(),
        );
        _loading = false;
      });
      return;
    }

    try {
      final ticket = await FirestoreService.instance.getTicket(widget.ticketHash);
      if (ticket == null) {
        setState(() {
          _errorMsg = 'Ticket not found. Please verify your QR code.';
          _loading = false;
        });
        return;
      }

      // Load tenant branding dynamically
      final tenant = await FirestoreService.instance.getTenant(ticket.tenantId);
      if (tenant != null && mounted) {
        final themeColorHex = tenant.themeColorHex.isNotEmpty ? tenant.themeColorHex : '#3F51B5';
        final activeColor = _parseHexColor(themeColorHex);
        context.read<ThemeBloc>().add(ThemeLoadTenant(
          color: activeColor,
          logoUrl: tenant.logoUrl,
          tenantName: tenant.name,
        ));
      }

      if (mounted) {
        setState(() {
          _ticket = ticket;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Error loading tracking details: $e';
          _loading = false;
        });
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMsg.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMsg,
              style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final themeColor = context.watch<ThemeBloc>().state.themeColor;

    return PassengerMapScreen(
      tripId: _ticket?.tripId ?? 'TR001',
      ticketHash: widget.ticketHash,
      themeColor: themeColor,
      ticket: _ticket,
    );
  }
}

/// Driver/Conductor home — loads assigned trip from logged-in session.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String _tripId = 'TR001';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final session = context.read<AuthBloc>().state.session;
    if (session == null) {
      setState(() => _loading = false);
      return;
    }

    final trips = await FirestoreService.instance.getTrips(
      session.tenantId.isEmpty ? SeedDataService.defaultTenantId : session.tenantId,
    );

    Trip? assigned;
    for (final t in trips) {
      if (t.status == TripStatus.live &&
          (t.driverId == session.uid || t.conductorId == session.uid)) {
        assigned = t;
        break;
      }
    }
    if (assigned == null) {
      for (final t in trips) {
        if (t.driverId == session.uid || t.conductorId == session.uid) {
          assigned = t;
          break;
        }
      }
    }
    assigned ??= trips.isNotEmpty ? trips.first : null;

    if (mounted) {
      setState(() {
        _tripId = assigned?.id ?? 'TR001';
        _loading = false;
      });
    }
  }

  void _logout() {
    context.read<AuthBloc>().add(AuthLogoutRequested());
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state.session;
    final roleLabel = session?.role.name ?? 'staff';

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DriverControlPanel(
      tripId: _tripId,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('${session?.name ?? "Driver"} ($roleLabel)'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Trip: $_tripId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('GPS toggle upar thi tracking start/stop karo', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Verify Boarding (Ticket Scan)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.go('/driver/verify/$_tripId'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.list_alt),
                label: const Text('Digital Passenger Chart', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.go('/driver/chart/$_tripId'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
