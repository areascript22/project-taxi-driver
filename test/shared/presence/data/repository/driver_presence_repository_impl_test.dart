import 'package:dio/dio.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/shared/presence/data/repository/driver_presence_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late DriverPresenceRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = MockDio();
    repository = DriverPresenceRepositoryImpl(dio: dio);
  });

  RequestOptions requestOptions(String path) => RequestOptions(path: path);

  DioException serverError(String path, int status) => DioException(
    requestOptions: requestOptions(path),
    response: Response(requestOptions: requestOptions(path), statusCode: status),
  );

  group('setOnline', () {
    test('sends the flag to the server and returns Right(unit)', () async {
      when(
        () => dio.put('/api/me/driver/availability', data: {'online': true}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: requestOptions('/api/me/driver/availability'),
          statusCode: 204,
        ),
      );

      final result = await repository.setOnline(online: true);

      expect(result.isRight(), isTrue);
      verify(
        () => dio.put('/api/me/driver/availability', data: {'online': true}),
      ).called(1);
    });

    test('maps 403 to onlineNotAllowed (not approved or blocked)', () async {
      when(
        () => dio.put('/api/me/driver/availability', data: any(named: 'data')),
      ).thenThrow(serverError('/api/me/driver/availability', 403));

      final result = await repository.setOnline(online: true);

      result.fold(
        (failure) => expect(failure.code, FailureCode.onlineNotAllowed),
        (_) => fail('expected Left'),
      );
    });

    test('maps 404 to driverProfileNotReady', () async {
      when(
        () => dio.put('/api/me/driver/availability', data: any(named: 'data')),
      ).thenThrow(serverError('/api/me/driver/availability', 404));

      final result = await repository.setOnline(online: true);

      result.fold(
        (failure) => expect(failure.code, FailureCode.driverProfileNotReady),
        (_) => fail('expected Left'),
      );
    });

    for (final status in [400, 500, 503]) {
      test('maps $status to onlineFailed', () async {
        when(
          () => dio.put('/api/me/driver/availability', data: any(named: 'data')),
        ).thenThrow(serverError('/api/me/driver/availability', status));

        final result = await repository.setOnline(online: false);

        result.fold(
          (failure) => expect(failure.code, FailureCode.onlineFailed),
          (_) => fail('expected Left'),
        );
      });
    }

    test('maps a network error to onlineFailed', () async {
      when(
        () => dio.put('/api/me/driver/availability', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: requestOptions('/api/me/driver/availability'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.setOnline(online: true);

      result.fold(
        (failure) => expect(failure.code, FailureCode.onlineFailed),
        (_) => fail('expected Left'),
      );
    });
  });

  group('reportLocation', () {
    test('without a ride sends only the coordinates', () async {
      when(
        () => dio.put(
          '/api/me/driver/location',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: requestOptions('/api/me/driver/location'),
          statusCode: 204,
        ),
      );

      final result = await repository.reportLocation(
        latitude: -1.6635,
        longitude: -78.6546,
      );

      expect(result.isRight(), isTrue);
      final captured = verify(
        () => dio.put(
          '/api/me/driver/location',
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured.single as Map;
      expect(captured, {'latitude': -1.6635, 'longitude': -78.6546});
    });

    test('during a ride also sends the passengerId', () async {
      when(
        () => dio.put(
          '/api/me/driver/location',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: requestOptions('/api/me/driver/location'),
          statusCode: 204,
        ),
      );

      await repository.reportLocation(
        latitude: -1.67,
        longitude: -78.66,
        passengerId: 'p1',
      );

      final captured = verify(
        () => dio.put(
          '/api/me/driver/location',
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured.single as Map;
      expect(captured['passengerId'], 'p1');
    });

    // Una posicion vieja es peor que ninguna: DioClient reintenta por defecto
    // ante un timeout y aca eso no se quiere.
    test('disables automatic retries for the request', () async {
      when(
        () => dio.put(
          '/api/me/driver/location',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: requestOptions('/api/me/driver/location'),
          statusCode: 204,
        ),
      );

      await repository.reportLocation(latitude: -1.0, longitude: -78.0);

      final options = verify(
        () => dio.put(
          '/api/me/driver/location',
          data: any(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured.single as Options;
      expect(options.extra?['ro_disable_retry'], isTrue);
    });

    test('maps any failure to locationUpdateFailed', () async {
      when(
        () => dio.put(
          '/api/me/driver/location',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(serverError('/api/me/driver/location', 409));

      final result = await repository.reportLocation(
        latitude: -1.0,
        longitude: -78.0,
      );

      result.fold(
        (failure) => expect(failure.code, FailureCode.locationUpdateFailed),
        (_) => fail('expected Left'),
      );
    });
  });
}
