import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bus_service/core/models/models.dart';
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

  Color get _primaryColor => widget.themeColor ?? Colors.indigo;

  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Overview/Stats', 'icon': Icons.analytics_outlined},
    {'title': 'Buses', 'icon': Icons.directions_bus_outlined},
    {'title': 'Trips', 'icon': Icons.route_outlined},
    {'title': 'Book Ticket / Generate QR', 'icon': Icons.qr_code_outlined},
  ];

  // Dummy fleet list
  final List<Bus> _dummyBuses = [
    Bus(id: 'B1', busNumber: 'DL-01-A-1234', tenantId: 'T1', totalSeats: 36, layoutType: BusLayoutType.sleeper),
    Bus(id: 'B2', busNumber: 'MH-12-PQ-5678', tenantId: 'T1', totalSeats: 45, layoutType: BusLayoutType.seater),
    Bus(id: 'B3', busNumber: 'KA-03-XY-9876', tenantId: 'T1', totalSeats: 30, layoutType: BusLayoutType.sleeper),
    Bus(id: 'B4', busNumber: 'UP-16-Z-5432', tenantId: 'T1', totalSeats: 48, layoutType: BusLayoutType.seater),
  ];

  // Dummy trips list
  final List<Trip> _dummyTrips = [
    Trip(
      id: 'TR001',
      tenantId: 'T1',
      busId: 'B1',
      driverId: 'D101',
      routeId: 'Delhi - Jaipur',
      status: TripStatus.live,
      startDateTime: DateTime.now(),
    ),
    Trip(
      id: 'TR002',
      tenantId: 'T1',
      busId: 'B2',
      driverId: 'D102',
      routeId: 'Mumbai - Pune',
      status: TripStatus.scheduled,
      startDateTime: DateTime.now().add(const Duration(hours: 4)),
    ),
    Trip(
      id: 'TR003',
      tenantId: 'T1',
      busId: 'B3',
      driverId: 'D103',
      routeId: 'Bangalore - Chennai',
      status: TripStatus.completed,
      startDateTime: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Breakpoint: 900px width for responsive adaptations.
    final bool isMobileOrTablet = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: isMobileOrTablet
          ? AppBar(
              title: Text('${_navItems[_activeTabIndex]['title']} - Agency Portal'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey.shade800,
              elevation: 1,
              iconTheme: IconThemeData(color: _primaryColor),
            )
          : null,
      drawer: isMobileOrTablet ? _buildDrawer() : null,
      body: Row(
        children: [
          // Render Desktop Sidebar only when width >= 900
          if (!isMobileOrTablet) _buildSidebar(),
          
          // Main Body Content
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Desktop page header
                  if (!isMobileOrTablet) ...[
                    _buildDesktopHeader(),
                    const SizedBox(height: 24),
                  ],
                  // Current active view
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
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Badge(
                label: Text('3'),
                child: Icon(Icons.notifications_none, size: 24),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 16),
            const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person_outline, color: Colors.white),
            ),
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
            // Sidebar Logo / Title
            Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment:
                  _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(Icons.directions_bus, color: _primaryColor, size: 28),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AgencyPortal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
            
            const Divider(height: 1),
            
            // Navigation links list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _activeTabIndex == index;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Tooltip(
                      message: _isSidebarCollapsed ? item['title'] as String : '',
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        selected: isSelected,
                        selectedTileColor: _primaryColor.withOpacity(0.08),
                        selectedColor: _primaryColor,
                        textColor: Colors.grey.shade600,
                        iconColor: Colors.grey.shade400,
                        leading: Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: isSelected ? _primaryColor : Colors.grey.shade500,
                        ),
                        title: _isSidebarCollapsed
                            ? null
                            : Text(
                                item['title'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                        onTap: () {
                          setState(() {
                            _activeTabIndex = index;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Sidebar Collapse trigger button
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                _isSidebarCollapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left,
                color: Colors.grey,
              ),
              title: _isSidebarCollapsed ? null : const Text('Collapse Sidebar', style: TextStyle(color: Colors.grey)),
              onTap: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: _primaryColor.withOpacity(0.05)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, color: _primaryColor, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Travel Agency Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _activeTabIndex == index;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: _primaryColor.withOpacity(0.08),
                  selectedColor: _primaryColor,
                  leading: Icon(item['icon'] as IconData, size: 16),
                  title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    setState(() {
                      _activeTabIndex = index;
                    });
                    Navigator.of(context).pop(); // Close drawer
                  },
                );
              },
            ),
          ),
        ],
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
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600 ? 1 : (screenWidth < 1200 ? 2 : 3);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary KPI Layout using responsive LayoutBuilder
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              if (width > 900) {
                return Row(
                  children: [
                    Expanded(child: _buildKPICard('Active Fleet', '4 Buses', Icons.directions_bus, Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKPICard("Today's Bookings", '184 Tickets', Icons.confirmation_number_outlined, Colors.amber)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKPICard('Live Trips Now', '2 Trips Live', Icons.cell_tower, Colors.blue)),
                  ],
                );
              } else if (width > 600) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildKPICard('Active Fleet', '4 Buses', Icons.directions_bus, Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildKPICard("Today's Bookings", '184 Tickets', Icons.confirmation_number_outlined, Colors.amber)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildKPICard('Live Trips Now', '2 Trips Live', Icons.cell_tower, Colors.blue)),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildKPICard('Active Fleet', '4 Buses', Icons.directions_bus, Colors.green),
                    const SizedBox(height: 16),
                    _buildKPICard("Today's Bookings", '184 Tickets', Icons.confirmation_number_outlined, Colors.amber),
                    const SizedBox(height: 16),
                    _buildKPICard('Live Trips Now', '2 Trips Live', Icons.cell_tower, Colors.blue),
                  ],
                );
              }
            },
          ),
          
          const SizedBox(height: 24),
          
          // fl_chart Weekly Revenue Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Booking Revenue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 4),
                  const Text('Revenue statistics for the current week (USD)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _buildRevenueChart(),
                  ),
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
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0: return const Text('Mon');
                  case 1: return const Text('Tue');
                  case 2: return const Text('Wed');
                  case 3: return const Text('Thu');
                  case 4: return const Text('Fri');
                  case 5: return const Text('Sat');
                  case 6: return const Text('Sun');
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 1000,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 300),
              FlSpot(1, 450),
              FlSpot(2, 400),
              FlSpot(3, 650),
              FlSpot(4, 800),
              FlSpot(5, 750),
              FlSpot(6, 950),
            ],
            isCurved: true,
            color: _primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: _primaryColor.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusesTab() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                  onPressed: () {},
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
                    DataColumn(label: Text('Bus Number')),
                    DataColumn(label: Text('Total Capacity')),
                    DataColumn(label: Text('Berth Layout')),
                    DataColumn(label: Text('Fleet Status')),
                  ],
                  rows: _dummyBuses.map((bus) {
                    return DataRow(cells: [
                      DataCell(Text(bus.id)),
                      DataCell(Text(bus.busNumber)),
                      DataCell(Text('${bus.totalSeats} seats')),
                      DataCell(Text(bus.layoutType == BusLayoutType.sleeper ? 'Sleeper (2x1)' : 'Seater (2x2)')),
                      DataCell(
                        Chip(
                          label: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 11)),
                          backgroundColor: Colors.green.shade50,
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        ),
                      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trip Schedules & Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule Trip'),
                  onPressed: () {},
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
                    DataColumn(label: Text('Bus Reference')),
                    DataColumn(label: Text('Driver ID')),
                    DataColumn(label: Text('Trip Status')),
                  ],
                  rows: _dummyTrips.map((trip) {
                    Color chipColor;
                    Color chipBg;
                    switch (trip.status) {
                      case TripStatus.live:
                        chipColor = Colors.green;
                        chipBg = Colors.green.shade50;
                        break;
                      case TripStatus.scheduled:
                        chipColor = Colors.blue;
                        chipBg = Colors.blue.shade50;
                        break;
                      case TripStatus.completed:
                        chipColor = Colors.grey;
                        chipBg = Colors.grey.shade100;
                        break;
                    }
                    return DataRow(cells: [
                      DataCell(Text(trip.id)),
                      DataCell(Text(trip.routeId)),
                      DataCell(Text(trip.busId)),
                      DataCell(Text(trip.driverId)),
                      DataCell(
                        Chip(
                          label: Text(trip.status.name.toUpperCase(), style: TextStyle(color: chipColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: chipBg,
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        ),
                      ),
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

  Widget _buildBookTicketTab() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Generate Ticket / QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text('Book ticket dynamically and dispatch hash coordinates.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  TicketBookingForm(
                    tenantId: 'T1',
                    themeColor: _primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
