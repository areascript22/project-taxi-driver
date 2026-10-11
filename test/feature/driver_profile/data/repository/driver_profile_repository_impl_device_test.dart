import 'package:dio/dio.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/driver_profile/data/repository/driver_profile_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

// El token de notificaciones y el idioma ya no se escriben en Firestore: van
// al servidor (PUT /api/me/device), que identifica a la persona y a la app por
// el token de sesion.
void main() {
  late MockDio dio;
  late DriverProfileRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = DriverProfileRepositoryImpl(dio: dio);
  });

  Response<dynamic> noContent() => Response(
    requestOptions: RequestOptions(path: '/api/me/device'),
    statusCode: 204,
  );

  group('updateFcmToken', () {
    test('sends token and language tagged as the driver app', () async {
      when(
        () => dio.put('/api/me/device', data: any(named: 'data')),
      ).thenAnswer((_) async => noContent());

      final result = await repository.updateFcmToken(
        driverId: 'd1',
        token: 'tok-1',
        language: 'es',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => dio.put(
          '/api/me/device',
          data: {'app': 'driver', 'fcmToken': 'tok-1', 'language': 'es'},
        ),
      ).called(1);
    });

    test('does not send the driverId: the server takes identity from the session', () async {
      when(
        () => dio.put('/api/me/device', data: any(named: 'data')),
      ).thenAnswer((_) async => noContent());

      await repository.updateFcmToken(driverId: 'otro', token: 't', language: 'en');

      final body = verify(
        () => dio.put('/api/me/device', data: captureAny(named: 'data')),
      ).captured.single as Map;
      expect(body.containsKey('driverId'), isFalse);
      expect(body.containsKey('uid'), isFalse);
    });

    test('returns Left(fcmTokenSaveFailed) when the server rejects it', () async {
      when(() => dio.put('/api/me/device', data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/me/device'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/me/device'),
            statusCode: 404,
          ),
        ),
      );

      final result = await repository.updateFcmToken(
        driverId: 'd1',
        token: 'tok-1',
        language: 'es',
      );

      result.fold(
        (failure) => expect(failure.code, FailureCode.fcmTokenSaveFailed),
        (_) => fail('expected Left'),
      );
    });
  });

  group('updateLanguage', () {
    test('sends only the language', () async {
      when(
        () => dio.put('/api/me/device', data: any(named: 'data')),
      ).thenAnswer((_) async => noContent());

      final result = await repository.updateLanguage(driverId: 'd1', language: 'en');

      expect(result.isRight(), isTrue);
      verify(
        () => dio.put('/api/me/device', data: {'app': 'driver', 'language': 'en'}),
      ).called(1);
    });

    test('returns Left(pushLanguageSaveFailed) on a network error', () async {
      when(() => dio.put('/api/me/device', data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/me/device'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.updateLanguage(driverId: 'd1', language: 'en');

      result.fold(
        (failure) => expect(failure.code, FailureCode.pushLanguageSaveFailed),
        (_) => fail('expected Left'),
      );
    });
  });
}
