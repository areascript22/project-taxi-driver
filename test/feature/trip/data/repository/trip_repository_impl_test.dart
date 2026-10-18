import 'package:dio/dio.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/trip/data/repository/trip_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late TripRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = TripRepositoryImpl(dio: dio);
  });

  RequestOptions requestOptions() =>
      RequestOptions(path: '/api/rides/p1/arrived');

  group('markDriverArrived', () {
    // Ya no escribe directo en Realtime Database: pasa por el servidor, que
    // verifica quién es y en qué estado está la carrera.
    test('posts to the server and returns Right(unit) on 204', () async {
      when(() => dio.post('/api/rides/p1/arrived')).thenAnswer(
        (_) async => Response(requestOptions: requestOptions(), statusCode: 204),
      );

      final result = await repository.markDriverArrived(passengerId: 'p1');

      expect(result.isRight(), isTrue);
      verify(() => dio.post('/api/rides/p1/arrived')).called(1);
    });

    for (final statusCode in [403, 404, 409, 500]) {
      test('returns Left(arrivalNotifyFailed) when the server answers $statusCode', () async {
        when(() => dio.post('/api/rides/p1/arrived')).thenThrow(
          DioException(
            requestOptions: requestOptions(),
            response: Response(
              requestOptions: requestOptions(),
              statusCode: statusCode,
            ),
          ),
        );

        final result = await repository.markDriverArrived(passengerId: 'p1');

        result.fold(
          (failure) => expect(failure.code, FailureCode.arrivalNotifyFailed),
          (_) => fail('expected Left'),
        );
      });
    }

    test('returns Left(arrivalNotifyFailed) on a network error', () async {
      when(() => dio.post('/api/rides/p1/arrived')).thenThrow(
        DioException(
          requestOptions: requestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.markDriverArrived(passengerId: 'p1');

      expect(result.isLeft(), isTrue);
    });
  });
}
