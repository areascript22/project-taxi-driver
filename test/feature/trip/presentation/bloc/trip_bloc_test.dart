import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/trip/domain/entity/trip_status_entity.dart';
import 'package:driver_app/feature/trip/domain/repository/trip_repository.dart';
import 'package:driver_app/feature/trip/presentation/bloc/trip_bloc.dart';
import 'package:driver_app/shared/foreground_location/service/driver_foreground_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTripRepository extends Mock implements TripRepository {}

class MockDriverForegroundService extends Mock
    implements DriverForegroundService {}

void main() {
  late MockTripRepository repository;
  late MockDriverForegroundService foregroundService;
  late StreamController<TripStatusEntity> tripController;

  setUp(() {
    repository = MockTripRepository();
    foregroundService = MockDriverForegroundService();
    tripController = StreamController<TripStatusEntity>.broadcast();

    when(
      () => repository.watchTrip(passengerId: any(named: 'passengerId')),
    ).thenAnswer((_) => tripController.stream);
    when(
      () => foregroundService.start(passengerId: any(named: 'passengerId')),
    ).thenAnswer((_) async {});
    when(() => foregroundService.stopTracking()).thenAnswer((_) async {});
    when(() => foregroundService.stop()).thenAnswer((_) async {});
  });

  tearDown(() {
    tripController.close();
  });

  TripBloc buildBloc() => TripBloc(
    repository: repository,
    driverForegroundService: foregroundService,
  );

  test('initial state has an empty status and no flags set', () {
    final bloc = buildBloc();
    expect(bloc.state.status, '');
    expect(bloc.state.isCancelled, isFalse);
    expect(bloc.state.isCompleted, isFalse);
  });

  group('StartWatchingTrip', () {
    blocTest<TripBloc, TripState>(
      'starts the foreground service and forwards trip status updates',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartWatchingTrip(passengerId: 'p1'));
        await Future.delayed(Duration.zero);
        tripController.add(TripStatusEntity(status: 'driverArrived'));
      },
      expect: () => [
        predicate<TripState>((s) => s.status == 'driverArrived'),
      ],
      verify: (_) {
        verify(() => foregroundService.start(passengerId: 'p1')).called(1);
      },
    );

    blocTest<TripBloc, TripState>(
      'stops tracking when the trip stream reports cancelled',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartWatchingTrip(passengerId: 'p1'));
        await Future.delayed(Duration.zero);
        tripController.add(
          TripStatusEntity(status: 'cancelled', cancelledBy: 'passenger'),
        );
      },
      expect: () => [
        predicate<TripState>((s) => s.status == 'cancelled'),
        predicate<TripState>(
          (s) => s.isCancelled && s.cancelledBy == 'passenger',
        ),
      ],
      verify: (_) {
        verify(() => foregroundService.stopTracking()).called(1);
      },
    );

    blocTest<TripBloc, TripState>(
      'replaces the previous subscription when started again for a new passenger',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartWatchingTrip(passengerId: 'p1'));
        await Future.delayed(Duration.zero);
        bloc.add(StartWatchingTrip(passengerId: 'p2'));
        await Future.delayed(Duration.zero);
        tripController.add(TripStatusEntity(status: 'tripStarted'));
      },
      expect: () => [
        predicate<TripState>((s) => s.status == 'tripStarted'),
      ],
      verify: (_) {
        verify(() => foregroundService.start(passengerId: 'p1')).called(1);
        verify(() => foregroundService.start(passengerId: 'p2')).called(1);
      },
    );
  });

  group('CancelTripRequested', () {
    blocTest<TripBloc, TripState>(
      'emits isCancelling then clears it on success',
      setUp: () {
        when(
          () => repository.cancelRide(passengerId: 'p1'),
        ).thenAnswer((_) async => Right(unit));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(CancelTripRequested(passengerId: 'p1')),
      wait: const Duration(seconds: 2, milliseconds: 100),
      expect: () => [
        predicate<TripState>((s) => s.isCancelling && s.errorMessage == null),
        predicate<TripState>((s) => !s.isCancelling),
      ],
    );

    blocTest<TripBloc, TripState>(
      'reports an error message on failure',
      setUp: () {
        when(
          () => repository.cancelRide(passengerId: 'p1'),
        ).thenAnswer((_) async => Left(Failure(message: 'no se pudo cancelar')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(CancelTripRequested(passengerId: 'p1')),
      wait: const Duration(seconds: 2, milliseconds: 100),
      expect: () => [
        predicate<TripState>((s) => s.isCancelling),
        predicate<TripState>(
          (s) => !s.isCancelling && s.errorMessage == 'no se pudo cancelar',
        ),
      ],
    );
  });

  group('StopWatchingTrip', () {
    blocTest<TripBloc, TripState>(
      'cancels the subscription and stops tracking',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartWatchingTrip(passengerId: 'p1'));
        await Future.delayed(Duration.zero);
        bloc.add(StopWatchingTrip());
        await Future.delayed(Duration.zero);
        tripController.add(TripStatusEntity(status: 'tripStarted'));
      },
      expect: () => [],
      verify: (_) {
        verify(() => foregroundService.stopTracking()).called(1);
      },
    );
  });

  group('DriverArrivedRequested', () {
    blocTest<TripBloc, TripState>(
      'emits isMarkingArrived then clears it on success',
      setUp: () {
        when(
          () => repository.markDriverArrived(passengerId: 'p1'),
        ).thenAnswer((_) async => Right(unit));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(DriverArrivedRequested(passengerId: 'p1')),
      expect: () => [
        predicate<TripState>((s) => s.isMarkingArrived),
        predicate<TripState>((s) => !s.isMarkingArrived && s.errorMessage == null),
      ],
    );

    blocTest<TripBloc, TripState>(
      'reports an error message on failure',
      setUp: () {
        when(
          () => repository.markDriverArrived(passengerId: 'p1'),
        ).thenAnswer((_) async => Left(Failure(message: 'error de red')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(DriverArrivedRequested(passengerId: 'p1')),
      expect: () => [
        predicate<TripState>((s) => s.isMarkingArrived),
        predicate<TripState>(
          (s) => !s.isMarkingArrived && s.errorMessage == 'error de red',
        ),
      ],
    );
  });

  group('CompleteTripRequested', () {
    blocTest<TripBloc, TripState>(
      'stops tracking and marks the trip as completed on success',
      setUp: () {
        when(
          () => repository.completeTrip(passengerId: 'p1'),
        ).thenAnswer((_) async => Right(unit));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(CompleteTripRequested(passengerId: 'p1')),
      expect: () => [
        predicate<TripState>((s) => s.isCompleting),
        predicate<TripState>((s) => !s.isCompleting && s.isCompleted),
      ],
      verify: (_) {
        verify(() => foregroundService.stopTracking()).called(1);
      },
    );

    blocTest<TripBloc, TripState>(
      'reports an error and does not mark completed on failure',
      setUp: () {
        when(
          () => repository.completeTrip(passengerId: 'p1'),
        ).thenAnswer((_) async => Left(Failure(message: 'no se pudo completar')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(CompleteTripRequested(passengerId: 'p1')),
      expect: () => [
        predicate<TripState>((s) => s.isCompleting),
        predicate<TripState>(
          (s) =>
              !s.isCompleting &&
              !s.isCompleted &&
              s.errorMessage == 'no se pudo completar',
        ),
      ],
      verify: (_) {
        verifyNever(() => foregroundService.stopTracking());
      },
    );
  });

  test('close cancels the trip subscription', () async {
    final bloc = buildBloc();
    bloc.add(StartWatchingTrip(passengerId: 'p1'));
    await Future.delayed(Duration.zero);
    await bloc.close();
    expect(tripController.hasListener, isFalse);
  });
}
