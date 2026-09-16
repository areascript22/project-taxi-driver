import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/feature/incoming_request/domain/repository/incoming_request_repository.dart';
import 'package:driver_app/feature/incoming_request/presentation/bloc/incoming_request_bloc.dart';
import 'package:driver_app/shared/domain/entity/user_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncomingRequestRepository extends Mock
    implements IncomingRequestRepository {}

IncomingRequestEntity _request(String rideId, {String status = 'pending'}) {
  return IncomingRequestEntity(
    rideId: rideId,
    userId: 'passenger-$rideId',
    status: status,
    createdAt: 0,
    updatedAt: 0,
    passenger: PassengerEntity(name: 'Pass $rideId', profileImage: ''),
    pickupLocation: PickupLocationEntity(
      address: 'Calle $rideId',
      latitude: 0,
      longitude: 0,
    ),
  );
}

final _driverLocation = UserLocation(latitude: 1, longitude: 2);

void main() {
  late MockIncomingRequestRepository repository;
  late StreamController<IncomingRequestEntity> addedController;
  late StreamController<IncomingRequestEntity> changedController;
  late StreamController<String> removedController;

  setUpAll(() {
    registerFallbackValue(UserLocation(latitude: 0, longitude: 0));
  });

  setUp(() {
    repository = MockIncomingRequestRepository();
    addedController = StreamController<IncomingRequestEntity>.broadcast();
    changedController = StreamController<IncomingRequestEntity>.broadcast();
    removedController = StreamController<String>.broadcast();

    when(() => repository.onRequestAdded).thenAnswer((_) => addedController.stream);
    when(() => repository.onRequestChanged).thenAnswer((_) => changedController.stream);
    when(() => repository.onRequestRemoved).thenAnswer((_) => removedController.stream);
  });

  tearDown(() {
    addedController.close();
    changedController.close();
    removedController.close();
  });

  IncomingRequestBloc buildBloc() =>
      IncomingRequestBloc(repository: repository);

  test('initial state is IncomingRequestInitial', () {
    expect(buildBloc().state, isA<IncomingRequestInitial>());
  });

  group('StartListeningRequests', () {
    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'emits an empty loaded list immediately',
      build: buildBloc,
      act: (bloc) => bloc.add(StartListeningRequests()),
      expect: () => [
        isA<IncomingRequestLoaded>().having((s) => s.requests, 'requests', isEmpty),
      ],
    );

    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'inserts newly added requests at the front of the list',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartListeningRequests());
        await Future.delayed(Duration.zero);
        addedController.add(_request('1'));
        addedController.add(_request('2'));
      },
      expect: () => [
        isA<IncomingRequestLoaded>().having((s) => s.requests, 'requests', isEmpty),
        isA<IncomingRequestLoaded>()
            .having((s) => s.requests.map((r) => r.rideId).toList(), 'ids', ['1']),
        isA<IncomingRequestLoaded>()
            .having((s) => s.requests.map((r) => r.rideId).toList(), 'ids', ['2', '1']),
      ],
    );

    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'ignores a duplicate rideId that arrives twice via onRequestAdded',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartListeningRequests());
        await Future.delayed(Duration.zero);
        addedController.add(_request('1'));
        addedController.add(_request('1'));
      },
      expect: () => [
        isA<IncomingRequestLoaded>().having((s) => s.requests, 'requests', isEmpty),
        isA<IncomingRequestLoaded>()
            .having((s) => s.requests.map((r) => r.rideId).toList(), 'ids', ['1']),
      ],
    );

    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'updates a request in place when onRequestChanged fires',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartListeningRequests());
        await Future.delayed(Duration.zero);
        addedController.add(_request('1', status: 'pending'));
        await Future.delayed(Duration.zero);
        changedController.add(_request('1', status: 'accepted'));
      },
      skip: 2,
      expect: () => [
        isA<IncomingRequestLoaded>()
            .having((s) => s.requests.single.status, 'status', 'accepted'),
      ],
    );

    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'removes a request from the list when onRequestRemoved fires',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartListeningRequests());
        await Future.delayed(Duration.zero);
        addedController.add(_request('1'));
        addedController.add(_request('2'));
        await Future.delayed(Duration.zero);
        removedController.add('1');
      },
      skip: 3,
      expect: () => [
        isA<IncomingRequestLoaded>()
            .having((s) => s.requests.map((r) => r.rideId).toList(), 'ids', ['2']),
      ],
    );

    test('does not open a second subscription when started again', () async {
      var listenCount = 0;
      final singleSubController = StreamController<IncomingRequestEntity>.broadcast(
        onListen: () => listenCount++,
      );
      when(() => repository.onRequestAdded).thenAnswer((_) => singleSubController.stream);

      final bloc = buildBloc();
      bloc.add(StartListeningRequests());
      await Future.delayed(Duration.zero);
      bloc.add(StartListeningRequests());
      await Future.delayed(Duration.zero);

      expect(listenCount, 1);

      await bloc.close();
      await singleSubController.close();
    });
  });

  group('StopListeningRequests', () {
    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'cancels subscriptions so further stream events are ignored',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartListeningRequests());
        await Future.delayed(Duration.zero);
        bloc.add(StopListeningRequests());
        await Future.delayed(Duration.zero);
        addedController.add(_request('1'));
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        isA<IncomingRequestLoaded>().having((s) => s.requests, 'requests', isEmpty),
      ],
    );
  });

  group('AcceptRideRequested', () {
    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'does nothing if the current state is not IncomingRequestLoaded',
      build: buildBloc,
      act: (bloc) => bloc.add(
        AcceptRideRequested(request: _request('1'), driverLocation: _driverLocation),
      ),
      expect: () => [],
      verify: (_) {
        verifyNever(
          () => repository.acceptRide(
            passengerId: any(named: 'passengerId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        );
      },
    );

    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'marks success when the repository accepts the ride',
      setUp: () {
        when(
          () => repository.acceptRide(
            passengerId: any(named: 'passengerId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        ).thenAnswer((_) async => const Right(true));
      },
      build: buildBloc,
      seed: () => IncomingRequestLoaded(requests: [_request('1')]),
      act: (bloc) => bloc.add(
        AcceptRideRequested(request: _request('1'), driverLocation: _driverLocation),
      ),
      expect: () => [
        isA<IncomingRequestLoaded>().having((s) => s.acceptStatus, 'status', AcceptRideStatus.loading),
        isA<IncomingRequestLoaded>().having((s) => s.acceptStatus, 'status', AcceptRideStatus.success),
      ],
      verify: (_) {
        verify(
          () => repository.acceptRide(
            passengerId: 'passenger-1',
            driverLocation: _driverLocation,
          ),
        ).called(1);
      },
    );

    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'marks error with the failure message when the repository rejects the ride',
      setUp: () {
        when(
          () => repository.acceptRide(
            passengerId: any(named: 'passengerId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        ).thenAnswer((_) async => Left(Failure(message: 'ya fue tomada')));
      },
      build: buildBloc,
      seed: () => IncomingRequestLoaded(requests: [_request('1')]),
      act: (bloc) => bloc.add(
        AcceptRideRequested(request: _request('1'), driverLocation: _driverLocation),
      ),
      expect: () => [
        isA<IncomingRequestLoaded>().having((s) => s.acceptStatus, 'status', AcceptRideStatus.loading),
        isA<IncomingRequestLoaded>()
            .having((s) => s.acceptStatus, 'status', AcceptRideStatus.error)
            .having((s) => s.acceptErrorMessage, 'errorMessage', 'ya fue tomada'),
      ],
    );

    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'ignores a duplicate accept for the same ride while one is already loading',
      setUp: () {
        when(
          () => repository.acceptRide(
            passengerId: any(named: 'passengerId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        ).thenAnswer(
          (_) => Future.delayed(const Duration(milliseconds: 50), () => const Right(true)),
        );
      },
      build: buildBloc,
      seed: () => IncomingRequestLoaded(requests: [_request('1')]),
      act: (bloc) {
        final req = _request('1');
        bloc.add(AcceptRideRequested(request: req, driverLocation: _driverLocation));
        bloc.add(AcceptRideRequested(request: req, driverLocation: _driverLocation));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<IncomingRequestLoaded>().having((s) => s.acceptStatus, 'status', AcceptRideStatus.loading),
        isA<IncomingRequestLoaded>().having((s) => s.acceptStatus, 'status', AcceptRideStatus.success),
      ],
      verify: (_) {
        verify(
          () => repository.acceptRide(
            passengerId: any(named: 'passengerId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        ).called(1);
      },
    );

    blocTest<IncomingRequestBloc, IncomingRequestState>(
      'allows accepting a different ride while another is already loading',
      setUp: () {
        when(
          () => repository.acceptRide(
            passengerId: any(named: 'passengerId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        ).thenAnswer((_) async => const Right(true));
      },
      build: buildBloc,
      seed: () => IncomingRequestLoaded(
        requests: [_request('1'), _request('2')],
        acceptStatus: AcceptRideStatus.loading,
        processingRequest: _request('1'),
      ),
      act: (bloc) => bloc.add(
        AcceptRideRequested(request: _request('2'), driverLocation: _driverLocation),
      ),
      expect: () => [
        isA<IncomingRequestLoaded>()
            .having((s) => s.processingRequest?.rideId, 'processing', '2'),
        isA<IncomingRequestLoaded>().having((s) => s.acceptStatus, 'status', AcceptRideStatus.success),
      ],
    );
  });

  test('close cancels all stream subscriptions without throwing', () async {
    final bloc = buildBloc();
    bloc.add(StartListeningRequests());
    await Future.delayed(Duration.zero);
    await bloc.close();
    expect(addedController.hasListener, isFalse);
  });
}
