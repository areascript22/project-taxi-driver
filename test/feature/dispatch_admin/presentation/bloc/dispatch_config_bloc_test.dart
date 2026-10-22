import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_config_entity.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_limits_entity.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_ring_entity.dart';
import 'package:driver_app/feature/dispatch_admin/domain/repository/dispatch_admin_repository.dart';
import 'package:driver_app/feature/dispatch_admin/presentation/bloc/dispatch_config_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDispatchAdminRepository extends Mock
    implements DispatchAdminRepository {}

const _limits = DispatchLimitsEntity(
  maxRings: 3,
  maxTotalWaitSeconds: 120,
  minLocationMaxAgeSeconds: 30,
  maxLocationMaxAgeSeconds: 600,
  minRadiusMeters: 100,
  maxRadiusMeters: 50000,
  minWaitSeconds: 1,
  maxWaitSeconds: 120,
  minMaxDrivers: 1,
  maxMaxDrivers: 100,
);

const _r1 = DispatchRingEntity(radiusMeters: 3000, waitSeconds: 10, maxDrivers: 10);
const _r2 = DispatchRingEntity(radiusMeters: 6000, waitSeconds: 10, maxDrivers: 10);

DispatchConfigEntity _config({
  List<DispatchRingEntity> rings = const [_r1, _r2],
  int maxAge = 45,
  int version = 0,
  bool adminsCanEdit = false,
  bool canEdit = true,
  bool canChangeAdminEditing = true,
}) => DispatchConfigEntity(
  rings: rings,
  locationMaxAgeSeconds: maxAge,
  adminsCanEdit: adminsCanEdit,
  version: version,
  updatedAt: null,
  updatedByName: '',
  totalWaitSeconds: rings.fold(0, (s, r) => s + r.waitSeconds),
  requestExpirySeconds: 35,
  canEdit: canEdit,
  canChangeAdminEditing: canChangeAdminEditing,
  limits: _limits,
);

void main() {
  late MockDispatchAdminRepository repository;

  setUpAll(() {
    registerFallbackValue(<DispatchRingEntity>[]);
  });

  setUp(() {
    repository = MockDispatchAdminRepository();
  });

  DispatchConfigBloc build() => DispatchConfigBloc(repository: repository);

  // Un bloc ya cargado: lo que hacen casi todas las pruebas de edición.
  Future<DispatchConfigBloc> loaded(DispatchConfigEntity config) async {
    when(() => repository.getConfig()).thenAnswer((_) async => Right(config));
    final bloc = build()..add(DispatchConfigLoadRequested());
    await bloc.stream.firstWhere((s) => s.config != null);
    return bloc;
  }

  test('initial state has no config and nothing to save', () {
    final state = build().state;

    expect(state.config, isNull);
    expect(state.canSave, isFalse);
    expect(state.isDirty, isFalse);
  });

  group('load', () {
    blocTest<DispatchConfigBloc, DispatchConfigState>(
      'puts the saved config in both the config and the draft',
      setUp: () => when(() => repository.getConfig()).thenAnswer((_) async => Right(_config())),
      build: build,
      act: (bloc) => bloc.add(DispatchConfigLoadRequested()),
      expect: () => [
        isA<DispatchConfigState>().having((s) => s.isLoading, 'isLoading', true),
        isA<DispatchConfigState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.draftRings, 'draft', [_r1, _r2])
            .having((s) => s.draftLocationMaxAgeSeconds, 'age', 45)
            .having((s) => s.isDirty, 'isDirty', false),
      ],
    );

    blocTest<DispatchConfigBloc, DispatchConfigState>(
      'reports the failure code and no config',
      setUp: () => when(() => repository.getConfig()).thenAnswer(
        (_) async => Left(Failure(code: FailureCode.dispatchConfigFetchFailed)),
      ),
      build: build,
      act: (bloc) => bloc.add(DispatchConfigLoadRequested()),
      expect: () => [
        isA<DispatchConfigState>().having((s) => s.isLoading, 'isLoading', true),
        isA<DispatchConfigState>()
            .having((s) => s.config, 'config', isNull)
            .having((s) => s.errorCode, 'code', FailureCode.dispatchConfigFetchFailed)
            .having((s) => s.errorSerial, 'serial', 1),
      ],
    );
  });

  group('editing the draft', () {
    test('a changed ring makes the draft dirty and valid edits can be saved', () async {
      final bloc = await loaded(_config());

      bloc.add(
        DispatchRingChanged(
          index: 0,
          ring: _r1.copyWith(radiusMeters: 2000),
        ),
      );
      final state = await bloc.stream.first;

      expect(state.draftRings[0].radiusMeters, 2000);
      expect(state.isDirty, isTrue);
      expect(state.canSave, isTrue);
      expect(state.config!.rings[0].radiusMeters, 3000, reason: 'lo guardado no cambia');
    });

    test('going back to the saved values makes it clean again', () async {
      final bloc = await loaded(_config());
      bloc.add(DispatchRingChanged(index: 0, ring: _r1.copyWith(radiusMeters: 2000)));
      await bloc.stream.first;

      bloc.add(DispatchRingChanged(index: 0, ring: _r1));
      final state = await bloc.stream.first;

      expect(state.isDirty, isFalse);
      expect(state.canSave, isFalse);
    });

    test('an invalid draft cannot be saved', () async {
      final bloc = await loaded(_config());

      bloc.add(DispatchRingChanged(index: 1, ring: _r2.copyWith(radiusMeters: 3000)));
      final state = await bloc.stream.first;

      expect(state.isDirty, isTrue);
      expect(state.validation!.isValid, isFalse);
      expect(state.canSave, isFalse);
    });

    test('adding a ring starts a bit beyond the last one with the same waits', () async {
      final bloc = await loaded(_config());

      bloc.add(DispatchRingAdded());
      final state = await bloc.stream.first;

      expect(state.draftRings, hasLength(3));
      expect(state.draftRings.last.radiusMeters, 7000);
      expect(state.draftRings.last.waitSeconds, 10);
      expect(state.validation!.isValid, isTrue);
    });

    test('cannot add past the maximum number of rings', () async {
      final bloc = await loaded(_config(rings: const [_r1, _r2, DispatchRingEntity(radiusMeters: 9000, waitSeconds: 10, maxDrivers: 10)]));

      bloc.add(DispatchRingAdded());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.draftRings, hasLength(3));
    });

    test('removing a ring renumbers by position', () async {
      final bloc = await loaded(_config());

      bloc.add(DispatchRingRemoved(index: 0));
      final state = await bloc.stream.first;

      expect(state.draftRings, [_r2]);
    });

    test('changing the location freshness is part of the draft', () async {
      final bloc = await loaded(_config());

      bloc.add(DispatchLocationMaxAgeChanged(seconds: 60));
      final state = await bloc.stream.first;

      expect(state.draftLocationMaxAgeSeconds, 60);
      expect(state.isDirty, isTrue);
    });

    test('discard goes back to what is saved', () async {
      final bloc = await loaded(_config());
      bloc.add(DispatchLocationMaxAgeChanged(seconds: 60));
      await bloc.stream.first;

      bloc.add(DispatchDraftDiscarded());
      final state = await bloc.stream.first;

      expect(state.draftLocationMaxAgeSeconds, 45);
      expect(state.isDirty, isFalse);
    });

    test('an admin without permission cannot edit anything (events are ignored)', () async {
      final bloc = await loaded(_config(canEdit: false, canChangeAdminEditing: false));
      final states = <DispatchConfigState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(DispatchRingChanged(index: 0, ring: _r1.copyWith(radiusMeters: 1)));
      bloc.add(DispatchRingAdded());
      bloc.add(DispatchRingRemoved(index: 0));
      bloc.add(DispatchLocationMaxAgeChanged(seconds: 99));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states, isEmpty);
      expect(bloc.state.isDirty, isFalse);
      expect(bloc.state.canSave, isFalse);
    });

    test('an out-of-range index is ignored', () async {
      final bloc = await loaded(_config());
      final states = <DispatchConfigState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(DispatchRingChanged(index: 5, ring: _r1));
      bloc.add(DispatchRingRemoved(index: -1));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states, isEmpty);
    });
  });

  group('save', () {
    test('sends the draft with the version that was loaded and adopts the result', () async {
      final bloc = await loaded(_config(version: 2));
      when(
        () => repository.saveConfig(
          rings: any(named: 'rings'),
          locationMaxAgeSeconds: any(named: 'locationMaxAgeSeconds'),
          expectedVersion: any(named: 'expectedVersion'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _config(
            rings: [_r1.copyWith(radiusMeters: 2000), _r2],
            maxAge: 60,
            version: 3,
          ),
        ),
      );
      bloc.add(DispatchRingChanged(index: 0, ring: _r1.copyWith(radiusMeters: 2000)));
      bloc.add(DispatchLocationMaxAgeChanged(seconds: 60));
      await Future<void>.delayed(Duration.zero);

      bloc.add(DispatchSaveRequested());
      final states = await bloc.stream.take(2).toList();

      expect(states[0].isSaving, isTrue);
      expect(states[1].isSaving, isFalse);
      expect(states[1].config!.version, 3);
      expect(states[1].isDirty, isFalse);
      expect(states[1].notice, DispatchConfigNotice.saved);
      expect(states[1].noticeSerial, 1);
      verify(
        () => repository.saveConfig(
          rings: [_r1.copyWith(radiusMeters: 2000), _r2],
          locationMaxAgeSeconds: 60,
          expectedVersion: 2,
        ),
      ).called(1);
    });

    test('nothing is sent when there are no changes', () async {
      final bloc = await loaded(_config());

      bloc.add(DispatchSaveRequested());
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => repository.saveConfig(
          rings: any(named: 'rings'),
          locationMaxAgeSeconds: any(named: 'locationMaxAgeSeconds'),
          expectedVersion: any(named: 'expectedVersion'),
        ),
      );
    });

    test('nothing is sent when the draft is invalid', () async {
      final bloc = await loaded(_config());
      bloc.add(DispatchLocationMaxAgeChanged(seconds: 1));
      await Future<void>.delayed(Duration.zero);

      bloc.add(DispatchSaveRequested());
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => repository.saveConfig(
          rings: any(named: 'rings'),
          locationMaxAgeSeconds: any(named: 'locationMaxAgeSeconds'),
          expectedVersion: any(named: 'expectedVersion'),
        ),
      );
    });

    test('a failure keeps the draft so nothing typed is lost', () async {
      final bloc = await loaded(_config());
      when(
        () => repository.saveConfig(
          rings: any(named: 'rings'),
          locationMaxAgeSeconds: any(named: 'locationMaxAgeSeconds'),
          expectedVersion: any(named: 'expectedVersion'),
        ),
      ).thenAnswer((_) async => Left(Failure(code: FailureCode.dispatchConfigSaveFailed)));
      bloc.add(DispatchLocationMaxAgeChanged(seconds: 60));
      await Future<void>.delayed(Duration.zero);

      bloc.add(DispatchSaveRequested());
      final states = await bloc.stream.take(2).toList();

      expect(states[1].isSaving, isFalse);
      expect(states[1].errorCode, FailureCode.dispatchConfigSaveFailed);
      expect(states[1].draftLocationMaxAgeSeconds, 60);
      expect(states[1].isDirty, isTrue);
      expect(states[1].config!.version, 0);
    });

    test('a conflict reloads the newer config and drops the stale draft', () async {
      final bloc = await loaded(_config(version: 0));
      when(
        () => repository.saveConfig(
          rings: any(named: 'rings'),
          locationMaxAgeSeconds: any(named: 'locationMaxAgeSeconds'),
          expectedVersion: any(named: 'expectedVersion'),
        ),
      ).thenAnswer((_) async => Left(Failure(code: FailureCode.dispatchConfigConflict)));
      // el servidor ya tiene la versión 1 de otro administrador
      when(() => repository.getConfig()).thenAnswer(
        (_) async => Right(_config(rings: const [_r2], version: 1)),
      );
      bloc.add(DispatchLocationMaxAgeChanged(seconds: 60));
      await Future<void>.delayed(Duration.zero);

      bloc.add(DispatchSaveRequested());
      final states = await bloc.stream.take(2).toList();

      expect(states[1].errorCode, FailureCode.dispatchConfigConflict);
      expect(states[1].config!.version, 1);
      expect(states[1].draftRings, [_r2]);
      expect(states[1].draftLocationMaxAgeSeconds, 45);
      expect(states[1].isDirty, isFalse);
      expect(states[1].isSaving, isFalse);
    });

    test('the same error twice in a row can be shown twice (serial grows)', () async {
      final bloc = await loaded(_config());
      when(
        () => repository.saveConfig(
          rings: any(named: 'rings'),
          locationMaxAgeSeconds: any(named: 'locationMaxAgeSeconds'),
          expectedVersion: any(named: 'expectedVersion'),
        ),
      ).thenAnswer((_) async => Left(Failure(code: FailureCode.dispatchConfigSaveFailed)));
      bloc.add(DispatchLocationMaxAgeChanged(seconds: 60));
      await Future<void>.delayed(Duration.zero);

      bloc.add(DispatchSaveRequested());
      final first = (await bloc.stream.take(2).toList()).last;
      bloc.add(DispatchSaveRequested());
      final second = (await bloc.stream.take(2).toList()).last;

      expect(second.errorSerial, greaterThan(first.errorSerial));
    });
  });

  group('admin editing switch', () {
    test('turning it on updates the saved config and keeps the draft', () async {
      final bloc = await loaded(_config());
      bloc.add(DispatchLocationMaxAgeChanged(seconds: 60));
      await Future<void>.delayed(Duration.zero);
      when(() => repository.setAdminEditing(enabled: true)).thenAnswer(
        (_) async => Right(_config(adminsCanEdit: true)),
      );

      bloc.add(DispatchAdminEditingToggled(enabled: true));
      final states = await bloc.stream.take(2).toList();

      expect(states[0].isTogglingAdminEditing, isTrue);
      expect(states[1].isTogglingAdminEditing, isFalse);
      expect(states[1].config!.adminsCanEdit, isTrue);
      expect(states[1].notice, DispatchConfigNotice.adminEditingEnabled);
      expect(states[1].draftLocationMaxAgeSeconds, 60, reason: 'el borrador sigue');
      verify(() => repository.setAdminEditing(enabled: true)).called(1);
    });

    test('turning it off reports the matching notice', () async {
      final bloc = await loaded(_config(adminsCanEdit: true));
      when(() => repository.setAdminEditing(enabled: false)).thenAnswer(
        (_) async => Right(_config(adminsCanEdit: false)),
      );

      bloc.add(DispatchAdminEditingToggled(enabled: false));
      final states = await bloc.stream.take(2).toList();

      expect(states[1].notice, DispatchConfigNotice.adminEditingDisabled);
    });

    test('an admin cannot toggle it (ignored, nothing sent)', () async {
      final bloc = await loaded(_config(canChangeAdminEditing: false, canEdit: false));

      bloc.add(DispatchAdminEditingToggled(enabled: true));
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => repository.setAdminEditing(enabled: any(named: 'enabled')));
    });

    test('setting the value it already has is ignored', () async {
      final bloc = await loaded(_config(adminsCanEdit: true));

      bloc.add(DispatchAdminEditingToggled(enabled: true));
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => repository.setAdminEditing(enabled: any(named: 'enabled')));
    });

    test('a failure leaves the switch where it was and reports the code', () async {
      final bloc = await loaded(_config());
      when(() => repository.setAdminEditing(enabled: true)).thenAnswer(
        (_) async => Left(Failure(code: FailureCode.noPermission)),
      );

      bloc.add(DispatchAdminEditingToggled(enabled: true));
      final states = await bloc.stream.take(2).toList();

      expect(states[1].config!.adminsCanEdit, isFalse);
      expect(states[1].errorCode, FailureCode.noPermission);
      expect(states[1].notice, isNull);
    });
  });
}
