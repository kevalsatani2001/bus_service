import 'package:flutter/material.dart';
import 'package:bus_service/core/models/models.dart';
import 'package:bus_service/core/services/firestore_service.dart';

/// Digital passenger chart — shows boarding/drop wise passenger list for conductor.
class PassengerChartScreen extends StatelessWidget {
  final String tripId;

  const PassengerChartScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Passenger Chart (ડિજિટલ ચાર્ટ)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Ticket>>(
        stream: FirestoreService.instance.watchTripTickets(tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return const Center(child: Text('No passengers booked for this trip.'));
          }

          final byBoarding = <String, List<Ticket>>{};
          final byDrop = <String, List<Ticket>>{};

          for (final t in tickets) {
            byBoarding.putIfAbsent(t.boardingPoint.isEmpty ? 'Unknown' : t.boardingPoint, () => []).add(t);
            byDrop.putIfAbsent(t.dropPoint.isEmpty ? 'Unknown' : t.dropPoint, () => []).add(t);
          }

          final scanned = tickets.where((t) => t.isScanned).length;

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.indigo.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statChip('Total', '${tickets.length}', Colors.blue),
                      _statChip('Boarded', '$scanned', Colors.green),
                      _statChip('Pending', '${tickets.length - scanned}', Colors.orange),
                    ],
                  ),
                ),
                const TabBar(
                  labelColor: Colors.indigo,
                  tabs: [
                    Tab(text: 'Boarding Point Wise (બેસવાનું)'),
                    Tab(text: 'Drop Village Wise (ઉતરવાનું)'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildGroupedList(context, byBoarding),
                      _buildGroupedList(context, byDrop),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildGroupedList(BuildContext context, Map<String, List<Ticket>> grouped) {
    final keys = grouped.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final point = keys[index];
        final passengers = grouped[point]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              child: Text('${passengers.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(point, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${passengers.length} passengers'),
            children: passengers.map((t) {
              return ListTile(
                dense: true,
                leading: Icon(
                  t.isScanned ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: t.isScanned ? Colors.green : Colors.grey,
                  size: 20,
                ),
                title: Text(t.passengerName),
                subtitle: Text('${t.passengerPhone} • Seat ${t.seatNumber}'),
                trailing: t.isScanned
                    ? const Chip(label: Text('Boarded', style: TextStyle(fontSize: 10)), backgroundColor: Color(0xFFE8F5E9))
                    : const Chip(label: Text('Pending', style: TextStyle(fontSize: 10)), backgroundColor: Color(0xFFFFF3E0)),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
