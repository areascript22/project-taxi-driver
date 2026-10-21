import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/shared/battery_optimization/service/battery_optimization_service.dart';
import 'package:driver_app/shared/domain/entity/user_location.dart';
import 'package:driver_app/shared/geolocator/service/geolocator/geolocator_service.dart';
import 'package:driver_app/shared/presence/domain/repository/driver_presence_repository.dart';
import 'package:driver_app/shared/foreground_location/presentation/bloc/foreground_service_bloc.dart';
import 'package:driver_app/shared/foreground_location/service/driver_foreground_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDriverForegroundService extends Mock
    implements DriverForegroundService {}

class MockBatteryOptimizationService extends Mock
    implements BatteryOptimizationService {}

class MockDriverPresenceRepository extends Mock
    implements DriverPresenceRepository {}

class MockGeolocatorService extends Mock implements GeolocatorService {}

void main() {
  late MockDriverForegroundService foregroundService;
  late MockBatteryOptimizationService batteryService;
  late MockDriverPresenceRepository presenceRepository;
  late MockGeolocatorService geolocatorService;
  late StreamController<FailureCode?> locationIssues;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  tearDown(() async {
    await locationIssues.close();
  });

  setUp(() {
    foregroundService = MockDriverForegroundService();
    batteryService = MockBatteryOptimizationService();
    presenceRepository = MockDriverPresenceRepository();
    geolocatorService = MockGeolocatorService();
    locationIssues = StreamController<FailureCode?>.broadcast();
    when(() => foregroundService.locationIssue).thenAnswer((_) => locationIssues.stream);
    when(() => foregroundService.requestLocationStatus()).thenAnswer((_) async {});
    // Por defecto hay ubicacion: las pruebas de otros temas no se ven afectadas.
    when(
      () => geolocatorService.getCurrentPosition(timeLimit: any(named: 'timeLimit')),
    ).thenAnswer(
      (_) async => Right(UserLocation(latitude: -1.67, longitude: -78.65)),
    );
    when(() => geolocatorService.openLocationSettings()).thenAnswer((_) async => const Right(true));
    when(() => geolocatorService.openAppSettings()).thenAnswer((_) async => const Right(true));
    // Por defecto el servidor no responde: el bloc cae al estado local, que es
    // lo que probaban las pruebas anteriores a la sincronizacion.
    when(() => presenceRepository.fetchOnline()).thenAnswer(
      (_) async => Left(Failure(code: FailureCode.onlineFailed)),
    );
    when(() => foregroundService.start()).thenAnswer((_) async {});
    when(() => foregroundService.stop()).thenAnswer((_) async {});
    // Por defecto el servidor acepta el cambio de estado.
    when(
      () => presenceRepository.setOnline(online: any(named: 'online')),
    ).thenAnswer((_) async => const Right(unit));
  });

  ForegroundServiceBloc buildBloc() => ForegroundServiceBloc(
    driverForegroundService: foregroundService,
    batteryOptimizationService: batteryService,
    driverPresenceRepository: presenceRepository,
    geolocatorService: geolocatorService,
  );

  test('initial state is off, unprocessed and status not yet loaded', () {
    final state = buildBloc().state;
    expect(state.isRunning, isFalse);
    expect(state.hasLoadedStatus, isFalse);
    expect(state.isBatteryOptimizationIgnored, isFalse);
    expect(state.batteryPromptStep, BatteryOptimizationPromptStep.none);
  });

  group('ForegroundServiceStatusRequested', () {
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'reflects a service already running with battery permission granted',
      setUp: () {
        when(() => foregroundService.isRunning()).thenAnswer((_) async => true);
        when(
          () => batteryService.isIgnoringBatteryOptimizations(),
        ).thenAnswer((_) async => const Right(true));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => s.isRunning && s.hasLoadedStatus && s.isBatteryOptimizationIgnored,
        ),
      ],
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'treats a battery-check failure as "not ignored" without throwing',
      setUp: () {
        when(() => foregroundService.isRunning()).thenAnswer((_) async => false);
        when(() => batteryService.isIgnoringBatteryOptimizations()).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.unexpected)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) =>
              !s.isRunning &&
              s.hasLoadedStatus &&
              !s.isBatteryOptimizationIgnored,
        ),
      ],
    );
  });

  group('ForegroundServiceToggled (turning off)', () {
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'stops the service; never requires the battery permission',
      build: buildBloc,
      seed: () => const ForegroundServiceState(isRunning: true, hasLoadedStatus: true),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      expect: () => [
        predicate<ForegroundServiceState>((s) => s.isProcessing),
        predicate<ForegroundServiceState>(
          (s) => !s.isRunning && !s.isProcessing && s.hasLoadedStatus,
        ),
      ],
      verify: (_) {
        verify(() => foregroundService.stop()).called(1);
        verifyNever(() => batteryService.isIgnoringBatteryOptimizations());
      },
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'tells the server the driver is offline before stopping the service',
      build: buildBloc,
      seed: () => const ForegroundServiceState(isRunning: true, hasLoadedStatus: true),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      verify: (_) {
        verifyInOrder([
          () => presenceRepository.setOnline(online: false),
          () => foregroundService.stop(),
        ]);
      },
    );

    // Apagar nunca se bloquea por la red: si el servidor no se entera, la
    // ubicación deja de llegar y por frescura sale solo del despacho.
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'still stops the service when the server cannot be told',
      setUp: () {
        when(
          () => presenceRepository.setOnline(online: false),
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.onlineFailed)));
      },
      build: buildBloc,
      seed: () => const ForegroundServiceState(isRunning: true, hasLoadedStatus: true),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      expect: () => [
        predicate<ForegroundServiceState>((s) => s.isProcessing),
        predicate<ForegroundServiceState>(
          (s) => !s.isRunning && !s.isProcessing && s.errorCode == null,
        ),
      ],
      verify: (_) {
        verify(() => foregroundService.stop()).called(1);
      },
    );
  });

  group('ForegroundServiceToggled (turning on)', () {
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'starts the service immediately when battery permission is already granted',
      build: buildBloc,
      seed: () => const ForegroundServiceState(
        isRunning: false,
        isBatteryOptimizationIgnored: true,
      ),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      expect: () => [
        predicate<ForegroundServiceState>((s) => s.isProcessing),
        predicate<ForegroundServiceState>(
          (s) => s.isRunning && !s.isProcessing && s.hasLoadedStatus,
        ),
      ],
      verify: (_) {
        verify(() => foregroundService.start()).called(1);
      },
    );

    // El servidor decide si puede estar en línea: se le pregunta ANTES de
    // arrancar el servicio.
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'asks the server first and only then starts the service',
      build: buildBloc,
      seed: () => const ForegroundServiceState(isBatteryOptimizationIgnored: true),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      verify: (_) {
        verifyInOrder([
          () => presenceRepository.setOnline(online: true),
          () => foregroundService.start(),
        ]);
      },
    );

    for (final code in [
      FailureCode.onlineNotAllowed,
      FailureCode.driverProfileNotReady,
      FailureCode.onlineFailed,
    ]) {
      blocTest<ForegroundServiceBloc, ForegroundServiceState>(
        'does not start the service and reports $code when the server rejects going online',
        setUp: () {
          when(
            () => presenceRepository.setOnline(online: true),
          ).thenAnswer((_) async => Left(Failure(code: code)));
        },
        build: buildBloc,
        seed: () => const ForegroundServiceState(isBatteryOptimizationIgnored: true),
        act: (bloc) => bloc.add(ForegroundServiceToggled()),
        expect: () => [
          predicate<ForegroundServiceState>((s) => s.isProcessing),
          predicate<ForegroundServiceState>(
            (s) =>
                !s.isRunning &&
                !s.isProcessing &&
                s.hasLoadedStatus &&
                s.errorCode == code,
          ),
        ],
        verify: (_) {
          verifyNever(() => foregroundService.start());
        },
      );
    }

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'clears a previous error on the next state change',
      build: buildBloc,
      seed: () => const ForegroundServiceState(
        isBatteryOptimizationIgnored: true,
        errorCode: FailureCode.onlineNotAllowed,
      ),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      expect: () => [
        predicate<ForegroundServiceState>((s) => s.isProcessing && s.errorCode == null),
        predicate<ForegroundServiceState>((s) => s.isRunning && s.errorCode == null),
      ],
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'shows the rationale dialog instead of starting when permission is missing',
      build: buildBloc,
      seed: () => const ForegroundServiceState(isBatteryOptimizationIgnored: false),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => s.batteryPromptStep == BatteryOptimizationPromptStep.rationale,
        ),
      ],
      verify: (_) {
        verifyNever(() => foregroundService.start());
      },
    );
  });

  group('BatteryOptimizationPromptDismissed', () {
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'clears the rationale prompt without starting the service',
      build: buildBloc,
      seed: () => const ForegroundServiceState(
        batteryPromptStep: BatteryOptimizationPromptStep.rationale,
      ),
      act: (bloc) => bloc.add(BatteryOptimizationPromptDismissed()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => s.batteryPromptStep == BatteryOptimizationPromptStep.none,
        ),
      ],
      verify: (_) {
        verifyNever(() => foregroundService.start());
      },
    );
  });

  group('BatteryOptimizationSettingsOpened', () {
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'opens settings without emitting a new state',
      setUp: () {
        when(() => batteryService.openAppSettings()).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(BatteryOptimizationSettingsOpened()),
      expect: () => [],
      verify: (_) {
        verify(() => batteryService.openAppSettings()).called(1);
      },
    );
  });

  group('BatteryOptimizationPermissionRequested', () {
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'grants immediately and starts the service without polling',
      setUp: () {
        when(
          () => batteryService.requestIgnoreBatteryOptimizations(),
        ).thenAnswer((_) async => const Right(true));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(BatteryOptimizationPermissionRequested()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => s.isProcessing && s.batteryPromptStep == BatteryOptimizationPromptStep.none,
        ),
        predicate<ForegroundServiceState>(
          (s) => s.isBatteryOptimizationIgnored && s.isProcessing,
        ),
        // _startService re-emits an equivalent isProcessing:true state (new
        // instance, so it isn't deduped by the Bloc's identity check) before
        // the final "running" state.
        predicate<ForegroundServiceState>(
          (s) => s.isProcessing && s.isBatteryOptimizationIgnored && !s.isRunning,
        ),
        predicate<ForegroundServiceState>(
          (s) => s.isRunning && !s.isProcessing,
        ),
      ],
      verify: (_) {
        verifyNever(() => batteryService.isIgnoringBatteryOptimizations());
        verify(() => foregroundService.start()).called(1);
      },
    );

    test(
      'polls up to 8 times (~9.6s) and shows the denied banner if never granted',
      () {
        fakeAsync((async) {
          when(
            () => batteryService.requestIgnoreBatteryOptimizations(),
          ).thenAnswer((_) async => const Right(false));
          when(
            () => batteryService.isIgnoringBatteryOptimizations(),
          ).thenAnswer((_) async => const Right(false));

          final bloc = buildBloc();
          final states = <ForegroundServiceState>[];
          bloc.stream.listen(states.add);

          bloc.add(BatteryOptimizationPermissionRequested());
          async.elapse(const Duration(seconds: 15));

          expect(
            bloc.state.batteryPromptStep,
            BatteryOptimizationPromptStep.deniedBanner,
          );
          expect(bloc.state.isBatteryOptimizationIgnored, isFalse);
          expect(bloc.state.isProcessing, isFalse);
          verify(() => batteryService.isIgnoringBatteryOptimizations()).called(8);
          verifyNever(() => foregroundService.start());

          bloc.close();
        });
      },
    );

    test('polling stops early and starts the service as soon as it is granted', () {
      fakeAsync((async) {
        when(
          () => batteryService.requestIgnoreBatteryOptimizations(),
        ).thenAnswer((_) async => const Right(false));

        var pollCall = 0;
        when(() => batteryService.isIgnoringBatteryOptimizations()).thenAnswer((
          _,
        ) async {
          pollCall++;
          return Right(pollCall >= 3);
        });

        final bloc = buildBloc();
        bloc.add(BatteryOptimizationPermissionRequested());
        async.elapse(const Duration(seconds: 15));

        expect(bloc.state.isBatteryOptimizationIgnored, isTrue);
        expect(bloc.state.isRunning, isTrue);
        verify(() => batteryService.isIgnoringBatteryOptimizations()).called(3);
        verify(() => foregroundService.start()).called(1);

        bloc.close();
      });
    });

    test(
      'a newer poll (second request) supersedes a stale one in flight',
      () {
        fakeAsync((async) {
          when(
            () => batteryService.requestIgnoreBatteryOptimizations(),
          ).thenAnswer((_) async => const Right(false));
          when(
            () => batteryService.isIgnoringBatteryOptimizations(),
          ).thenAnswer((_) async => const Right(false));

          final bloc = buildBloc();
          bloc.add(BatteryOptimizationPermissionRequested());
          async.elapse(const Duration(milliseconds: 100));
          // Second tap ("Reintentar") starts a newer poll while the first
          // one is still in flight -- the first poll must not clobber the
          // outcome once it eventually resolves.
          bloc.add(BatteryOptimizationPermissionRequested());
          async.elapse(const Duration(seconds: 15));

          // Only the second poll's terminal state should apply.
          expect(
            bloc.state.batteryPromptStep,
            BatteryOptimizationPromptStep.deniedBanner,
          );

          bloc.close();
        });
      },
    );
  });

  group('BatteryOptimizationStatusRechecked', () {
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'is a no-op when the permission was already known to be granted',
      build: buildBloc,
      seed: () => const ForegroundServiceState(isBatteryOptimizationIgnored: true),
      act: (bloc) => bloc.add(BatteryOptimizationStatusRechecked()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => batteryService.isIgnoringBatteryOptimizations());
      },
    );

    test(
      'resumes the pending "go online" intent once the recheck confirms the grant',
      () {
        fakeAsync((async) {
          when(
            () => batteryService.requestIgnoreBatteryOptimizations(),
          ).thenAnswer((_) async => const Right(false));
          when(
            () => batteryService.isIgnoringBatteryOptimizations(),
          ).thenAnswer((_) async => const Right(false));

          final bloc = buildBloc();
          // First: user requests permission, it's denied after polling out ->
          // pendingGoOnline is left true only via the toggle path, so first
          // toggle ON to set _pendingGoOnline, then request permission.
          bloc.add(ForegroundServiceToggled());
          async.flushMicrotasks();
          bloc.add(BatteryOptimizationPermissionRequested());
          async.elapse(const Duration(seconds: 15));

          expect(
            bloc.state.batteryPromptStep,
            BatteryOptimizationPromptStep.deniedBanner,
          );

          // Now the user goes to Settings manually and grants it; app resumes
          // and fires a silent recheck.
          when(
            () => batteryService.isIgnoringBatteryOptimizations(),
          ).thenAnswer((_) async => const Right(true));
          bloc.add(BatteryOptimizationStatusRechecked());
          async.elapse(const Duration(seconds: 2));

          expect(bloc.state.isBatteryOptimizationIgnored, isTrue);
          expect(bloc.state.isRunning, isTrue);

          bloc.close();
        });
      },
    );

    test(
      'clears a stale denied banner when the recheck finds it granted without a pending intent',
      () {
        fakeAsync((async) {
          when(
            () => batteryService.isIgnoringBatteryOptimizations(),
          ).thenAnswer((_) async => const Right(true));

          final bloc = buildBloc();
          bloc.emit(
            const ForegroundServiceState(
              isBatteryOptimizationIgnored: false,
              batteryPromptStep: BatteryOptimizationPromptStep.deniedBanner,
            ),
          );

          bloc.add(BatteryOptimizationStatusRechecked());
          async.elapse(const Duration(seconds: 2));

          expect(bloc.state.isBatteryOptimizationIgnored, isTrue);
          expect(bloc.state.batteryPromptStep, BatteryOptimizationPromptStep.none);
          expect(bloc.state.isRunning, isFalse);
          verifyNever(() => foregroundService.start());

          bloc.close();
        });
      },
    );
  });

  // ===== El servidor es la fuente de verdad del interruptor =====
  group('ForegroundServiceStatusRequested (reconcile with the server)', () {
    void stubLocal({required bool running, required bool batteryIgnored}) {
      when(() => foregroundService.isRunning()).thenAnswer((_) async => running);
      when(
        () => batteryService.isIgnoringBatteryOptimizations(),
      ).thenAnswer((_) async => Right(batteryIgnored));
    }

    void stubServer({required bool online}) {
      when(() => presenceRepository.fetchOnline()).thenAnswer((_) async => Right(online));
    }

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'server online + service running: stays on, nothing is stopped or started, and asks the service for its location status',
      setUp: () {
        stubLocal(running: true, batteryIgnored: true);
        stubServer(online: true);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => s.isRunning && s.hasLoadedStatus && !s.disconnectedByServer,
        ),
      ],
      verify: (_) {
        verifyNever(() => foregroundService.stop());
        verifyNever(() => foregroundService.start());
        verify(() => foregroundService.requestLocationStatus()).called(1);
      },
    );

    // El caso que se reportaba: el interruptor aparecia ENCENDIDO (el servicio
    // de Android seguia vivo, apagandose) mientras la base decia is_online=false.
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'server OFFLINE + service still running: the server wins -> stops the service, shows off and flags it',
      setUp: () {
        stubLocal(running: true, batteryIgnored: true);
        stubServer(online: false);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => !s.isRunning && s.hasLoadedStatus && s.disconnectedByServer,
        ),
      ],
      verify: (_) {
        verify(() => foregroundService.stop()).called(1);
        verifyNever(() => foregroundService.requestLocationStatus());
      },
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'server online + service dead + battery permission ok: resumes the service without asking the server again',
      setUp: () {
        stubLocal(running: false, batteryIgnored: true);
        stubServer(online: true);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => s.isRunning && s.hasLoadedStatus && !s.disconnectedByServer,
        ),
      ],
      verify: (_) {
        verify(() => foregroundService.start()).called(1);
        verifyNever(() => presenceRepository.setOnline(online: any(named: 'online')));
      },
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'server online + service dead + NO battery permission: cannot keep it alive -> tells the server offline and stays off',
      setUp: () {
        stubLocal(running: false, batteryIgnored: false);
        stubServer(online: true);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => [
        predicate<ForegroundServiceState>((s) => !s.isRunning && s.hasLoadedStatus),
      ],
      verify: (_) {
        verify(() => presenceRepository.setOnline(online: false)).called(1);
        verifyNever(() => foregroundService.start());
      },
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'server offline + service not running: both agree, nothing to do',
      setUp: () {
        stubLocal(running: false, batteryIgnored: true);
        stubServer(online: false);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => !s.isRunning && s.hasLoadedStatus && !s.disconnectedByServer,
        ),
      ],
      verify: (_) {
        verifyNever(() => foregroundService.stop());
        verifyNever(() => foregroundService.start());
      },
    );

    // Sin red no se adivina: se queda con lo local y se reconcilia en el
    // siguiente resume.
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'server unreachable: keeps the local status and does not touch the service',
      setUp: () {
        stubLocal(running: true, batteryIgnored: true);
        // fetchOnline ya falla por defecto en setUp.
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => s.isRunning && s.hasLoadedStatus && !s.disconnectedByServer,
        ),
      ],
      verify: (_) {
        verifyNever(() => foregroundService.stop());
        verifyNever(() => foregroundService.start());
      },
    );

    // Una conexion o desconexion en curso decide ella como termina.
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'is ignored while a connect/disconnect is in flight (no reading of a half-changed server state)',
      build: buildBloc,
      seed: () => const ForegroundServiceState(isProcessing: true, hasLoadedStatus: true),
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => <ForegroundServiceState>[],
      verify: (_) {
        verifyNever(() => presenceRepository.fetchOnline());
        verifyNever(() => foregroundService.isRunning());
      },
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'drops a stale location issue when the driver is not connected',
      setUp: () {
        stubLocal(running: false, batteryIgnored: true);
        stubServer(online: false);
      },
      build: buildBloc,
      seed: () => const ForegroundServiceState(locationIssue: FailureCode.gpsDisabled),
      act: (bloc) => bloc.add(ForegroundServiceStatusRequested()),
      expect: () => [
        predicate<ForegroundServiceState>((s) => !s.isRunning && s.locationIssue == null),
      ],
    );
  });

  // ===== No se conecta a quien no tiene ubicacion =====
  group('ForegroundServiceToggled (turning on) requires a usable location', () {
    for (final code in [
      FailureCode.gpsDisabled,
      FailureCode.locationPermissionDenied,
      FailureCode.locationUnavailable,
    ]) {
      blocTest<ForegroundServiceBloc, ForegroundServiceState>(
        'does not go online and explains $code when the GPS cannot give a position',
        setUp: () {
          when(
            () => geolocatorService.getCurrentPosition(timeLimit: any(named: 'timeLimit')),
          ).thenAnswer((_) async => Left(Failure(code: code)));
        },
        build: buildBloc,
        seed: () => const ForegroundServiceState(isBatteryOptimizationIgnored: true),
        act: (bloc) => bloc.add(ForegroundServiceToggled()),
        expect: () => [
          predicate<ForegroundServiceState>((s) => s.isProcessing),
          predicate<ForegroundServiceState>(
            (s) =>
                !s.isRunning &&
                !s.isProcessing &&
                s.errorCode == code &&
                s.locationIssue == code,
          ),
        ],
        verify: (_) {
          verifyNever(() => presenceRepository.setOnline(online: any(named: 'online')));
          verifyNever(() => foregroundService.start());
        },
      );
    }

    // Un error de GPS desconocido igual significa "sin ubicacion": se le dice
    // asi al conductor, no un mensaje generico que no le sirve.
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'maps an unknown GPS error to locationUnavailable',
      setUp: () {
        when(
          () => geolocatorService.getCurrentPosition(timeLimit: any(named: 'timeLimit')),
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.unexpected)));
      },
      build: buildBloc,
      seed: () => const ForegroundServiceState(isBatteryOptimizationIgnored: true),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      expect: () => [
        predicate<ForegroundServiceState>((s) => s.isProcessing),
        predicate<ForegroundServiceState>(
          (s) =>
              s.errorCode == FailureCode.locationUnavailable &&
              s.locationIssue == FailureCode.locationUnavailable,
        ),
      ],
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'checks the GPS BEFORE asking the server, with a 15 s limit',
      build: buildBloc,
      seed: () => const ForegroundServiceState(isBatteryOptimizationIgnored: true),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      verify: (_) {
        verifyInOrder([
          () => geolocatorService.getCurrentPosition(timeLimit: const Duration(seconds: 15)),
          () => presenceRepository.setOnline(online: true),
          () => foregroundService.start(),
        ]);
      },
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'a successful connection clears an old location issue',
      build: buildBloc,
      seed: () => const ForegroundServiceState(
        isBatteryOptimizationIgnored: true,
        locationIssue: FailureCode.gpsDisabled,
      ),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      expect: () => [
        predicate<ForegroundServiceState>((s) => s.isProcessing),
        predicate<ForegroundServiceState>((s) => s.isRunning && s.locationIssue == null),
      ],
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'turning off clears the location issue',
      build: buildBloc,
      seed: () => const ForegroundServiceState(
        isRunning: true,
        hasLoadedStatus: true,
        locationIssue: FailureCode.locationUnavailable,
      ),
      act: (bloc) => bloc.add(ForegroundServiceToggled()),
      expect: () => [
        predicate<ForegroundServiceState>((s) => s.isProcessing),
        predicate<ForegroundServiceState>((s) => !s.isRunning && s.locationIssue == null),
      ],
    );
  });

  // ===== El servicio avisa si pierde la ubicacion estando en linea =====
  group('location issue reported by the background service', () {
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'while online: surfaces the issue and clears it when the location comes back',
      build: buildBloc,
      seed: () => const ForegroundServiceState(isRunning: true, hasLoadedStatus: true),
      act: (bloc) async {
        locationIssues.add(FailureCode.gpsDisabled);
        await Future<void>.delayed(Duration.zero);
        locationIssues.add(null);
      },
      wait: const Duration(milliseconds: 20),
      expect: () => [
        predicate<ForegroundServiceState>((s) => s.locationIssue == FailureCode.gpsDisabled),
        predicate<ForegroundServiceState>((s) => s.locationIssue == null),
      ],
    );

    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'the same issue twice is shown once',
      build: buildBloc,
      seed: () => const ForegroundServiceState(isRunning: true, hasLoadedStatus: true),
      act: (bloc) async {
        locationIssues.add(FailureCode.locationUnavailable);
        await Future<void>.delayed(Duration.zero);
        locationIssues.add(FailureCode.locationUnavailable);
      },
      wait: const Duration(milliseconds: 20),
      expect: () => [
        predicate<ForegroundServiceState>(
          (s) => s.locationIssue == FailureCode.locationUnavailable,
        ),
      ],
    );

    // Un aviso tardio de un servicio que ya se esta apagando no cuenta.
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'is ignored when the driver is not online',
      build: buildBloc,
      seed: () => const ForegroundServiceState(hasLoadedStatus: true),
      act: (bloc) async => locationIssues.add(FailureCode.gpsDisabled),
      wait: const Duration(milliseconds: 20),
      expect: () => <ForegroundServiceState>[],
    );

    test('closing the bloc cancels the subscription to the service', () async {
      final bloc = buildBloc();
      expect(locationIssues.hasListener, isTrue);

      await bloc.close();

      expect(locationIssues.hasListener, isFalse);
    });
  });

  group('LocationSettingsOpened', () {
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'opens the device location settings for a GPS/accuracy problem',
      build: buildBloc,
      seed: () => const ForegroundServiceState(locationIssue: FailureCode.gpsDisabled),
      act: (bloc) => bloc.add(LocationSettingsOpened()),
      verify: (_) {
        verify(() => geolocatorService.openLocationSettings()).called(1);
        verifyNever(() => geolocatorService.openAppSettings());
      },
    );

    // Con el permiso denegado los ajustes del dispositivo no sirven: el cambio
    // se hace en los permisos de la app.
    blocTest<ForegroundServiceBloc, ForegroundServiceState>(
      'opens the APP settings when the problem is the location permission',
      build: buildBloc,
      seed: () => const ForegroundServiceState(
        locationIssue: FailureCode.locationPermissionDenied,
      ),
      act: (bloc) => bloc.add(LocationSettingsOpened()),
      verify: (_) {
        verify(() => geolocatorService.openAppSettings()).called(1);
        verifyNever(() => geolocatorService.openLocationSettings());
      },
    );
  });
}
