import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/driver_profile/domain/entity/driver_entity.dart';
import 'package:driver_app/feature/driver_profile/domain/entity/vehicle_entity.dart';
import 'package:driver_app/feature/driver_profile/domain/repository/driver_profile_repository.dart';
import 'package:driver_app/feature/driver_profile/presentation/bloc/driver_onboarding_bloc.dart';
import 'package:driver_app/shared/domain/entity/user_entity.dart';
import 'package:driver_app/shared/image_picker/service/profile_image_picker_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDriverProfileRepository extends Mock
    implements DriverProfileRepository {}

class MockProfileImagePickerService extends Mock
    implements ProfileImagePickerService {}

class FakeFile extends Fake implements File {}

class FakeDriverEntity extends Fake implements DriverEntity {}

class FakeVehicleEntity extends Fake implements VehicleEntity {}

void main() {
  late MockDriverProfileRepository repository;
  late MockProfileImagePickerService imagePicker;

  final user = UserEntity(id: 'uid-1', email: 'a@b.com');

  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(FakeDriverEntity());
    registerFallbackValue(FakeVehicleEntity());
  });

  setUp(() {
    repository = MockDriverProfileRepository();
    imagePicker = MockProfileImagePickerService();
  });

  DriverOnboardingBloc buildBloc() => DriverOnboardingBloc(
    driverProfileRepository: repository,
    imagePickerService: imagePicker,
  );

  test('initial state has no user and no image', () {
    final bloc = buildBloc();
    expect(bloc.state.user, isNull);
    expect(bloc.state.profileImage, isNull);
    expect(bloc.state.registrationSuccess, isFalse);
  });

  group('DriverOnboardingStarted', () {
    blocTest<DriverOnboardingBloc, DriverOnboardingState>(
      'stores the user in state',
      build: buildBloc,
      act: (bloc) => bloc.add(DriverOnboardingStarted(user)),
      expect: () => [predicate<DriverOnboardingState>((s) => s.user == user)],
    );
  });

  group('DriverOnboardingImagePicked', () {
    blocTest<DriverOnboardingBloc, DriverOnboardingState>(
      'sets the picked file on success',
      setUp: () {
        when(
          () => imagePicker.pickImage(source: ProfileImageSource.gallery),
        ).thenAnswer((_) async => Right(FakeFile()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(DriverOnboardingImagePicked(ProfileImageSource.gallery)),
      expect: () => [
        predicate<DriverOnboardingState>((s) => s.isPickingImage),
        predicate<DriverOnboardingState>(
          (s) => !s.isPickingImage && s.profileImage != null,
        ),
      ],
    );

    blocTest<DriverOnboardingBloc, DriverOnboardingState>(
      'keeps profileImage null when the user cancels the picker',
      setUp: () {
        when(
          () => imagePicker.pickImage(source: ProfileImageSource.camera),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(DriverOnboardingImagePicked(ProfileImageSource.camera)),
      expect: () => [
        predicate<DriverOnboardingState>((s) => s.isPickingImage),
        predicate<DriverOnboardingState>(
          (s) => !s.isPickingImage && s.profileImage == null,
        ),
      ],
    );

    blocTest<DriverOnboardingBloc, DriverOnboardingState>(
      'reports an error message on failure',
      setUp: () {
        when(
          () => imagePicker.pickImage(source: ProfileImageSource.camera),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'permiso denegado')),
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(DriverOnboardingImagePicked(ProfileImageSource.camera)),
      expect: () => [
        predicate<DriverOnboardingState>((s) => s.isPickingImage),
        predicate<DriverOnboardingState>(
          (s) => !s.isPickingImage && s.errorMessage == 'permiso denegado',
        ),
      ],
    );
  });

  group('DriverOnboardingSubmitted', () {
    blocTest<DriverOnboardingBloc, DriverOnboardingState>(
      'does nothing when there is no user in state yet',
      build: buildBloc,
      act: (bloc) => bloc.add(
        DriverOnboardingSubmitted(
          firstName: 'A',
          lastName: 'B',
          phoneNumber: '123',
          plate: 'ABC123',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'red',
          registrationNumber: 'REG1',
        ),
      ),
      expect: () => [],
      verify: (_) {
        verifyNever(
          () => repository.registerDriver(
            driver: any(named: 'driver'),
            vehicle: any(named: 'vehicle'),
            profileImage: any(named: 'profileImage'),
          ),
        );
      },
    );

    blocTest<DriverOnboardingBloc, DriverOnboardingState>(
      'registers the driver and reports success',
      setUp: () {
        when(
          () => repository.registerDriver(
            driver: any(named: 'driver'),
            vehicle: any(named: 'vehicle'),
            profileImage: any(named: 'profileImage'),
          ),
        ).thenAnswer((_) async => Right(unit));
      },
      build: buildBloc,
      seed: () => DriverOnboardingState(user: user),
      act: (bloc) => bloc.add(
        DriverOnboardingSubmitted(
          firstName: 'A',
          lastName: 'B',
          phoneNumber: '123',
          plate: 'ABC123',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'red',
          registrationNumber: 'REG1',
        ),
      ),
      expect: () => [
        predicate<DriverOnboardingState>((s) => s.isSubmitting),
        predicate<DriverOnboardingState>(
          (s) => !s.isSubmitting && s.registrationSuccess,
        ),
      ],
    );

    blocTest<DriverOnboardingBloc, DriverOnboardingState>(
      'reports an error message when registration fails',
      setUp: () {
        when(
          () => repository.registerDriver(
            driver: any(named: 'driver'),
            vehicle: any(named: 'vehicle'),
            profileImage: any(named: 'profileImage'),
          ),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'no se pudo registrar')),
        );
      },
      build: buildBloc,
      seed: () => DriverOnboardingState(user: user),
      act: (bloc) => bloc.add(
        DriverOnboardingSubmitted(
          firstName: 'A',
          lastName: 'B',
          phoneNumber: '123',
          plate: 'ABC123',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'red',
          registrationNumber: 'REG1',
        ),
      ),
      expect: () => [
        predicate<DriverOnboardingState>((s) => s.isSubmitting),
        predicate<DriverOnboardingState>(
          (s) =>
              !s.isSubmitting &&
              s.errorMessage == 'no se pudo registrar' &&
              !s.registrationSuccess,
        ),
      ],
    );
  });
}
