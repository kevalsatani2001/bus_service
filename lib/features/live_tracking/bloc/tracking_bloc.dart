import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bus_service/features/live_tracking/services/driver_tracking_service.dart';

// Events
abstract class TrackingEvent {}

class TrackingStartRequested extends TrackingEvent {
  final String tripId;
  TrackingStartRequested(this.tripId);
}

class TrackingStopRequested extends TrackingEvent {}

class TrackingCheckStatusRequested extends TrackingEvent {}

// State
class TrackingState {
  final bool isTrackingActive;
  final String? tripId;
  final String? errorMessage;

  TrackingState({
    required this.isTrackingActive,
    this.tripId,
    this.errorMessage,
  });

  factory TrackingState.initial() => TrackingState(isTrackingActive: false);

  TrackingState copyWith({
    bool? isTrackingActive,
    String? tripId,
    String? errorMessage,
  }) {
    return TrackingState(
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      tripId: tripId ?? this.tripId,
      errorMessage: errorMessage,
    );
  }
}

// BLoC
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  TrackingBloc() : super(TrackingState.initial()) {
    on<TrackingStartRequested>((event, emit) async {
      final success = await DriverTrackingService.startTracking(event.tripId);
      if (success) {
        emit(TrackingState(isTrackingActive: true, tripId: event.tripId));
      } else {
        emit(TrackingState(
          isTrackingActive: false,
          errorMessage: 'Failed to request GPS permissions or start tracking service.',
        ));
      }
    });

    on<TrackingStopRequested>((event, emit) async {
      await DriverTrackingService.stopTracking();
      emit(TrackingState(isTrackingActive: false));
    });

    on<TrackingCheckStatusRequested>((event, emit) async {
      final active = await DriverTrackingService.isTrackingActive();
      emit(state.copyWith(
        isTrackingActive: active,
        tripId: active ? state.tripId : null,
      ));
    });
  }
}
