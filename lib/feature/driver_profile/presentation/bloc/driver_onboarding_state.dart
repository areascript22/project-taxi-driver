part of 'driver_onboarding_bloc.dart';

@immutable
class DriverOnboardingState {
  final UserEntity? user;
  final File? profileImage;
  final bool isPickingImage;
  final bool isSubmitting;
  final String? errorMessage;
  final bool registrationSuccess;

  const DriverOnboardingState({
    this.user,
    this.profileImage,
    this.isPickingImage = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.registrationSuccess = false,
  });

  DriverOnboardingState copyWith({
    UserEntity? user,
    File? profileImage,
    bool? isPickingImage,
    bool? isSubmitting,
    String? errorMessage,
    bool? registrationSuccess,
  }) {
    return DriverOnboardingState(
      user: user ?? this.user,
      profileImage: profileImage ?? this.profileImage,
      isPickingImage: isPickingImage ?? this.isPickingImage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
    );
  }
}
