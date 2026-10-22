part of 'driver_onboarding_bloc.dart';

@immutable
sealed class DriverOnboardingEvent {}

class DriverOnboardingStarted extends DriverOnboardingEvent {
  final UserEntity user;

  DriverOnboardingStarted(this.user);
}

class DriverOnboardingImagePicked extends DriverOnboardingEvent {
  final ProfileImageSource source;

  DriverOnboardingImagePicked(this.source);
}

class DriverOnboardingSubmitted extends DriverOnboardingEvent {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String registrationNumber;

  DriverOnboardingSubmitted({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.registrationNumber,
  });
}
