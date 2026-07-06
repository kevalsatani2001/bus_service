import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/models/models.dart';
import 'package:bus_service/core/services/firestore_service.dart';
import 'package:bus_service/features/auth/presentation/role_login_screen.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleLoginScreen(
      title: 'Super Admin Login',
      subtitle: 'App owner panel — agencies, staff ane system manage karo',
      icon: Icons.admin_panel_settings_outlined,
      accentColor: Colors.deepPurple,
      expectedRole: UserRole.admin,
      successRoute: '/admin/dashboard',
    );
  }
}

class AgencyLoginScreen extends StatelessWidget {
  const AgencyLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleLoginScreen(
      title: 'Agency Login',
      subtitle: 'Booking office — ticket book karo, QR generate karo, trips manage karo',
      icon: Icons.storefront_outlined,
      accentColor: Colors.teal,
      expectedRole: UserRole.agent,
      successRoute: '/agency/dashboard',
      alsoAllowRoles: [UserRole.admin],
    );
  }
}

class DriverLoginScreen extends StatelessWidget {
  const DriverLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleLoginScreen(
      title: 'Driver / Conductor Login',
      subtitle: 'GPS tracking, passenger chart ane boarding verification',
      icon: Icons.settings_remote_outlined,
      accentColor: Colors.orange,
      expectedRole: UserRole.driver,
      successRoute: '/driver/home',
      alsoAllowRoles: [UserRole.conductor],
    );
  }
}

/// Super Admin dashboard — add agencies, staff, view platform stats.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tabIndex = 0;
  List<Tenant> _tenants = [];
  List<UserStaff> _allStaff = [];
  List<Ticket> _allTickets = [];
  bool _loading = true;

  // Filter states for driver management
  String? _selectedFilterAgencyId; // null = 'All Agencies'
  String _driverSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final fs = FirestoreService.instance;
    final results = await Future.wait([
      fs.getTenants(),
      fs.getAllStaff(),
      fs.getAllTickets(),
    ]);
    if (mounted) {
      setState(() {
        _tenants = results[0] as List<Tenant>;
        _allStaff = results[1] as List<UserStaff>;
        _allTickets = results[2] as List<Ticket>;
        _loading = false;
      });
    }
  }

  void _logout() {
    context.read<AuthBloc>().add(AuthLogoutRequested());
    context.go('/');
  }

  Future<void> _approveAgency(String tenantId) async {
    setState(() => _loading = true);
    await FirestoreService.instance.updateTenantStatus(tenantId, 'approved');
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('એજન્સી મંજૂર કરવામાં આવી છે! (Agency Approved)')),
      );
    }
  }

  Future<void> _blockAgency(String tenantId) async {
    setState(() => _loading = true);
    await FirestoreService.instance.updateTenantStatus(tenantId, 'blocked');
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('એજન્સી બ્લોક કરવામાં આવી છે! (Agency Blocked)')),
      );
    }
  }

  Future<void> _unblockAgency(String tenantId) async {
    setState(() => _loading = true);
    await FirestoreService.instance.updateTenantStatus(tenantId, 'approved');
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('એજન્સી અનબ્લોક કરવામાં આવી છે! (Agency Unblocked)')),
      );
    }
  }

  Future<void> _deleteAgency(String tenantId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Agency?'),
        content: const Text('Are you sure you want to delete this agency? All associated staff will also be deleted.'),
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
      setState(() => _loading = true);
      await FirestoreService.instance.deleteTenant(tenantId);
      await _load();
    }
  }

  Future<void> _deleteStaff(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('Are you sure you want to delete this driver/staff?'),
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
      setState(() => _loading = true);
      await FirestoreService.instance.deleteStaff(uid);
      await _load();
    }
  }

  Future<void> _showAddAgencyDialog() async {
    final nameCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: '1234');
    var colorHex = '#3F51B5';
    var autoApprove = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('નવી Agency ઉમેરો (Add Agency)'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Agency + booking office agent ek sathe create thase.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Agency Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ownerCtrl,
                    decoration: const InputDecoration(labelText: 'Owner Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone/Login Number *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: licenseCtrl,
                    decoration: const InputDecoration(labelText: 'Business License No. *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: 'PIN/Password *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: colorHex,
                    decoration: const InputDecoration(labelText: 'Theme Color', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '#3F51B5', child: Text('Indigo')),
                      DropdownMenuItem(value: '#009688', child: Text('Teal')),
                      DropdownMenuItem(value: '#E91E63', child: Text('Pink')),
                      DropdownMenuItem(value: '#FF5722', child: Text('Orange')),
                    ],
                    onChanged: (v) => setDialogState(() => colorHex = v ?? colorHex),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Auto-Approve Agency'),
                    subtitle: const Text('Directly activate agency'),
                    value: autoApprove,
                    onChanged: (v) => setDialogState(() => autoApprove = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || ownerCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || licenseCtrl.text.trim().isEmpty) return;
                
                final tenantId = 'T${DateTime.now().millisecondsSinceEpoch % 100000}';
                final agentId = 'A${DateTime.now().millisecondsSinceEpoch % 100000}';
                
                final tenant = Tenant(
                  id: tenantId,
                  name: nameCtrl.text.trim(),
                  ownerName: ownerCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  businessLicenseNo: licenseCtrl.text.trim(),
                  themeColorHex: colorHex,
                  isActive: autoApprove,
                  status: autoApprove ? 'approved' : 'pending',
                  createdAt: DateTime.now(),
                );
                
                final agent = UserStaff(
                  uid: agentId,
                  name: ownerCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  role: UserRole.agent,
                  tenantId: tenantId,
                  email: emailCtrl.text.trim(),
                );
                
                await FirestoreService.instance.saveTenant(tenant);
                await FirestoreService.instance.saveStaffWithPin(agent, passwordCtrl.text.trim());
                
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Create Agency'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStaffDialog() async {
    String? tenantId = _tenants.isNotEmpty ? _tenants.first.id : null;
    var role = UserRole.driver;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '1234');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('નવો ડ્રાઇવર / સ્ટાફ ઉમેરો (Add Driver/Staff)'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tenantId,
                    decoration: const InputDecoration(labelText: 'Agency', border: OutlineInputBorder()),
                    items: _tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) => setDialogState(() => tenantId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: UserRole.driver, child: Text('Driver')),
                      DropdownMenuItem(value: UserRole.conductor, child: Text('Conductor')),
                      DropdownMenuItem(value: UserRole.agent, child: Text('Agency Agent')),
                    ],
                    onChanged: (v) => setDialogState(() => role = v ?? UserRole.driver),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
                  if (role == UserRole.driver) ...[
                    const SizedBox(height: 12),
                    TextField(controller: licenseCtrl, decoration: const InputDecoration(labelText: 'License Number *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number *', border: OutlineInputBorder())),
                  ],
                  const SizedBox(height: 12),
                  TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN/Password *', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (tenantId == null || phoneCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                if (role == UserRole.driver && (licenseCtrl.text.trim().isEmpty || vehicleCtrl.text.trim().isEmpty)) return;
                
                final staff = UserStaff(
                  uid: 'S${DateTime.now().millisecondsSinceEpoch % 100000}',
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  role: role,
                  tenantId: tenantId!,
                  email: emailCtrl.text.trim(),
                  licenseNumber: role == UserRole.driver ? licenseCtrl.text.trim() : null,
                  vehicleDetails: role == UserRole.driver ? vehicleCtrl.text.trim() : null,
                  status: 'approved',
                );
                
                await FirestoreService.instance.saveStaffWithPin(staff, pinCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Save Staff'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userName = 'Admin';
    try {
      final name = context.watch<AuthBloc>().state.userName;
      if (name != null) userName = name;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Panel'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text(userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _tabIndex,
                  onDestinationSelected: (i) => setState(() => _tabIndex = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Overview')),
                    NavigationRailDestination(icon: Icon(Icons.business_outlined), label: Text('Agencies')),
                    NavigationRailDestination(icon: Icon(Icons.people_outline), label: Text('Drivers')),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildTab()),
              ],
            ),
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddAgencyDialog,
              icon: const Icon(Icons.add_business),
              label: const Text('Add Agency'),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            )
          : _tabIndex == 2
              ? FloatingActionButton.extended(
                  onPressed: _showAddStaffDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Staff/Driver'),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                )
              : null,
    );
  }

  Widget _buildTab() {
    switch (_tabIndex) {
      case 0:
        return _overviewTab();
      case 1:
        return _agenciesTab();
      case 2:
        return _driverTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _overviewTab() {
    final totalDrivers = _allStaff.where((s) => s.role == UserRole.driver).length;
    final totalRevenue = _allTickets.length * 350;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tamari app no malik panel — ahiya thi badhi agencies ane staff manage karo.'),
          const SizedBox(height: 24),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard('Total Agencies', '${_tenants.length}', Icons.business, Colors.teal),
              _statCard('Total Drivers', '$totalDrivers', Icons.directions_bus, Colors.orange),
              _statCard('Total Bookings', '${_allTickets.length}', Icons.confirmation_number_outlined, Colors.blue),
              _statCard('Total Revenue', '₹$totalRevenue', Icons.currency_rupee, Colors.green),
            ],
          ),
          
          const SizedBox(height: 32),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Guide (માલિક માટે)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text('1. "Agencies" tab → pending એજન્સીઓ મંજૂર કરો અથવા નવી એજન્સી ઉમેરો (Mobile + Password)'),
                  const Text('2. "Drivers" tab → ડ્રાઇવર ની વિગતો જુઓ, એજન્સી દ્વારા ફિલ્ટર કરો'),
                  const Text('3. એજન્સી લોગિન કરી ને બસ અને બુકિંગ સેવાઓનું સંચાલન કરી શકે છે'),
                  const SizedBox(height: 16),
                  const Text('Demo credentials:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('• Admin Login: 9999999999 / 1234'),
                  const Text('• Agency Login: 8888888888 / 1234'),
                  const Text('• Driver Login: 7777777777 / 1234'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _agenciesTab() {
    final pendingAgencies = _tenants.where((t) => t.status == 'pending').toList();
    final approvedAgencies = _tenants.where((t) => t.status == 'approved' || t.isActive).toList();
    final blockedAgencies = _tenants.where((t) => t.status == 'blocked').toList();

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Agencies Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddAgencyDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Agency'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const TabBar(
              tabs: [
                Tab(text: 'Pending Approval'),
                Tab(text: 'Approved'),
                Tab(text: 'Blocked'),
              ],
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAgencyList(pendingAgencies, 'No pending approvals'),
                  _buildAgencyList(approvedAgencies, 'No approved agencies'),
                  _buildAgencyList(blockedAgencies, 'No blocked agencies'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyList(List<Tenant> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final t = list[index];
        final agencyStaff = _allStaff.where((s) => s.tenantId == t.id).toList();
        final agent = agencyStaff.where((s) => s.role == UserRole.agent).firstOrNull;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _parseColor(t.themeColorHex),
              child: Text(t.name.isNotEmpty ? t.name[0] : 'A', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${t.id} • Status: ${t.status.toUpperCase()}'),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Owner Name: ${t.ownerName ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Email: ${t.email ?? "N/A"}'),
                        Text('Phone/Login ID: ${t.phone ?? agent?.phone ?? "N/A"}'),
                        Text('License No: ${t.businessLicenseNo ?? "N/A"}'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${agencyStaff.length} Staff members'),
                      Text('Created: ${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}'),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (t.status == 'pending') ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _deleteAgency(t.id),
                      icon: const Icon(Icons.delete),
                      label: const Text('Reject & Delete'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _approveAgency(t.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ] else if (t.status == 'approved') ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                      onPressed: () => _blockAgency(t.id),
                      icon: const Icon(Icons.block),
                      label: const Text('Block'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _deleteAgency(t.id),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ] else if (t.status == 'blocked') ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _unblockAgency(t.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Unblock & Approve'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _deleteAgency(t.id),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ],
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _driverTab() {
    final drivers = _allStaff.where((s) => s.role == UserRole.driver).toList();

    // Filter drivers
    final filteredDrivers = drivers.where((d) {
      final matchesAgency = _selectedFilterAgencyId == null || d.tenantId == _selectedFilterAgencyId;
      final matchesSearch = d.name.toLowerCase().contains(_driverSearchQuery.toLowerCase()) || d.phone.contains(_driverSearchQuery);
      return matchesAgency && matchesSearch;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Drivers Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showAddStaffDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Driver'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String?>(
                  value: _selectedFilterAgencyId,
                  decoration: const InputDecoration(labelText: 'Filter by Agency', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Agencies (બધી એજન્સીઓ)')),
                    ..._tenants.where((t) => t.status == 'approved' || t.isActive).map((t) => DropdownMenuItem<String?>(
                          value: t.id,
                          child: Text(t.name),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedFilterAgencyId = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by Name or Phone',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _driverSearchQuery = val;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredDrivers.isEmpty
                ? const Center(child: Text('No drivers found matching criteria'))
                : ListView.builder(
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = filteredDrivers[index];
                      final agencyName = _tenants.where((t) => t.id == driver.tenantId).map((t) => t.name).firstOrNull ?? driver.tenantId;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(Icons.directions_bus, color: Colors.white),
                          ),
                          title: Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Phone: ${driver.phone} • Agency: $agencyName\nLicense: ${driver.licenseNumber ?? "N/A"} • Vehicle: ${driver.vehicleDetails ?? "N/A"}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteStaff(driver.uid),
                            tooltip: 'Remove Driver',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return Colors.indigo;
    }
  }
}
