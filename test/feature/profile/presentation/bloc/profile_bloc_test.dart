import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/driver_profile/domain/entity/driver_entity.dart';
import 'package:driver_app/feature/driver_profile/domain/entity/vehicle_entity.dart';
import 'package:driver_app/feature/driver_profile/domain/repository/driver_profile_repository.dart';
import 'package:driver_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDriverProfileRepository extends Mock
    implements DriverProfileRepository {}

DriverEntity _driver({String vehicleId = ''}) {
  return DriverEntity(
    id: 'd1',
    firstName: 'Juan',
    lastName: 'Perez',
    email: 'juan@example.com',
    phoneNumber: '123',
    vehicleId: vehicleId,
  );
}

VehicleEntity _vehicle() {
  return VehicleEntity(
    vehicleId: 'v1',
    driverId: 'd1',
    plate: 'ABC123',
    brand: 'Toyota',
    model: 'Corolla',
    year: 2020,
    color: 'red',
    registrationNumber: 'REG1',
  );
}

void main() {
  late MockDriverProfileRepository repository;

  setUp(() {
    repository = MockDriverProfileRepository();
  });

  ProfileBloc buildBloc() => ProfileBloc(driverProfileRepository: repository);

  test('initial state has no driver, no vehicle, not loading', () {
    final bloc = buildBloc();
    expect(bloc.state.isLoading, isFalse);
    expect(bloc.state.driver, isNull);
    expect(bloc.state.vehicle, isNull);
  });

  group('ProfileLoadRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'loads driver and vehicle when the driver has a vehicleId',
      setUp: () {
        when(
          () => repository.getDriver(driverId: 'd1'),
        ).thenAnswer((_) async => Right(_driver(vehicleId: 'v1')));
        when(
          () => repository.getVehicle(vehicleId: 'v1'),
        ).thenAnswer((_) async => Right(_vehicle()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ProfileLoadRequested(driverId: 'd1')),
      expect: () => [
        predicate<ProfileState>((s) => s.isLoading),
        predicate<ProfileState>(
          (s) => !s.isLoading && s.driver != null && s.vehicle != null,
        ),
      ],
      verify: (_) {
        verify(() => repository.getVehicle(vehicleId: 'v1')).called(1);
      },
    );

    // Regresion: DriverModel.toEntity() deja vehicleId vacio (el servidor ya no
    // lo manda en el conductor), asi que el vehiculo se tiene que pedir igual.
    blocTest<ProfileBloc, ProfileState>(
      'still loads the vehicle when the driver has an empty vehicleId',
      setUp: () {
        when(
          () => repository.getDriver(driverId: 'd1'),
        ).thenAnswer((_) async => Right(_driver(vehicleId: '')));
        when(
          () => repository.getVehicle(vehicleId: ''),
        ).thenAnswer((_) async => Right(_vehicle()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ProfileLoadRequested(driverId: 'd1')),
      expect: () => [
        predicate<ProfileState>((s) => s.isLoading),
        predicate<ProfileState>(
          (s) => !s.isLoading && s.driver != null && s.vehicle != null,
        ),
      ],
      verify: (_) {
        verify(() => repository.getVehicle(vehicleId: '')).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'vehicle stays null when the server has no vehicle for the driver',
      setUp: () {
        when(
          () => repository.getDriver(driverId: 'd1'),
        ).thenAnswer((_) async => Right(_driver()));
        when(
          () => repository.getVehicle(vehicleId: any(named: 'vehicleId')),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ProfileLoadRequested(driverId: 'd1')),
      expect: () => [
        predicate<ProfileState>((s) => s.isLoading),
        predicate<ProfileState>(
          (s) => !s.isLoading && s.driver != null && s.vehicle == null,
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'reports a generic error message when getDriver fails',
      setUp: () {
        when(
          () => repository.getDriver(driverId: 'd1'),
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.unexpected)));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ProfileLoadRequested(driverId: 'd1')),
      expect: () => [
        predicate<ProfileState>((s) => s.isLoading),
        predicate<ProfileState>(
          (s) =>
              !s.isLoading &&
              s.driver == null &&
              s.errorCode != null,
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'reports a generic error when getDriver succeeds with a null driver',
      setUp: () {
        when(
          () => repository.getDriver(driverId: 'd1'),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ProfileLoadRequested(driverId: 'd1')),
      expect: () => [
        predicate<ProfileState>((s) => s.isLoading),
        predicate<ProfileState>(
          (s) =>
              !s.isLoading &&
              s.driver == null &&
              s.errorCode != null,
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'keeps the driver but vehicle stays null when getVehicle fails',
      setUp: () {
        when(
          () => repository.getDriver(driverId: 'd1'),
        ).thenAnswer((_) async => Right(_driver(vehicleId: 'v1')));
        when(
          () => repository.getVehicle(vehicleId: 'v1'),
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.unexpected)));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ProfileLoadRequested(driverId: 'd1')),
      expect: () => [
        predicate<ProfileState>((s) => s.isLoading),
        predicate<ProfileState>(
          (s) =>
              !s.isLoading &&
              s.driver != null &&
              s.vehicle == null &&
              s.errorCode == null,
        ),
      ],
    );
  });
}
