import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bus_service/features/live_tracking/bloc/tracking_bloc.dart';

/// A clean UI overlay wrapper for the Driver Screen.
/// Embellished with status indications and localized Gujarati buttons.
class DriverControlPanel extends StatelessWidget {
  /// The driver home screen content widget.
  final Widget child;

  /// The active trip ID being verified/tracked.
  final String tripId;

  const DriverControlPanel({
    super.key,
    required this.child,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrackingBloc, TrackingState>(
      listenWhen: (previous, current) => current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Underlying driver control page
            Positioned.fill(
              child: child,
            ),

            // Persistent overlay controls panel at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: BlocBuilder<TrackingBloc, TrackingState>(
                      builder: (context, state) {
                        final isActive = state.isTrackingActive;

                        return Row(
                          children: [
                            // 1. Status Indicator
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? Colors.green.shade500 : Colors.grey.shade400,
                                boxShadow: [
                                  if (isActive)
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 2. Localized Status Metadata
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isActive ? 'લાઇવ ટ્રેકિંગ ચાલુ છે' : 'ટ્રેકિંગ બંધ છે',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ટ્રિપ (Trip): $tripId',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. Control Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive ? Colors.red.shade600 : Colors.teal.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 3,
                              ),
                              onPressed: () {
                                if (isActive) {
                                  context.read<TrackingBloc>().add(TrackingStopRequested());
                                } else {
                                  context.read<TrackingBloc>().add(TrackingStartRequested(tripId));
                                }
                              },
                              icon: Icon(
                                isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                size: 20,
                              ),
                              label: Text(
                                isActive ? 'ટ્રેકિંગ બંધ કરો' : 'ટ્રેકિંગ શરૂ કરો',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
