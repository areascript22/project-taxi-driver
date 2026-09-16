import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/shared/geolocator/location/location_bloc.dart';
import 'package:driver_app/shared/geolocator/service/geolocator/geolocator_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockGeolocatorService extends Mock implements GeolocatorService {}

void main() {
  late MockGeolocatorService service;

  setUp(() {
    service = MockGeolocatorService();
  });

  LocationBloc buildBloc() => LocationBloc(locationService: service);

  test('initial state is LocationProcess.initial with no permission', () {
    final state = buildBloc().state;
    expect(state.locationProcess, LocationProcess.initial);
    expect(state.permissionStatus, isNull);
    expect(state.isGranted, isFalse);
    expect(state.isPermanentlyDenied, isFalse);
  });

  group('CheckLocationPermissionEvent', () {
    blocTest<LocationBloc, LocationState>(
      'reports permissionsReady with the granted status (whileInUse)',
      setUp: () {
        when(() => service.checkPermission()).thenAnswer(
          (_) async => const Right(LocationPermission.whileInUse),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(CheckLocationPermissionEvent()),
      expect: () => [
        predicate<LocationState>(
          (s) => s.locationProcess == LocationProcess.checkingPermissions,
        ),
        predicate<LocationState>(
          (s) =>
              s.locationProcess == LocationProcess.permissionsReady &&
              s.isGranted &&
              s.errorMessage == null,
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'reports permissionsReady with isPermanentlyDenied when deniedForever',
      setUp: () {
        when(() => service.checkPermission()).thenAnswer(
          (_) async => const Right(LocationPermission.deniedForever),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(CheckLocationPermissionEvent()),
      expect: () => [
        predicate<LocationState>(
          (s) => s.locationProcess == LocationProcess.checkingPermissions,
        ),
        predicate<LocationState>(
          (s) =>
              s.locationProcess == LocationProcess.permissionsReady &&
              !s.isGranted &&
              s.isPermanentlyDenied,
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'reports permissionsError with the failure message',
      setUp: () {
        when(() => service.checkPermission()).thenAnswer(
          (_) async => Left(Failure(message: 'servicio deshabilitado')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(CheckLocationPermissionEvent()),
      expect: () => [
        predicate<LocationState>(
          (s) => s.locationProcess == LocationProcess.checkingPermissions,
        ),
        predicate<LocationState>(
          (s) =>
              s.locationProcess == LocationProcess.permissionsError &&
              s.errorMessage == 'servicio deshabilitado',
        ),
      ],
    );
  });

  group('CheckAndRequestPermissionEvent', () {
    blocTest<LocationBloc, LocationState>(
      'reports permissionsReady with denied status',
      setUp: () {
        when(() => service.checkAndRequestPermission()).thenAnswer(
          (_) async => const Right(LocationPermission.denied),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(CheckAndRequestPermissionEvent()),
      expect: () => [
        predicate<LocationState>(
          (s) => s.locationProcess == LocationProcess.checkingPermissions,
        ),
        predicate<LocationState>(
          (s) =>
              s.locationProcess == LocationProcess.permissionsReady &&
              !s.isGranted &&
              !s.isPermanentlyDenied,
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'reports permissionsError on failure',
      setUp: () {
        when(() => service.checkAndRequestPermission()).thenAnswer(
          (_) async => Left(Failure(message: 'error')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(CheckAndRequestPermissionEvent()),
      expect: () => [
        predicate<LocationState>(
          (s) => s.locationProcess == LocationProcess.checkingPermissions,
        ),
        predicate<LocationState>(
          (s) => s.locationProcess == LocationProcess.permissionsError,
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'clears a previous error message on a new successful check',
      setUp: () {
        when(() => service.checkAndRequestPermission()).thenAnswer(
          (_) async => const Right(LocationPermission.always),
        );
      },
      build: buildBloc,
      seed: () => const LocationState(
        locationProcess: LocationProcess.permissionsError,
        errorMessage: 'error viejo',
      ),
      act: (bloc) => bloc.add(CheckAndRequestPermissionEvent()),
      expect: () => [
        predicate<LocationState>(
          (s) => s.locationProcess == LocationProcess.checkingPermissions,
        ),
        predicate<LocationState>(
          (s) => s.errorMessage == null && s.isGranted,
        ),
      ],
    );
  });

  group('OpenAppSettingsEvent', () {
    blocTest<LocationBloc, LocationState>(
      'calls the service without emitting a new state',
      setUp: () {
        when(() => service.openAppSettings()).thenAnswer((_) async => const Right(true));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(OpenAppSettingsEvent()),
      expect: () => [],
      verify: (_) {
        verify(() => service.openAppSettings()).called(1);
      },
    );
  });
}
