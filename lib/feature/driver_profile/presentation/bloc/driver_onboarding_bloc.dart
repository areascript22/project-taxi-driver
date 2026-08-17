import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../../../shared/image_picker/service/profile_image_picker_service.dart';
import '../../domain/entity/driver_entity.dart';
import '../../domain/entity/vehicle_entity.dart';
import '../../domain/repository/driver_profile_repository.dart';

part 'driver_onboarding_event.dart';
part 'driver_onboarding_state.dart';

class DriverOnboardingBloc
    extends Bloc<DriverOnboardingEvent, DriverOnboardingState> {
  final DriverProfileRepository driverProfileRepository;
  final ProfileImagePickerService imagePickerService;

  DriverOnboardingBloc({
    required this.driverProfileRepository,
    required this.imagePickerService,
  }) : super(const DriverOnboardingState()) {
    on<DriverOnboardingStarted>(_onStarted);
    on<DriverOnboardingImagePicked>(_onImagePicked);
    on<DriverOnboardingSubmitted>(_onSubmitted);
  }

  void _onStarted(
    DriverOnboardingStarted event,
    Emitter<DriverOnboardingState> emit,
  ) {
    emit(state.copyWith(user: event.user));
  }

  Future<void> _onImagePicked(
    DriverOnboardingImagePicked event,
    Emitter<DriverOnboardingState> emit,
  ) async {
    emit(state.copyWith(isPickingImage: true, errorMessage: null));

    final result = await imagePickerService.pickImage(source: event.source);

    result.fold(
      (failure) => emit(
        state.copyWith(isPickingImage: false, errorMessage: failure.message),
      ),
      (file) {
        if (file == null) {
          emit(state.copyWith(isPickingImage: false));
          return;
        }
        emit(state.copyWith(isPickingImage: false, profileImage: file));
      },
    );
  }

  Future<void> _onSubmitted(
    DriverOnboardingSubmitted event,
    Emitter<DriverOnboardingState> emit,
  ) async {
    final user = state.user;
    if (user == null) {
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final driver = DriverEntity(
      id: user.id,
      firstName: event.firstName,
      lastName: event.lastName,
      email: user.email ?? '',
      phoneNumber: event.phoneNumber,
      photoUrl: user.photoUrl,
    );

    final vehicle = VehicleEntity(
      vehicleId: '',
      driverId: user.id,
      plate: event.plate,
      brand: event.brand,
      model: event.model,
      year: event.year,
      color: event.color,
      registrationNumber: event.registrationNumber,
    );

    final result = await driverProfileRepository.registerDriver(
      driver: driver,
      vehicle: vehicle,
      profileImage: state.profileImage,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isSubmitting: false, errorMessage: failure.message),
      ),
      (_) => emit(
        state.copyWith(isSubmitting: false, registrationSuccess: true),
      ),
    );
  }
}
