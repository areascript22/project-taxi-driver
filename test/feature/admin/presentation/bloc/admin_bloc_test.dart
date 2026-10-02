import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/admin/domain/entity/admin_driver_entity.dart';
import 'package:driver_app/feature/admin/domain/entity/driver_page_entity.dart';
import 'package:driver_app/feature/admin/domain/repository/admin_repository.dart';
import 'package:driver_app/feature/admin/presentation/bloc/admin_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

AdminDriverEntity _driver(String uid, {String role = 'driver'}) {
  return AdminDriverEntity(
    uid: uid,
    firstName: 'First$uid',
    lastName: 'Last$uid',
    email: '$uid@example.com',
    phoneNumber: '555-$uid',
    role: role,
  );
}

void main() {
  late MockAdminRepository repository;

  setUp(() {
    repository = MockAdminRepository();
  });

  AdminBloc buildBloc() => AdminBloc(adminRepository: repository);

  test('initial state is the default AdminState', () {
    final bloc = buildBloc();
    expect(bloc.state.isLoading, isFalse);
    expect(bloc.state.loadedDrivers, isEmpty);
    expect(bloc.state.currentPage, 0);
    expect(bloc.state.errorMessage, isNull);
  });

  group('AdminLoadRequested (browse mode)', () {
    blocTest<AdminBloc, AdminState>(
      'loads the first page and stores the cursor/hasMore from the response',
      setUp: () {
        when(
          () => repository.listDriversPage(pageSize: 10),
        ).thenAnswer(
          (_) async => Right(
            DriverPageEntity(
              drivers: [_driver('1'), _driver('2')],
              nextCursor: 'cursor-2',
              hasMore: true,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AdminLoadRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading && s.errorMessage == null),
        predicate<AdminState>(
          (s) =>
              !s.isLoading &&
              s.loadedDrivers.length == 2 &&
              s.nextCursor == 'cursor-2' &&
              s.hasMore,
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'clears nextCursor when the response has no more pages',
      setUp: () {
        when(
          () => repository.listDriversPage(pageSize: 10),
        ).thenAnswer(
          (_) async => Right(
            DriverPageEntity(drivers: [_driver('1')], nextCursor: null, hasMore: false),
          ),
        );
      },
      build: buildBloc,
      seed: () => const AdminState(nextCursor: 'stale-cursor', hasMore: true),
      act: (bloc) => bloc.add(AdminLoadRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading),
        predicate<AdminState>((s) => !s.isLoading && s.nextCursor == null && !s.hasMore),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'resets currentPage to 0',
      setUp: () {
        when(
          () => repository.listDriversPage(pageSize: 10),
        ).thenAnswer((_) async => Right(DriverPageEntity(drivers: [_driver('1')])));
      },
      build: buildBloc,
      seed: () => const AdminState(currentPage: 3),
      act: (bloc) => bloc.add(AdminLoadRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading),
        predicate<AdminState>((s) => !s.isLoading && s.currentPage == 0),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'emits an error message on failure',
      setUp: () {
        when(
          () => repository.listDriversPage(pageSize: 10),
        ).thenAnswer((_) async => Left(Failure(message: 'no autorizado')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AdminLoadRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading),
        predicate<AdminState>((s) => !s.isLoading && s.errorMessage == 'no autorizado'),
      ],
    );
  });

  group('AdminLoadRequested (search mode)', () {
    blocTest<AdminBloc, AdminState>(
      'fetches the full list via searchAllDrivers instead of listDriversPage',
      setUp: () {
        when(
          () => repository.searchAllDrivers(),
        ).thenAnswer((_) async => Right([_driver('1'), _driver('2')]));
      },
      build: buildBloc,
      seed: () => const AdminState(searchQuery: 'ana'),
      act: (bloc) => bloc.add(AdminLoadRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading),
        predicate<AdminState>((s) => !s.isLoading && s.searchResults?.length == 2),
      ],
      verify: (_) {
        verify(() => repository.searchAllDrivers()).called(1);
        verifyNever(() => repository.listDriversPage(pageSize: any(named: 'pageSize')));
      },
    );
  });

  group('AdminSearchChanged', () {
    blocTest<AdminBloc, AdminState>(
      'fetches searchAllDrivers the first time the query becomes non-empty',
      setUp: () {
        when(
          () => repository.searchAllDrivers(),
        ).thenAnswer((_) async => Right([_driver('1')]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AdminSearchChanged(query: 'ana')),
      expect: () => [
        predicate<AdminState>((s) => s.searchQuery == 'ana' && s.currentPage == 0),
        predicate<AdminState>((s) => s.isLoading),
        predicate<AdminState>((s) => !s.isLoading && s.searchResults?.length == 1),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'does not refetch while typing if searchResults is already cached',
      build: buildBloc,
      seed: () => AdminState(searchQuery: 'an', searchResults: [_driver('1')]),
      act: (bloc) => bloc.add(AdminSearchChanged(query: 'ana')),
      expect: () => [predicate<AdminState>((s) => s.searchQuery == 'ana')],
      verify: (_) {
        verifyNever(() => repository.searchAllDrivers());
      },
    );

    blocTest<AdminBloc, AdminState>(
      'clearing the query back to empty does not trigger any fetch',
      build: buildBloc,
      seed: () => AdminState(searchQuery: 'ana', searchResults: [_driver('1')]),
      act: (bloc) => bloc.add(AdminSearchChanged(query: '')),
      expect: () => [predicate<AdminState>((s) => s.searchQuery == '' && s.currentPage == 0)],
      verify: (_) {
        verifyNever(() => repository.searchAllDrivers());
      },
    );
  });

  group('AdminNextPageRequested', () {
    blocTest<AdminBloc, AdminState>(
      'just advances currentPage when the next page is already cached',
      build: buildBloc,
      seed: () => AdminState(
        loadedDrivers: List.generate(20, (i) => _driver('$i')),
        hasMore: false,
        currentPage: 0,
      ),
      act: (bloc) => bloc.add(AdminNextPageRequested()),
      expect: () => [predicate<AdminState>((s) => s.currentPage == 1)],
      verify: (_) {
        verifyNever(() => repository.listDriversPage(pageSize: any(named: 'pageSize')));
      },
    );

    blocTest<AdminBloc, AdminState>(
      'fetches the next page via cursor when nothing is cached ahead',
      setUp: () {
        when(
          () => repository.listDriversPage(pageSize: 10, cursor: 'cursor-1'),
        ).thenAnswer(
          (_) async => Right(
            DriverPageEntity(drivers: [_driver('11')], nextCursor: null, hasMore: false),
          ),
        );
      },
      build: buildBloc,
      seed: () => AdminState(
        loadedDrivers: List.generate(10, (i) => _driver('$i')),
        nextCursor: 'cursor-1',
        hasMore: true,
        currentPage: 0,
      ),
      act: (bloc) => bloc.add(AdminNextPageRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading),
        predicate<AdminState>(
          (s) =>
              !s.isLoading &&
              s.currentPage == 1 &&
              s.loadedDrivers.length == 11 &&
              !s.hasMore,
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'does nothing when canGoNext is false',
      build: buildBloc,
      seed: () => AdminState(
        loadedDrivers: List.generate(5, (i) => _driver('$i')),
        hasMore: false,
      ),
      act: (bloc) => bloc.add(AdminNextPageRequested()),
      expect: () => [],
    );
  });

  group('AdminPreviousPageRequested', () {
    blocTest<AdminBloc, AdminState>(
      'decrements currentPage',
      build: buildBloc,
      seed: () => const AdminState(currentPage: 2),
      act: (bloc) => bloc.add(AdminPreviousPageRequested()),
      expect: () => [predicate<AdminState>((s) => s.currentPage == 1)],
    );

    blocTest<AdminBloc, AdminState>(
      'does nothing on the first page',
      build: buildBloc,
      seed: () => const AdminState(currentPage: 0),
      act: (bloc) => bloc.add(AdminPreviousPageRequested()),
      expect: () => [],
    );
  });

  group('AdminRoleChangeRequested', () {
    blocTest<AdminBloc, AdminState>(
      'updates the role of the matching driver in loadedDrivers and searchResults',
      setUp: () {
        when(
          () => repository.updateDriverRole(uid: '1', role: 'admin'),
        ).thenAnswer((_) async => Right(unit));
      },
      build: buildBloc,
      seed: () => AdminState(
        loadedDrivers: [_driver('1'), _driver('2')],
        searchResults: [_driver('1')],
      ),
      act: (bloc) =>
          bloc.add(AdminRoleChangeRequested(uid: '1', role: 'admin')),
      expect: () => [
        predicate<AdminState>((s) => s.actionUid == '1'),
        predicate<AdminState>(
          (s) =>
              s.actionUid == null &&
              s.loadedDrivers.firstWhere((d) => d.uid == '1').role == 'admin' &&
              s.loadedDrivers.firstWhere((d) => d.uid == '2').role == 'driver' &&
              s.searchResults!.first.role == 'admin',
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'reports the error and leaves roles untouched on failure',
      setUp: () {
        when(
          () => repository.updateDriverRole(uid: '1', role: 'admin'),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'no se pudo actualizar')),
        );
      },
      build: buildBloc,
      seed: () => AdminState(loadedDrivers: [_driver('1')]),
      act: (bloc) =>
          bloc.add(AdminRoleChangeRequested(uid: '1', role: 'admin')),
      expect: () => [
        predicate<AdminState>((s) => s.actionUid == '1'),
        predicate<AdminState>(
          (s) =>
              s.actionUid == null &&
              s.errorMessage == 'no se pudo actualizar' &&
              s.loadedDrivers.first.role == 'driver',
        ),
      ],
    );
  });

  group('AdminDriverRefreshRequested', () {
    blocTest<AdminBloc, AdminState>(
      'patches the driver in place without touching pagination state',
      setUp: () {
        when(
          () => repository.getDriver(uid: '1'),
        ).thenAnswer((_) async => Right(_driver('1', role: 'admin')));
      },
      build: buildBloc,
      seed: () => AdminState(
        loadedDrivers: [_driver('1'), _driver('2')],
        currentPage: 1,
        hasMore: true,
        nextCursor: 'cursor-x',
      ),
      act: (bloc) => bloc.add(AdminDriverRefreshRequested(uid: '1')),
      expect: () => [
        predicate<AdminState>(
          (s) =>
              s.loadedDrivers.firstWhere((d) => d.uid == '1').role == 'admin' &&
              s.currentPage == 1 &&
              s.hasMore &&
              s.nextCursor == 'cursor-x',
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'removes the driver from loadedDrivers and searchResults when it no longer exists',
      setUp: () {
        when(
          () => repository.getDriver(uid: '1'),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      seed: () => AdminState(
        loadedDrivers: [_driver('1'), _driver('2')],
        searchResults: [_driver('1')],
      ),
      act: (bloc) => bloc.add(AdminDriverRefreshRequested(uid: '1')),
      expect: () => [
        predicate<AdminState>(
          (s) =>
              s.loadedDrivers.map((d) => d.uid).toList().join(',') == '2' &&
              (s.searchResults ?? []).isEmpty,
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'does nothing on a transient failure -- keeps the cached data as-is',
      setUp: () {
        when(
          () => repository.getDriver(uid: '1'),
        ).thenAnswer((_) async => Left(Failure(message: 'network')));
      },
      build: buildBloc,
      seed: () => AdminState(loadedDrivers: [_driver('1')]),
      act: (bloc) => bloc.add(AdminDriverRefreshRequested(uid: '1')),
      expect: () => [],
    );
  });
}
