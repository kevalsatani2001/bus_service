import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/models/models.dart';
import 'package:bus_service/core/services/auth_service.dart';
import 'package:bus_service/core/services/firestore_service.dart';

/// Shared login & registration UI used by Admin, Agency, and Driver portals.
class RoleLoginScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final UserRole expectedRole;
  final String successRoute;
  final List<UserRole>? alsoAllowRoles;

  const RoleLoginScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.expectedRole,
    required this.successRoute,
    this.alsoAllowRoles,
  });

  @override
  State<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends State<RoleLoginScreen> {
  // Login Controllers
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  
  // Agency Registration Controllers
  final _agencyNameController = TextEditingController();
  final _agencyOwnerController = TextEditingController();
  final _agencyEmailController = TextEditingController();
  final _agencyPhoneController = TextEditingController();
  final _agencyLicenseController = TextEditingController();
  final _agencyPasswordController = TextEditingController();

  // Driver Registration Controllers
  final _driverNameController = TextEditingController();
  final _driverEmailController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  final _driverVehicleController = TextEditingController();
  final _driverPasswordController = TextEditingController();

  // Admin Registration Controllers
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  // UI state
  bool _isRegister = false;
  bool _loading = false;
  bool _obscurePin = true;
  String? _error;
  
  // Driver agency selection state
  List<Tenant> _approvedAgencies = [];
  bool _loadingAgencies = false;
  String? _selectedAgencyId;

  @override
  void initState() {
    super.initState();
    if (widget.expectedRole == UserRole.driver) {
      _loadAgencies();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _agencyNameController.dispose();
    _agencyOwnerController.dispose();
    _agencyEmailController.dispose();
    _agencyPhoneController.dispose();
    _agencyLicenseController.dispose();
    _agencyPasswordController.dispose();
    _driverNameController.dispose();
    _driverEmailController.dispose();
    _driverPhoneController.dispose();
    _driverLicenseController.dispose();
    _driverVehicleController.dispose();
    _driverPasswordController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAgencies() async {
    setState(() => _loadingAgencies = true);
    try {
      final list = await FirestoreService.instance.getTenants();
      if (mounted) {
        setState(() {
          _approvedAgencies = list.where((t) => t.status == 'approved' || t.isActive).toList();
          _loadingAgencies = false;
          if (_approvedAgencies.isNotEmpty) {
            _selectedAgencyId = _approvedAgencies.first.id;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAgencies = false);
    }
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() => _error = 'કૃપા કરીને ફોન નંબર અને પિન દાખલ કરો (Please fill all fields)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bloc = context.read<AuthBloc>();
      final errMsg = await bloc.loginWithCredentials(
        phone: phone,
        pin: pin,
        expectedRole: widget.expectedRole,
      );

      if (!mounted) return;

      if (errMsg != null) {
        setState(() {
          _loading = false;
          _error = errMsg;
        });
      } else {
        context.go(widget.successRoute);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'લોગિન નિષ્ફળ: ${e.toString()}';
      });
    }
  }

  Future<void> _registerAgency() async {
    final agencyName = _agencyNameController.text.trim();
    final ownerName = _agencyOwnerController.text.trim();
    final email = _agencyEmailController.text.trim();
    final phone = _agencyPhoneController.text.trim();
    final license = _agencyLicenseController.text.trim();
    final password = _agencyPasswordController.text.trim();

    if (agencyName.isEmpty || ownerName.isEmpty || phone.isEmpty || license.isEmpty || password.isEmpty) {
      setState(() => _error = 'કૃપા કરીને બધી જરૂરી વિગતો ભરો (Please fill required fields)');
      return;
    }
    if (phone.length < 10) {
      setState(() => _error = 'મોબાઈલ નંબર ૧૦ અંકનો હોવો જોઈએ (Phone must be 10 digits)');
      return;
    }
    if (password.length < 4) {
      setState(() => _error = 'પાસવર્ડ ઓછામાં ઓછો ૪ અંકનો હોવો જોઈએ (Password min 4 chars)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tenantId = 'T${DateTime.now().millisecondsSinceEpoch % 100000}';
      final agentId = 'A${DateTime.now().millisecondsSinceEpoch % 100000}';

      final tenant = Tenant(
        id: tenantId,
        name: agencyName,
        ownerName: ownerName,
        email: email,
        phone: phone,
        businessLicenseNo: license,
        themeColorHex: '#3F51B5', // Default Indigo
        isActive: false, // Pending approval
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final agent = UserStaff(
        uid: agentId,
        name: ownerName,
        phone: phone,
        role: UserRole.agent,
        tenantId: tenantId,
        email: email,
      );

      await FirestoreService.instance.saveTenant(tenant);
      await FirestoreService.instance.saveStaffWithPin(agent, password);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _isRegister = false;
        _phoneController.text = phone;
        _pinController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('એજન્સી રજીસ્ટ્રેશન સફળ! સુપર એડમિન મંજૂરી માટે બાકી છે (Agency pending Admin approval)'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 6),
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'નોંધણી નિષ્ફળ: ${e.toString()}';
      });
    }
  }

  Future<void> _registerDriver() async {
    final name = _driverNameController.text.trim();
    final email = _driverEmailController.text.trim();
    final phone = _driverPhoneController.text.trim();
    final license = _driverLicenseController.text.trim();
    final vehicle = _driverVehicleController.text.trim();
    final password = _driverPasswordController.text.trim();
    final tenantId = _selectedAgencyId;

    if (name.isEmpty || phone.isEmpty || license.isEmpty || vehicle.isEmpty || password.isEmpty || tenantId == null) {
      setState(() => _error = 'કૃપા કરીને બધી જરૂરી વિગતો ભરો (Please fill required fields)');
      return;
    }
    if (phone.length < 10) {
      setState(() => _error = 'મોબાઈલ નંબર ૧૦ અંકનો હોવો જોઈએ (Phone must be 10 digits)');
      return;
    }
    if (password.length < 4) {
      setState(() => _error = 'પાસવર્ડ ઓછામાં ઓછો ૪ અંકનો હોવો જોઈએ (Password min 4 chars)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final driverId = 'S${DateTime.now().millisecondsSinceEpoch % 100000}';

      final driver = UserStaff(
        uid: driverId,
        name: name,
        phone: phone,
        role: UserRole.driver,
        tenantId: tenantId,
        email: email,
        licenseNumber: license,
        vehicleDetails: vehicle,
        status: 'approved', // Auto active
      );

      await FirestoreService.instance.saveStaffWithPin(driver, password);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _isRegister = false;
        _phoneController.text = phone;
        _pinController.text = password;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ડ્રાઈવર નોંધણી સફળ! હવે તમે લોગિન કરી શકો છો (Driver registered successfully)'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'નોંધણી નિષ્ફળ: ${e.toString()}';
      });
    }
  }

  Future<void> _registerAdmin() async {
    final name = _adminNameController.text.trim();
    final email = _adminEmailController.text.trim();
    final phone = _adminPhoneController.text.trim();
    final password = _adminPasswordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _error = 'કૃપા કરીને બધી જરૂરી વિગતો ભરો (Please fill required fields)');
      return;
    }
    if (phone.length < 10) {
      setState(() => _error = 'મોબાઈલ નંબર ૧૦ અંકનો હોવો જોઈએ (Phone must be 10 digits)');
      return;
    }
    if (password.length < 4) {
      setState(() => _error = 'પાસવર્ડ ઓછામાં ઓછો ૪ અંકનો હોવો જોઈએ (Password min 4 chars)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final adminId = 'AD${DateTime.now().millisecondsSinceEpoch % 100000}';

      final adminStaff = UserStaff(
        uid: adminId,
        name: name,
        phone: phone,
        role: UserRole.admin,
        tenantId: '',
        email: email,
        status: 'approved',
      );

      await FirestoreService.instance.saveStaffWithPin(adminStaff, password);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _isRegister = false;
        _phoneController.text = phone;
        _pinController.text = password;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('સુપર એડમિન નોંધણી સફળ! (Super Admin registered successfully)'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'નોંધણી નિષ્ફળ: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.accentColor.withOpacity(0.08), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: widget.accentColor.withOpacity(0.15),
                      child: Icon(widget.icon, size: 36, color: widget.accentColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRegister ? 'નવી નોંધણી (Register)' : widget.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegister 
                          ? 'કૃપા કરીને ખાતું બનાવવા માટે માહિતી ભરો' 
                          : widget.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    
                    Card(
                      elevation: 4,
                      shadowColor: widget.accentColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildToggle(),
                            
                            // Error message
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _isRegister ? _buildRegisterForm() : _buildLoginForm(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _isRegister = false;
                _error = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isRegister ? widget.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Login (લોગિન)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: !_isRegister ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isRegister = true;
                  _error = null;
                });
                if (widget.expectedRole == UserRole.driver && _approvedAgencies.isEmpty) {
                  _loadAgencies();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isRegister ? widget.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Register (નોંધણી)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isRegister ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Number (મોબાઇલ)',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'PIN / Password (૪ અંક)',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            suffixIcon: IconButton(
              icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _loading ? null : _login,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Login (લોગિન)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    if (widget.expectedRole == UserRole.agent) {
      return _buildAgencyRegisterForm();
    } else if (widget.expectedRole == UserRole.driver) {
      return _buildDriverRegisterForm();
    } else if (widget.expectedRole == UserRole.admin) {
      return _buildAdminRegisterForm();
    }
    return const SizedBox.shrink();
  }

  Widget _buildAgencyRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _agencyNameController,
          decoration: const InputDecoration(
            labelText: 'Agency Name (એજન્સી નામ) *',
            prefixIcon: Icon(Icons.business_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _agencyOwnerController,
          decoration: const InputDecoration(
            labelText: 'Owner Name (માલિકનું નામ) *',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _agencyEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address (ઈમેલ) *',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _agencyPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number (મોબાઈલ) *',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _agencyLicenseController,
          decoration: const InputDecoration(
            labelText: 'Business License No. (લાઈસન્સ) *',
            prefixIcon: Icon(Icons.badge_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _agencyPasswordController,
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Password / PIN (૪+ અંક) *',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            suffixIcon: IconButton(
              icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _loading ? null : _registerAgency,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Register Agency (નોંધણી કરો)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverRegisterForm() {
    if (_loadingAgencies) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_approvedAgencies.isEmpty) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'રજીસ્ટ્રેશન કરવા માટે કોઈ મંજૂર એજન્સી ઉપલબ્ધ નથી. કૃપા કરીને સુપર એડમિનનો સંપર્ક કરો.\n(No approved agencies available. Please contact Super Admin.)',
              style: TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _loadAgencies,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry (ફરી પ્રયાસ કરો)'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _driverNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name (આખું નામ) *',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _driverEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address (ઈમેલ) *',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _driverPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number (મોબાઈલ) *',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _driverLicenseController,
          decoration: const InputDecoration(
            labelText: 'Driver License Number (લાઈસન્સ) *',
            prefixIcon: Icon(Icons.card_membership_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _driverVehicleController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Number & Details (વાહન વિગત) *',
            prefixIcon: Icon(Icons.directions_bus_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedAgencyId,
          decoration: const InputDecoration(
            labelText: 'Select Agency (એજન્સી પસંદ કરો) *',
            prefixIcon: Icon(Icons.business_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          items: _approvedAgencies.map((t) {
            return DropdownMenuItem<String>(
              value: t.id,
              child: Text(t.name),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedAgencyId = val;
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _driverPasswordController,
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Password / PIN (૪+ અંક) *',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            suffixIcon: IconButton(
              icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _loading ? null : _registerDriver,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Register Driver (નોંધણી કરો)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _adminNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name (પૂરું નામ) *',
            prefixIcon: Icon(Icons.person_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _adminEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address (ઈમેલ) (વૈકલ્પિક)',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _adminPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number (મોબાઈલ) *',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _adminPasswordController,
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Password / PIN (૪+ અંક) *',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            suffixIcon: IconButton(
              icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _loading ? null : _registerAdmin,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Register Admin (નોંધણી)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
