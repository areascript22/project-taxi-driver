part of 'profile_bloc.dart';

@immutable
sealed class ProfileEvent {}

class ProfileLoadRequested extends ProfileEvent {
  final String driverId;

  ProfileLoadRequested({required this.driverId});
}
