import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/driver_profile/domain/entity/driver_entity.dart';
import 'package:driver_app/feature/driver_profile/domain/repository/driver_profile_repository.dart';
import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/feature/trip/domain/repository/trip_repository.dart';
import 'package:driver_app/shared/domain/entity/user_entity.dart';
import 'package:driver_app/shared/domain/repository/session_repository.dart';
import 'package:driver_app/shared/feature/session/presentation/bloc/session/session_bloc.dart';
import 'package:driver_app/shared/notifications/service/push_notifications_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockTripRepository extends Mock implements TripRepository {}

class MockDriverProfileRepository extends Mock
    implements DriverProfileRepository {}

class MockPushNotificationsService extends Mock
    implements PushNotificationsService {}

DriverEntity _driver({String role = 'driver'}) {
  return DriverEntity(
    id: 'u1',
    firstName: 'Juan',
    lastName: 'Perez',
    email: 'j@example.com',
    phoneNumber: '123',
    role: role,
  );
}

void main() {
  late MockSessionRepository sessionRepository;
  late MockTripRepository tripRepository;
  late MockDriverProfileRepository driverProfileRepository;
  late MockPushNotificationsService pushNotificationsService;
  late StreamController<String> tokenRefreshController;

  final user = UserEntity(id: 'u1', email: 'j@example.com');

  setUp(() {
    sessionRepository = MockSessionRepository();
    tripRepository = MockTripRepository();
    driverProfileRepository = MockDriverProfileRepository();
    pushNotificationsService = MockPushNotificationsService();
    tokenRefreshController = StreamController<String>.broadcast();

    when(
      () => pushNotificationsService.onTokenRefresh,
    ).thenAnswer((_) => tokenRefreshController.stream);
    when(
      () => pushNotificationsService.getToken(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => driverProfileRepository.updateFcmToken(
        driverId: any(named: 'driverId'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => Right(unit));
  });

  tearDown(() {
    tokenRefreshController.close();
  });

  SessionBloc buildBloc() => SessionBloc(
    sessionRepository: sessionRepository,
    tripRepository: tripRepository,
    driverProfileRepository: driverProfileRepository,
    pushNotificationsService: pushNotificationsService,
  );

  test('initial state is SessionUnknown', () {
    expect(buildBloc().state, isA<SessionUnknown>());
  });

  group('SessionCheckRequested', () {
    blocTest<SessionBloc, SessionState>(
      'emits SessionUnauthenticated when there is no authenticated user',
      setUp: () {
        when(() => sessionRepository.isUserAuthenticated()).thenAnswer(
          (_) async => Left(Failure(message: 'no session')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [isA<SessionUnauthenticated>()],
      verify: (_) {
        verifyNever(
          () => driverProfileRepository.getDriver(
            driverId: any(named: 'driverId'),
          ),
        );
      },
    );

    blocTest<SessionBloc, SessionState>(
      'emits SessionCheckFailed when the driver lookup fails',
      setUp: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => driverProfileRepository.getDriver(driverId: 'u1'),
        ).thenAnswer((_) async => Left(Failure(message: 'network')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [
        isA<SessionCheckFailed>().having((s) => s.user, 'user', user),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'emits SessionOnboardingRequired when the driver has no profile yet',
      setUp: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => driverProfileRepository.getDriver(driverId: 'u1'),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [
        isA<SessionOnboardingRequired>().having((s) => s.user, 'user', user),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'emits SessionAuthenticated with role and active trip when everything succeeds',
      setUp: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => driverProfileRepository.getDriver(driverId: 'u1'),
        ).thenAnswer((_) async => Right(_driver(role: 'admin')));
        when(() => tripRepository.findActiveTripForDriver()).thenAnswer(
          (_) async => Right(
            IncomingRequestEntity(
              rideId: 'r1',
              userId: 'p1',
              status: 'driverAssigned',
              createdAt: 0,
              updatedAt: 0,
              passenger: PassengerEntity(name: 'P', profileImage: ''),
              pickupLocation: PickupLocationEntity(
                address: 'x',
                latitude: 0,
                longitude: 0,
              ),
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [
        isA<SessionAuthenticated>()
            .having((s) => s.user, 'user', user)
            .having((s) => s.role, 'role', 'admin')
            .having((s) => s.activeTrip?.rideId, 'activeTrip', 'r1'),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'emits SessionAuthenticated with null activeTrip when the lookup fails',
      setUp: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => driverProfileRepository.getDriver(driverId: 'u1'),
        ).thenAnswer((_) async => Right(_driver()));
        when(() => tripRepository.findActiveTripForDriver()).thenAnswer(
          (_) async => Left(Failure(message: 'network')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [
        isA<SessionAuthenticated>().having(
          (s) => s.activeTrip,
          'activeTrip',
          isNull,
        ),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'registers the FCM token as a fire-and-forget side effect after authenticating',
      setUp: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => driverProfileRepository.getDriver(driverId: 'u1'),
        ).thenAnswer((_) async => Right(_driver()));
        when(
          () => tripRepository.findActiveTripForDriver(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => pushNotificationsService.getToken(),
        ).thenAnswer((_) async => const Right('token-123'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SessionCheckRequested()),
      wait: const Duration(milliseconds: 50),
      expect: () => [isA<SessionAuthenticated>()],
      verify: (_) {
        verify(
          () => driverProfileRepository.updateFcmToken(
            driverId: 'u1',
            token: 'token-123',
          ),
        ).called(1);
      },
    );

    blocTest<SessionBloc, SessionState>(
      'forwards a refreshed token to updateFcmToken via onTokenRefresh',
      setUp: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => driverProfileRepository.getDriver(driverId: 'u1'),
        ).thenAnswer((_) async => Right(_driver()));
        when(
          () => tripRepository.findActiveTripForDriver(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(SessionCheckRequested());
        await Future.delayed(const Duration(milliseconds: 20));
        tokenRefreshController.add('new-token');
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [isA<SessionAuthenticated>()],
      verify: (_) {
        verify(
          () => driverProfileRepository.updateFcmToken(
            driverId: 'u1',
            token: 'new-token',
          ),
        ).called(1);
      },
    );
  });

  group('SessionLogoutRequested', () {
    blocTest<SessionBloc, SessionState>(
      'emits SessionUnauthenticated on success',
      setUp: () {
        when(
          () => sessionRepository.signOut(),
        ).thenAnswer((_) async => Right(unit));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SessionLogoutRequested()),
      expect: () => [isA<SessionUnauthenticated>()],
    );

    blocTest<SessionBloc, SessionState>(
      'keeps the current state unchanged when sign out fails',
      setUp: () {
        when(
          () => sessionRepository.signOut(),
        ).thenAnswer((_) async => Left(Failure(message: 'error')));
      },
      build: buildBloc,
      seed: () => SessionAuthenticated(user: user),
      act: (bloc) => bloc.add(SessionLogoutRequested()),
      expect: () => [],
    );
  });
}
