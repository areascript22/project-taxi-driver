import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/shared/battery_optimization/service/battery_optimization_service.dart';
import 'package:driver_app/shared/foreground_location/presentation/bloc/foreground_service_bloc.dart';
import 'package:driver_app/shared/foreground_location/service/driver_foreground_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDriverForegroundService extends Mock
    implements DriverForegroundService {}

class MockBatteryOptimizationService extends Mock
    implements BatteryOptimizationService {}

void main() {
  late MockDriverForegroundService foregroundService;
  late MockBatteryOptimizationService batteryService;

  setUp(() {
    foregroundService = MockDriverForegroundService();
    batteryService = MockBatteryOptimizationService();
    when(() => foregroundService.start()).thenAnswer((_) async {});
    when(() => foregroundService.stop()).thenAnswer((_) async {});
  });

  ForegroundServiceBloc buildBloc() => ForegroundServiceBloc(
    driverForegroundService: foregroundService,
    batteryOptimizationService: batteryService,
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
          (_) async => Left(Failure(message: 'no disponible')),
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
}
