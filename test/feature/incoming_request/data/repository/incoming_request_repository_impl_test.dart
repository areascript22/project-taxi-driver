import 'dart:async';

import 'package:dio/dio.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/incoming_request/data/repository/incoming_request_repository_impl.dart';
import 'package:driver_app/shared/domain/entity/user_location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockQuery extends Mock implements Query {}

class MockDatabaseEvent extends Mock implements DatabaseEvent {}

class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockDio dio;
  late MockQuery offers;
  late StreamController<DatabaseEvent> added;
  late StreamController<DatabaseEvent> changed;
  late StreamController<DatabaseEvent> removed;
  late IncomingRequestRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    offers = MockQuery();
    added = StreamController<DatabaseEvent>.broadcast();
    changed = StreamController<DatabaseEvent>.broadcast();
    removed = StreamController<DatabaseEvent>.broadcast();
    when(() => offers.onChildAdded).thenAnswer((_) => added.stream);
    when(() => offers.onChildChanged).thenAnswer((_) => changed.stream);
    when(() => offers.onChildRemoved).thenAnswer((_) => removed.stream);
    repository = IncomingRequestRepositoryImpl(offersQuery: offers, dio: dio);
  });

  tearDown(() async {
    await added.close();
    await changed.close();
    await removed.close();
  });

  DatabaseEvent event(Object? value, {String? key}) {
    final snapshot = MockDataSnapshot();
    when(() => snapshot.value).thenReturn(value);
    when(() => snapshot.key).thenReturn(key);
    final event = MockDatabaseEvent();
    when(() => event.snapshot).thenReturn(snapshot);
    return event;
  }

  Map<String, dynamic> offer({String rideId = 'p1_1', int? expiresAt}) => {
    'rideId': rideId,
    'passengerId': 'p1',
    'passengerName': 'Ana',
    'pickup': {
      'latitude': -1.66,
      'longitude': -78.65,
      'address': 'Av. 1',
      'sector': 'La Saboya',
    },
    if (expiresAt != null) 'expiresAt': expiresAt,
  };

  group('inbox streams', () {
    test('onRequestAdded emits each offer as an incoming request', () async {
      final received = <String>[];
      final sub = repository.onRequestAdded.listen((r) => received.add(r.rideId));

      added.add(event(offer(rideId: 'a'), key: 'p1'));
      added.add(event(offer(rideId: 'b'), key: 'p2'));
      await Future<void>.delayed(Duration.zero);

      expect(received, ['a', 'b']);
      await sub.cancel();
    });

    test('onRequestAdded skips an offer that already expired', () async {
      final received = <String>[];
      final sub = repository.onRequestAdded.listen((r) => received.add(r.rideId));
      final past = DateTime.now().millisecondsSinceEpoch - 1000;
      final future = DateTime.now().millisecondsSinceEpoch + 60000;

      added.add(event(offer(rideId: 'vencida', expiresAt: past), key: 'p1'));
      added.add(event(offer(rideId: 'vigente', expiresAt: future), key: 'p2'));
      await Future<void>.delayed(Duration.zero);

      expect(received, ['vigente']);
      await sub.cancel();
    });

    test('onRequestAdded ignores a malformed (non-map) value', () async {
      final received = <String>[];
      final sub = repository.onRequestAdded.listen((r) => received.add(r.rideId));

      added.add(event('basura', key: 'p1'));
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
      await sub.cancel();
    });

    test('onRequestChanged emits the updated offer', () async {
      final received = <String>[];
      final sub =
          repository.onRequestChanged.listen((r) => received.add(r.pickupLocation.sector));

      changed.add(event(offer(), key: 'p1'));
      await Future<void>.delayed(Duration.zero);

      expect(received, ['La Saboya']);
      await sub.cancel();
    });

    test('onRequestRemoved emits the rideId stored in the removed offer', () async {
      final received = <String>[];
      final sub = repository.onRequestRemoved.listen(received.add);

      removed.add(event(offer(rideId: 'p1_99'), key: 'p1'));
      await Future<void>.delayed(Duration.zero);

      expect(received, ['p1_99']);
      await sub.cancel();
    });

    test('onRequestRemoved falls back to the node key when the value has no rideId', () async {
      final received = <String>[];
      final sub = repository.onRequestRemoved.listen(received.add);

      removed.add(event(null, key: 'p7'));
      await Future<void>.delayed(Duration.zero);

      expect(received, ['p7']);
      await sub.cancel();
    });
  });

  group('acceptRide', () {
    final location = UserLocation(latitude: -1.66, longitude: -78.65);

    DioException status(int code) => DioException(
      requestOptions: RequestOptions(path: '/api/rides/p1/accept'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/rides/p1/accept'),
        statusCode: code,
      ),
    );

    test('posts the driver location and returns Right(true)', () async {
      when(
        () => dio.post('/api/rides/p1/accept', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/rides/p1/accept'),
          statusCode: 204,
        ),
      );

      final result = await repository.acceptRide(
        passengerId: 'p1',
        driverLocation: location,
      );

      result.fold(
        (failure) => fail('expected Right, got ${failure.code}'),
        (accepted) => expect(accepted, isTrue),
      );
      verify(
        () => dio.post(
          '/api/rides/p1/accept',
          data: {'latitude': -1.66, 'longitude': -78.65},
        ),
      ).called(1);
    });

    final cases = <int, FailureCode>{
      409: FailureCode.rideTaken,
      404: FailureCode.rideUnavailable,
      403: FailureCode.rideAcceptFailed,
      500: FailureCode.rideAcceptFailed,
    };
    cases.forEach((statusCode, expected) {
      test('maps $statusCode to $expected', () async {
        when(
          () => dio.post('/api/rides/p1/accept', data: any(named: 'data')),
        ).thenThrow(status(statusCode));

        final result = await repository.acceptRide(
          passengerId: 'p1',
          driverLocation: location,
        );

        result.fold(
          (failure) => expect(failure.code, expected),
          (_) => fail('expected Left'),
        );
      });
    });
  });
}
