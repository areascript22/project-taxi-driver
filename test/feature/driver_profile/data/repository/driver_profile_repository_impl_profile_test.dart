import 'dart:io';

import 'package:dio/dio.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/driver_profile/data/repository/driver_profile_repository_impl.dart';
import 'package:driver_app/feature/driver_profile/domain/entity/driver_entity.dart';
import 'package:driver_app/feature/driver_profile/domain/entity/vehicle_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

// El perfil del conductor se lee de GET /api/me y se guarda con
// PUT /api/me/driver-profile: ya no se toca Firestore.
void main() {
  late MockDio dio;
  late DriverProfileRepositoryImpl repository;
  String? uploadedPath;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = MockDio();
    uploadedPath = null;
    repository = DriverProfileRepositoryImpl(
      dio: dio,
      photoUploader: ({required String path, required File file}) async {
        uploadedPath = path;
        return 'https://storage/photo.jpg';
      },
    );
  });

  Response<dynamic> ok(Map<String, dynamic> body) => Response(
    requestOptions: RequestOptions(path: '/api/me'),
    statusCode: 200,
    data: body,
  );

  Map<String, dynamic> me({
    Map<String, dynamic>? driver,
    bool blocked = false,
    String? blockReason,
    String role = 'user',
  }) => {
    'id': 'u-1',
    'uid': 'uid-1',
    'email': 'ana@test.com',
    'displayName': 'Ana Perez',
    'firstName': 'Ana',
    'lastName': 'Perez',
    'role': role,
    'blocked': blocked,
    'blockReason': blockReason,
    'driver': driver,
    'passenger': null,
  };

  final approvedDriver = <String, dynamic>{
    'phoneNumber': '0991112222',
    'photoUrl': 'https://p/ana.jpg',
    'rating': 4.5,
    'approvalStatus': 'approved',
    'rejectionReason': null,
    'language': 'es',
    'vehicle': {
      'vehicleId': 'v-1',
      'plate': 'PBX-1234',
      'brand': 'Toyota',
      'model': 'Corolla',
      'year': 2020,
      'color': 'Amarillo',
      'registrationNumber': 'REG-1',
      'verificationStatus': 'pending',
    },
    'online': false,
    'onRide': false,
  };

  group('getDriver', () {
    test('maps /api/me to the driver entity', () async {
      when(() => dio.get('/api/me')).thenAnswer(
        (_) async => ok(me(driver: approvedDriver)),
      );

      final result = await repository.getDriver(driverId: 'uid-1');

      final driver = result.getOrElse(() => null)!;
      expect(driver.id, 'uid-1');
      expect(driver.firstName, 'Ana');
      expect(driver.lastName, 'Perez');
      expect(driver.email, 'ana@test.com');
      expect(driver.phoneNumber, '0991112222');
      expect(driver.photoUrl, 'https://p/ana.jpg');
      expect(driver.rating, 4.5);
      expect(driver.approvalStatus, 'approved');
      expect(driver.isBlocked, isFalse);
      expect(driver.role, 'driver', reason: 'el rol base es un conductor aqui');
    });

    test('returns Right(null) when the person has no driver profile', () async {
      when(() => dio.get('/api/me')).thenAnswer((_) async => ok(me()));

      final result = await repository.getDriver(driverId: 'uid-1');

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => null), isNull);
    });

    test('carries blocked state and reason', () async {
      when(() => dio.get('/api/me')).thenAnswer(
        (_) async => ok(
          me(driver: approvedDriver, blocked: true, blockReason: 'Quejas'),
        ),
      );

      final driver = (await repository.getDriver(
        driverId: 'uid-1',
      )).getOrElse(() => null)!;

      expect(driver.isBlocked, isTrue);
      expect(driver.blockReason, 'Quejas');
    });

    test('carries the rejection reason', () async {
      when(() => dio.get('/api/me')).thenAnswer(
        (_) async => ok(
          me(
            driver: {
              ...approvedDriver,
              'approvalStatus': 'rejected',
              'rejectionReason': 'Fotos borrosas',
            },
          ),
        ),
      );

      final driver = (await repository.getDriver(
        driverId: 'uid-1',
      )).getOrElse(() => null)!;

      expect(driver.approvalStatus, 'rejected');
      expect(driver.rejectionReason, 'Fotos borrosas');
    });

    test('keeps the admin role as is', () async {
      when(() => dio.get('/api/me')).thenAnswer(
        (_) async => ok(me(driver: approvedDriver, role: 'admin')),
      );

      final driver = (await repository.getDriver(
        driverId: 'uid-1',
      )).getOrElse(() => null)!;

      expect(driver.role, 'admin');
    });

    test('returns a failure when the request fails', () async {
      when(() => dio.get('/api/me')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/me')),
      );

      final result = await repository.getDriver(driverId: 'uid-1');

      expect(
        result.fold((f) => f.code, (_) => null),
        FailureCode.driverProfileCheckFailed,
      );
    });
  });

  group('getVehicle', () {
    test('maps the embedded vehicle', () async {
      when(() => dio.get('/api/me')).thenAnswer(
        (_) async => ok(me(driver: approvedDriver)),
      );

      final vehicle = (await repository.getVehicle(
        vehicleId: 'v-1',
      )).getOrElse(() => null)!;

      expect(vehicle.vehicleId, 'v-1');
      expect(vehicle.driverId, 'uid-1');
      expect(vehicle.plate, 'PBX-1234');
      expect(vehicle.year, 2020);
      expect(vehicle.verificationStatus, 'pending');
    });

    test('returns Right(null) when there is no vehicle', () async {
      when(() => dio.get('/api/me')).thenAnswer(
        (_) async => ok(me(driver: {...approvedDriver, 'vehicle': null})),
      );

      final result = await repository.getVehicle(vehicleId: 'v-1');

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => null), isNull);
    });

    test('returns a failure when the request fails', () async {
      when(() => dio.get('/api/me')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/me')),
      );

      final result = await repository.getVehicle(vehicleId: 'v-1');

      expect(
        result.fold((f) => f.code, (_) => null),
        FailureCode.vehicleFetchFailed,
      );
    });
  });

  group('registerDriver', () {
    final driver = DriverEntity(
      id: 'uid-1',
      firstName: 'Ana',
      lastName: 'Perez',
      email: 'ana@test.com',
      phoneNumber: '0991112222',
      photoUrl: 'https://google/photo.jpg',
    );
    final vehicle = VehicleEntity(
      vehicleId: '',
      driverId: 'uid-1',
      plate: 'PBX-1234',
      brand: 'Toyota',
      model: 'Corolla',
      year: 2020,
      color: 'Amarillo',
      registrationNumber: 'REG-1',
    );

    Response<dynamic> saved() => Response(
      requestOptions: RequestOptions(path: '/api/me/driver-profile'),
      statusCode: 200,
      data: <String, dynamic>{},
    );

    void stubPut() {
      when(
        () => dio.put(
          '/api/me/driver-profile',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => saved());
    }

    Map<String, dynamic> sentBody() {
      return verify(
        () => dio.put(
          '/api/me/driver-profile',
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured.single as Map<String, dynamic>;
    }

    test(
      'sends the profile to the server without touching Storage when there '
      'is no new photo',
      () async {
        stubPut();

        final result = await repository.registerDriver(
          driver: driver,
          vehicle: vehicle,
        );

        expect(result.isRight(), isTrue);
        expect(uploadedPath, isNull);
        final body = sentBody();
        expect(body['firstName'], 'Ana');
        expect(body['lastName'], 'Perez');
        expect(body['phoneNumber'], '0991112222');
        expect(body['photoUrl'], 'https://google/photo.jpg');
        expect(body['vehicle'], {
          'plate': 'PBX-1234',
          'brand': 'Toyota',
          'model': 'Corolla',
          'year': 2020,
          'color': 'Amarillo',
          'registrationNumber': 'REG-1',
        });
      },
    );

    test(
      'uploads the new photo under the driver uid and sends its URL',
      () async {
        stubPut();

        await repository.registerDriver(
          driver: driver,
          vehicle: vehicle,
          profileImage: File('photo.jpg'),
        );

        expect(uploadedPath, 'driver_profile_photos/uid-1.jpg');
        expect(sentBody()['photoUrl'], 'https://storage/photo.jpg');
      },
    );

    test('omits photoUrl when the driver has none', () async {
      stubPut();

      await repository.registerDriver(
        driver: driver.copyWith(photoUrl: ''),
        vehicle: vehicle,
      );

      expect(sentBody().containsKey('photoUrl'), isFalse);
    });

    test('returns profileSaveFailed when the server rejects it', () async {
      when(
        () => dio.put(
          '/api/me/driver-profile',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/me/driver-profile'),
        ),
      );

      final result = await repository.registerDriver(
        driver: driver,
        vehicle: vehicle,
      );

      expect(
        result.fold((f) => f.code, (_) => null),
        FailureCode.profileSaveFailed,
      );
    });

    test('returns profileSaveFailed when the photo upload fails', () async {
      final failing = DriverProfileRepositoryImpl(
        dio: dio,
        photoUploader: ({required String path, required File file}) async {
          throw Exception('storage down');
        },
      );

      final result = await failing.registerDriver(
        driver: driver,
        vehicle: vehicle,
        profileImage: File('photo.jpg'),
      );

      expect(
        result.fold((f) => f.code, (_) => null),
        FailureCode.profileSaveFailed,
      );
      verifyNever(
        () => dio.put(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });
  });
}
