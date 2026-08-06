part of 'trip_bloc.dart';

@immutable
sealed class TripEvent {}

class StartWatchingTrip extends TripEvent {
  final String passengerId;

  StartWatchingTrip({required this.passengerId});
}

class _TripStatusUpdated extends TripEvent {
  final TripStatusEntity data;

  _TripStatusUpdated(this.data);
}

class CancelTripRequested extends TripEvent {
  final String passengerId;

  CancelTripRequested({required this.passengerId});
}

class StopWatchingTrip extends TripEvent {}
