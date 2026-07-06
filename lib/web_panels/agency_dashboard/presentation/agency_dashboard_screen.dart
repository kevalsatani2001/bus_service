import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/blocs/theme_bloc.dart';
import 'package:bus_service/core/theme/tenant_theme_loader.dart';
import 'package:bus_service/core/models/models.dart';
import 'package:bus_service/core/services/firestore_service.dart';
import 'package:bus_service/core/services/seed_data_service.dart';
import 'package:bus_service/web_panels/agency_dashboard/widgets/ticket_booking_form.dart';

class AgencyDashboardScreen extends StatefulWidget {
  final Color? themeColor;

  const AgencyDashboardScreen({super.key, this.themeColor});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  int _activeTabIndex = 0;
  bool _isSidebarCollapsed = false;

  List<Bus> _buses = [];
  List<Trip> _trips = [];
  List<UserStaff> _staff = [];
  Tenant? _agencyTenant;
  bool _loading = true;

  // Profile fields controllers
  final _profileNameCtrl = TextEditingController();
  final _profileOwnerCtrl = TextEditingController();
  final _profileEmailCtrl = TextEditingController();
  final _profilePhoneCtrl = TextEditingController();
  final _profileLicenseCtrl = TextEditingController();
  String _profileColorHex = '#3F51B5';
  bool _profileInitialized = false;

  String get _tenantId {
    try {
      final fromAuth = context.read<AuthBloc>().state.tenantId;
      if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;
    } catch (_) {}
    return SeedDataService.defaultTenantId;
  }

  Color get _primaryColor {
    try {
      return context.watch<ThemeBloc>().state.themeColor;
    } catch (_) {}
    return widget.themeColor ?? Colors.indigo;
  }

  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Overview/Stats', 'icon': Icons.analytics_outlined},
    {'title': 'Buses', 'icon': Icons.directions_bus_outlined},
    {'title': 'Trips', 'icon': Icons.route_outlined},
    {'title': 'Book Ticket / Generate QR', 'icon': Icons.qr_code_outlined},
    {'title': 'Drivers', 'icon': Icons.people_outline},
    {'title': 'Agency Profile', 'icon': Icons.settings_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _profileNameCtrl.dispose();
    _profileOwnerCtrl.dispose();
    _profileEmailCtrl.dispose();
    _profilePhoneCtrl.dispose();
    _profileLicenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final fs = FirestoreService.instance;
    final results = await Future.wait([
      fs.getBuses(_tenantId),
      fs.getTrips(_tenantId),
      fs.getStaff(_tenantId),
      fs.getTenant(_tenantId),
    ]);
    if (mounted) {
      final tenant = results[3] as Tenant?;
      setState(() {
        _buses = results[0] as List<Bus>;
        _trips = results[1] as List<Trip>;
        _staff = results[2] as List<UserStaff>;
        _agencyTenant = tenant;
        _loading = false;
      });

      if (tenant != null) {
        try {
          final color = TenantThemeLoader.hexToColor(tenant.themeColorHex);
          context.read<ThemeBloc>().add(ThemeLoadTenant(
            color: color,
            tenantName: tenant.name,
          ));
        } catch (_) {}
      }
    }
  }

  void _initProfileFields() {
    if (_agencyTenant == null || _profileInitialized) return;
    _profileNameCtrl.text = _agencyTenant!.name;
    _profileOwnerCtrl.text = _agencyTenant!.ownerName ?? '';
    _profileEmailCtrl.text = _agencyTenant!.email ?? '';
    _profilePhoneCtrl.text = _agencyTenant!.phone ?? '';
    _profileLicenseCtrl.text = _agencyTenant!.businessLicenseNo ?? '';
    _profileColorHex = _agencyTenant!.themeColorHex;
    _profileInitialized = true;
  }

  String _staffName(String uid) =>
      _staff.where((s) => s.uid == uid).map((s) => s.name).firstOrNull ?? uid;

  String _busNumber(String busId) =>
      _buses.where((b) => b.id == busId).map((b) => b.busNumber).firstOrNull ?? busId;

  void _logout() {
    try {
      context.read<AuthBloc>().add(AuthLogoutRequested());
      context.read<ThemeBloc>().add(ThemeReset());
    } catch (_) {}
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobileOrTablet = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: isMobileOrTablet
          ? AppBar(
              title: Text('${_navItems[_activeTabIndex]['title']}'),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 1,
              actions: [
                IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
              ],
            )
          : null,
      drawer: isMobileOrTablet ? _buildDrawer() : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (!isMobileOrTablet) _buildSidebar(),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMobileOrTablet) ...[
                          _buildDesktopHeader(),
                          const SizedBox(height: 24),
                        ],
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildActiveTabContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDesktopHeader() {
    String userName = 'Agency User';
    try {
      final name = context.watch<AuthBloc>().state.userName;
      if (name != null) userName = name;
    } catch (_) {}
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _navItems[_activeTabIndex]['title'] as String,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome back! Here is a summary of your agency metrics.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(userName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Material(
      color: Colors.white,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isSidebarCollapsed ? 80 : 250,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: _primaryColor, size: 28),
                  if (!_isSidebarCollapsed) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('AgencyPortal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _activeTabIndex == index;
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    selected: isSelected,
                    selectedTileColor: _primaryColor.withOpacity(0.08),
                    selectedColor: _primaryColor,
                    leading: Icon(item['icon'] as IconData, size: 18),
                    title: _isSidebarCollapsed
                        ? null
                        : Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onTap: () => setState(() => _activeTabIndex = index),
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(_isSidebarCollapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left),
              title: _isSidebarCollapsed ? null : const Text('Collapse Sidebar'),
              onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView.builder(
        itemCount: _navItems.length,
        itemBuilder: (context, index) {
          final item = _navItems[index];
          return ListTile(
            selected: _activeTabIndex == index,
            selectedColor: _primaryColor,
            leading: Icon(item['icon'] as IconData),
            title: Text(item['title'] as String),
            onTap: () {
              setState(() => _activeTabIndex = index);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildBusesTab();
      case 2:
        return _buildTripsTab();
      case 3:
        return _buildBookTicketTab();
      case 4:
        return _buildDriversTab();
      case 5:
        return _buildProfileTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab() {
    final liveTrips = _trips.where((t) => t.status == TripStatus.live).length;
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKPICard('Active Fleet', '${_buses.length} Buses', Icons.directions_bus, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildKPICard('Live Trips Now', '$liveTrips Trips Live', Icons.cell_tower, Colors.blue)),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Booking Revenue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 24),
                  SizedBox(height: 300, child: _buildRevenueChart()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12), overflow: TextOverflow.ellipsis),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][v.toInt() % 7]),
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 300), FlSpot(1, 450), FlSpot(2, 400),
              FlSpot(3, 650), FlSpot(4, 800), FlSpot(5, 750), FlSpot(6, 950),
            ],
            isCurved: true,
            color: _primaryColor,
            barWidth: 4,
            belowBarData: BarAreaData(show: true, color: _primaryColor.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBusesTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bus Fleet Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Bus'),
                  onPressed: _showAddBusDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Bus ID')),
                    DataColumn(label: Text('Number Plate')),
                    DataColumn(label: Text('Capacity')),
                    DataColumn(label: Text('Layout')),
                  ],
                  rows: _buses.map((bus) {
                    return DataRow(cells: [
                      DataCell(Text(bus.id)),
                      DataCell(Text(bus.busNumber)),
                      DataCell(Text('${bus.totalSeats} seats')),
                      DataCell(Text(bus.layoutType == BusLayoutType.sleeper ? 'Sleeper (2x1)' : 'Seater (2x2)')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trip Schedules & Crew Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule Trip'),
                  onPressed: _showScheduleTripDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Trip ID')),
                    DataColumn(label: Text('Route')),
                    DataColumn(label: Text('Bus')),
                    DataColumn(label: Text('Driver')),
                    DataColumn(label: Text('Conductor')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: _trips.map((trip) {
                    Color chipColor = switch (trip.status) {
                      TripStatus.live => Colors.green,
                      TripStatus.scheduled => Colors.blue,
                      TripStatus.completed => Colors.grey,
                    };
                    return DataRow(cells: [
                      DataCell(Text(trip.id)),
                      DataCell(Text(trip.routeId)),
                      DataCell(Text(_busNumber(trip.busId))),
                      DataCell(Text(_staffName(trip.driverId))),
                      DataCell(Text(_staffName(trip.conductorId))),
                      DataCell(Chip(
                        label: Text(trip.status.name.toUpperCase(), style: TextStyle(color: chipColor, fontSize: 10)),
                        backgroundColor: chipColor.withOpacity(0.1),
                        side: BorderSide.none,
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversTab() {
    final drivers = _staff.where((s) => s.role == UserRole.driver).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Agency Driver Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add New Driver'),
                  onPressed: _showAddDriverDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: drivers.isEmpty
                  ? Center(
                      child: Text('No drivers added yet for this agency', style: TextStyle(color: Colors.grey.shade500)),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('License Number')),
                            DataColumn(label: Text('Vehicle Details')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: drivers.map((driver) {
                            return DataRow(cells: [
                              DataCell(Text(driver.name)),
                              DataCell(Text(driver.phone)),
                              DataCell(Text(driver.email ?? 'N/A')),
                              DataCell(Text(driver.licenseNumber ?? 'N/A')),
                              DataCell(Text(driver.vehicleDetails ?? 'N/A')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remove Driver?'),
                                        content: const Text('Are you sure you want to remove this driver?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirestoreService.instance.deleteStaff(driver.uid);
                                      _loadData();
                                    }
                                  },
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    _initProfileFields();
    if (_agencyTenant == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Manage Agency Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text('Update your agency details and customize the dashboard branding theme.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _profileNameCtrl,
                    decoration: const InputDecoration(labelText: 'Agency Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _profileOwnerCtrl,
                    decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _profileEmailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _profilePhoneCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Phone Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _profileLicenseCtrl,
                    decoration: const InputDecoration(labelText: 'Business License Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),

                  // Color Selector
                  DropdownButtonFormField<String>(
                    value: _profileColorHex,
                    decoration: const InputDecoration(labelText: 'Branding Theme Color', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '#3F51B5', child: Text('Indigo')),
                      DropdownMenuItem(value: '#009688', child: Text('Teal')),
                      DropdownMenuItem(value: '#E91E63', child: Text('Pink')),
                      DropdownMenuItem(value: '#FF5722', child: Text('Orange')),
                      DropdownMenuItem(value: '#4CAF50', child: Text('Green')),
                      DropdownMenuItem(value: '#2196F3', child: Text('Blue')),
                      DropdownMenuItem(value: '#9C27B0', child: Text('Purple')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _profileColorHex = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                      onPressed: () async {
                        final updated = _agencyTenant!.copyWith(
                          name: _profileNameCtrl.text.trim(),
                          ownerName: _profileOwnerCtrl.text.trim(),
                          email: _profileEmailCtrl.text.trim(),
                          phone: _profilePhoneCtrl.text.trim(),
                          businessLicenseNo: _profileLicenseCtrl.text.trim(),
                          themeColorHex: _profileColorHex,
                        );

                        await FirestoreService.instance.saveTenant(updated);

                        if (mounted) {
                          setState(() {
                            _agencyTenant = updated;
                          });

                          // Dynamically update the app theme color
                          final color = TenantThemeLoader.hexToColor(_profileColorHex);
                          context.read<ThemeBloc>().add(ThemeLoadTenant(
                            color: color,
                            tenantName: updated.name,
                          ));

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile and Theme Color saved successfully!')),
                          );
                        }
                      },
                      child: const Text('Save Profile & Theme Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDriverDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: '1234');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Driver (નવો ડ્રાઇવર ઉમેરો)'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Driver Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: licenseCtrl,
                    decoration: const InputDecoration(labelText: 'Driver License No. *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vehicleCtrl,
                    decoration: const InputDecoration(labelText: 'Vehicle Details (e.g. GJ-05-AB-1234) *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: 'PIN/Password (4 digits) *', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || licenseCtrl.text.trim().isEmpty || vehicleCtrl.text.trim().isEmpty) return;

                final driverId = 'S${DateTime.now().millisecondsSinceEpoch % 100000}';
                final driver = UserStaff(
                  uid: driverId,
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  role: UserRole.driver,
                  tenantId: _tenantId,
                  email: emailCtrl.text.trim(),
                  licenseNumber: licenseCtrl.text.trim(),
                  vehicleDetails: vehicleCtrl.text.trim(),
                  status: 'approved',
                );

                await FirestoreService.instance.saveStaffWithPin(driver, passwordCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Save Driver'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBusDialog() {
    final numberCtrl = TextEditingController();
    final seatsCtrl = TextEditingController(text: '36');
    var layout = BusLayoutType.sleeper;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Bus'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Number Plate (GJ-05-XX-XXXX)'),
                ),
                TextField(
                  controller: seatsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Seats'),
                ),
                DropdownButtonFormField<BusLayoutType>(
                  value: layout,
                  decoration: const InputDecoration(labelText: 'Layout Type'),
                  items: BusLayoutType.values
                      .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => layout = v ?? BusLayoutType.sleeper),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final bus = Bus(
                  id: 'B${DateTime.now().millisecondsSinceEpoch % 10000}',
                  busNumber: numberCtrl.text.trim(),
                  tenantId: _tenantId,
                  totalSeats: int.tryParse(seatsCtrl.text) ?? 36,
                  layoutType: layout,
                );
                await FirestoreService.instance.addBus(bus);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Save Bus'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleTripDialog() {
    String? busId = _buses.isNotEmpty ? _buses.first.id : null;
    String? driverId = _staff.where((s) => s.role == UserRole.driver).map((s) => s.uid).firstOrNull;
    String? conductorId = _staff.where((s) => s.role == UserRole.conductor).map((s) => s.uid).firstOrNull;
    var status = TripStatus.scheduled;

    final drivers = _staff.where((s) => s.role == UserRole.driver).toList();
    final conductors = _staff.where((s) => s.role == UserRole.conductor).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Schedule Trip & Assign Crew'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: busId,
                  decoration: const InputDecoration(labelText: 'Select Bus'),
                  items: _buses.map((b) => DropdownMenuItem(value: b.id, child: Text(b.busNumber))).toList(),
                  onChanged: (v) => setDialogState(() => busId = v),
                ),
                DropdownButtonFormField<String>(
                  value: driverId,
                  decoration: const InputDecoration(labelText: 'Assign Driver'),
                  items: drivers.map((d) => DropdownMenuItem(value: d.uid, child: Text(d.name))).toList(),
                  onChanged: (v) => setDialogState(() => driverId = v),
                ),
                DropdownButtonFormField<String>(
                  value: conductorId,
                  decoration: const InputDecoration(labelText: 'Assign Conductor'),
                  items: conductors.map((c) => DropdownMenuItem(value: c.uid, child: Text(c.name))).toList(),
                  onChanged: (v) => setDialogState(() => conductorId = v),
                ),
                DropdownButtonFormField<TripStatus>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Trip Status'),
                  items: TripStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => status = v ?? TripStatus.scheduled),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (busId == null || driverId == null) return;
                final trip = Trip(
                  id: 'TR${DateTime.now().millisecondsSinceEpoch % 10000}',
                  tenantId: _tenantId,
                  busId: busId!,
                  driverId: driverId!,
                  conductorId: conductorId ?? '',
                  routeId: 'RT001',
                  status: status,
                  startDateTime: DateTime.now(),
                );
                await FirestoreService.instance.addTrip(trip);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Schedule Trip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookTicketTab() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Generate Ticket / QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text('Book ticket with boarding/drop points and generate tracking QR.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TicketBookingForm(tenantId: _tenantId, themeColor: _primaryColor, onTicketBooked: _loadData),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
