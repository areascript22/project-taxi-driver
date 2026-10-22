import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_change_entity.dart';
import 'package:driver_app/feature/dispatch_admin/domain/repository/dispatch_admin_repository.dart';
import 'package:driver_app/feature/dispatch_admin/presentation/bloc/dispatch_history_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDispatchAdminRepository extends Mock
    implements DispatchAdminRepository {}

const _snapshot = DispatchSnapshotEntity(
  rings: [],
  locationMaxAgeSeconds: 45,
  adminsCanEdit: false,
);

DispatchChangeEntity _change(int id) => DispatchChangeEntity(
  id: id,
  changedAt: null,
  changedByName: 'Super',
  type: DispatchChangeType.config,
  before: _snapshot,
  after: _snapshot,
);

void main() {
  late MockDispatchAdminRepository repository;

  setUp(() {
    repository = MockDispatchAdminRepository();
  });

  DispatchHistoryCubit build() => DispatchHistoryCubit(repository: repository);

  test('initial state is empty and not loaded', () {
    final state = build().state;

    expect(state.changes, isEmpty);
    expect(state.loaded, isFalse);
    expect(state.hasMore, isFalse);
  });

  blocTest<DispatchHistoryCubit, DispatchHistoryState>(
    'load fetches the first page without a cursor',
    setUp: () => when(
      () => repository.getHistory(limit: any(named: 'limit'), beforeId: any(named: 'beforeId')),
    ).thenAnswer(
      (_) async => Right(
        DispatchHistoryPageEntity(changes: [_change(3), _change(2)], nextBeforeId: 2),
      ),
    ),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<DispatchHistoryState>().having((s) => s.isLoading, 'isLoading', true),
      isA<DispatchHistoryState>()
          .having((s) => s.changes.map((c) => c.id), 'ids', [3, 2])
          .having((s) => s.hasMore, 'hasMore', true)
          .having((s) => s.loaded, 'loaded', true),
    ],
    verify: (_) {
      verify(() => repository.getHistory(limit: 20, beforeId: null)).called(1);
    },
  );

  blocTest<DispatchHistoryCubit, DispatchHistoryState>(
    'load reports the failure and still counts as loaded',
    setUp: () => when(
      () => repository.getHistory(limit: any(named: 'limit'), beforeId: any(named: 'beforeId')),
    ).thenAnswer(
      (_) async => Left(Failure(code: FailureCode.dispatchHistoryFetchFailed)),
    ),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<DispatchHistoryState>().having((s) => s.isLoading, 'isLoading', true),
      isA<DispatchHistoryState>()
          .having((s) => s.errorCode, 'code', FailureCode.dispatchHistoryFetchFailed)
          .having((s) => s.changes, 'changes', isEmpty)
          .having((s) => s.loaded, 'loaded', true),
    ],
  );

  blocTest<DispatchHistoryCubit, DispatchHistoryState>(
    'loadMore appends the next page using the cursor and stops at the end',
    setUp: () {
      when(() => repository.getHistory(limit: 20, beforeId: null)).thenAnswer(
        (_) async => Right(
          DispatchHistoryPageEntity(changes: [_change(3), _change(2)], nextBeforeId: 2),
        ),
      );
      when(() => repository.getHistory(limit: 20, beforeId: 2)).thenAnswer(
        (_) async => Right(
          DispatchHistoryPageEntity(changes: [_change(1)], nextBeforeId: null),
        ),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    skip: 2,
    expect: () => [
      isA<DispatchHistoryState>().having((s) => s.isLoadingMore, 'isLoadingMore', true),
      isA<DispatchHistoryState>()
          .having((s) => s.changes.map((c) => c.id), 'ids', [3, 2, 1])
          .having((s) => s.hasMore, 'hasMore', false)
          .having((s) => s.isLoadingMore, 'isLoadingMore', false),
    ],
  );

  blocTest<DispatchHistoryCubit, DispatchHistoryState>(
    'loadMore does nothing when there is no next page',
    setUp: () => when(
      () => repository.getHistory(limit: any(named: 'limit'), beforeId: any(named: 'beforeId')),
    ).thenAnswer(
      (_) async => Right(
        DispatchHistoryPageEntity(changes: [_change(1)], nextBeforeId: null),
      ),
    ),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    skip: 2,
    expect: () => <DispatchHistoryState>[],
    verify: (_) {
      verify(() => repository.getHistory(limit: 20, beforeId: null)).called(1);
      verifyNever(() => repository.getHistory(limit: 20, beforeId: 1));
    },
  );

  blocTest<DispatchHistoryCubit, DispatchHistoryState>(
    'a failure while loading more keeps what was already loaded',
    setUp: () {
      when(() => repository.getHistory(limit: 20, beforeId: null)).thenAnswer(
        (_) async => Right(
          DispatchHistoryPageEntity(changes: [_change(3)], nextBeforeId: 3),
        ),
      );
      when(() => repository.getHistory(limit: 20, beforeId: 3)).thenAnswer(
        (_) async => Left(Failure(code: FailureCode.dispatchHistoryFetchFailed)),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    skip: 3,
    expect: () => [
      isA<DispatchHistoryState>()
          .having((s) => s.changes.map((c) => c.id), 'ids', [3])
          .having((s) => s.errorCode, 'code', FailureCode.dispatchHistoryFetchFailed)
          .having((s) => s.hasMore, 'can retry', true),
    ],
  );
}
