import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/admin/domain/entity/admin_driver_entity.dart';
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
    expect(bloc.state.drivers, isEmpty);
    expect(bloc.state.currentPage, 0);
    expect(bloc.state.errorMessage, isNull);
  });

  group('AdminLoadRequested', () {
    blocTest<AdminBloc, AdminState>(
      'emits loading then the driver list on success, resetting currentPage',
      setUp: () {
        when(
          () => repository.listDrivers(),
        ).thenAnswer((_) async => Right([_driver('1'), _driver('2')]));
      },
      build: buildBloc,
      seed: () => const AdminState(currentPage: 3),
      act: (bloc) => bloc.add(AdminLoadRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading && s.errorMessage == null),
        predicate<AdminState>(
          (s) => !s.isLoading && s.drivers.length == 2 && s.currentPage == 0,
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'emits loading then an error message on failure',
      setUp: () {
        when(
          () => repository.listDrivers(),
        ).thenAnswer((_) async => Left(Failure(message: 'no autorizado')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AdminLoadRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading),
        predicate<AdminState>(
          (s) => !s.isLoading && s.errorMessage == 'no autorizado',
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'clears a previous error message when reloading',
      setUp: () {
        when(
          () => repository.listDrivers(),
        ).thenAnswer((_) async => Right([_driver('1')]));
      },
      build: buildBloc,
      seed: () => const AdminState(errorMessage: 'error viejo'),
      act: (bloc) => bloc.add(AdminLoadRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading && s.errorMessage == null),
        predicate<AdminState>((s) => !s.isLoading && s.drivers.length == 1),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'handles an empty driver list',
      setUp: () {
        when(
          () => repository.listDrivers(),
        ).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AdminLoadRequested()),
      expect: () => [
        predicate<AdminState>((s) => s.isLoading),
        predicate<AdminState>((s) => !s.isLoading && s.drivers.isEmpty),
      ],
    );
  });

  group('AdminSearchChanged', () {
    blocTest<AdminBloc, AdminState>(
      'updates the search query and resets currentPage to 0',
      build: buildBloc,
      seed: () => const AdminState(currentPage: 2),
      act: (bloc) => bloc.add(AdminSearchChanged(query: 'ana')),
      expect: () => [
        predicate<AdminState>((s) => s.searchQuery == 'ana' && s.currentPage == 0),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'accepts an empty query to clear filtering',
      build: buildBloc,
      seed: () => const AdminState(searchQuery: 'algo'),
      act: (bloc) => bloc.add(AdminSearchChanged(query: '')),
      expect: () => [predicate<AdminState>((s) => s.searchQuery == '')],
    );
  });

  group('AdminPageChanged', () {
    blocTest<AdminBloc, AdminState>(
      'moves to a valid page within range',
      build: buildBloc,
      seed: () => AdminState(drivers: List.generate(25, (i) => _driver('$i'))),
      act: (bloc) => bloc.add(AdminPageChanged(page: 1)),
      expect: () => [predicate<AdminState>((s) => s.currentPage == 1)],
    );

    blocTest<AdminBloc, AdminState>(
      'clamps a page request above the max page',
      build: buildBloc,
      seed: () => AdminState(drivers: List.generate(15, (i) => _driver('$i'))),
      act: (bloc) => bloc.add(AdminPageChanged(page: 99)),
      expect: () => [predicate<AdminState>((s) => s.currentPage == 1)],
    );

    blocTest<AdminBloc, AdminState>(
      'clamps a negative page request to 0',
      build: buildBloc,
      seed: () => AdminState(drivers: List.generate(15, (i) => _driver('$i'))),
      act: (bloc) => bloc.add(AdminPageChanged(page: -5)),
      expect: () => [predicate<AdminState>((s) => s.currentPage == 0)],
    );

    blocTest<AdminBloc, AdminState>(
      'clamps to 0 when there are no drivers at all',
      build: buildBloc,
      act: (bloc) => bloc.add(AdminPageChanged(page: 3)),
      expect: () => [predicate<AdminState>((s) => s.currentPage == 0)],
    );
  });

  group('AdminDeleteDriverRequested', () {
    blocTest<AdminBloc, AdminState>(
      'removes the driver from the list on success and clears actionUid',
      setUp: () {
        when(
          () => repository.deleteDriver(uid: '1'),
        ).thenAnswer((_) async => Right(unit));
      },
      build: buildBloc,
      seed: () => AdminState(drivers: [_driver('1'), _driver('2')]),
      act: (bloc) => bloc.add(AdminDeleteDriverRequested(uid: '1')),
      expect: () => [
        predicate<AdminState>((s) => s.actionUid == '1'),
        predicate<AdminState>(
          (s) =>
              s.actionUid == null &&
              s.drivers.length == 1 &&
              s.drivers.first.uid == '2',
        ),
      ],
      verify: (_) {
        verify(() => repository.deleteDriver(uid: '1')).called(1);
      },
    );

    blocTest<AdminBloc, AdminState>(
      'keeps the list and reports the error on failure',
      setUp: () {
        when(() => repository.deleteDriver(uid: '1')).thenAnswer(
          (_) async => Left(Failure(message: 'no se pudo borrar')),
        );
      },
      build: buildBloc,
      seed: () => AdminState(drivers: [_driver('1')]),
      act: (bloc) => bloc.add(AdminDeleteDriverRequested(uid: '1')),
      expect: () => [
        predicate<AdminState>((s) => s.actionUid == '1'),
        predicate<AdminState>(
          (s) =>
              s.actionUid == null &&
              s.errorMessage == 'no se pudo borrar' &&
              s.drivers.length == 1,
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'clamps currentPage down when deleting empties out the last page',
      setUp: () {
        when(
          () => repository.deleteDriver(uid: 'last'),
        ).thenAnswer((_) async => Right(unit));
      },
      build: buildBloc,
      seed: () => AdminState(
        drivers: [..._twoOnFirstPage(), _driver('last')],
        currentPage: 1,
      ),
      act: (bloc) => bloc.add(AdminDeleteDriverRequested(uid: 'last')),
      expect: () => [
        predicate<AdminState>((s) => s.actionUid == 'last'),
        predicate<AdminState>((s) => s.currentPage == 0),
      ],
    );
  });

  group('AdminRoleChangeRequested', () {
    blocTest<AdminBloc, AdminState>(
      'updates the role of the matching driver on success',
      setUp: () {
        when(
          () => repository.updateDriverRole(uid: '1', role: 'admin'),
        ).thenAnswer((_) async => Right(unit));
      },
      build: buildBloc,
      seed: () => AdminState(drivers: [_driver('1'), _driver('2')]),
      act: (bloc) =>
          bloc.add(AdminRoleChangeRequested(uid: '1', role: 'admin')),
      expect: () => [
        predicate<AdminState>((s) => s.actionUid == '1'),
        predicate<AdminState>(
          (s) =>
              s.actionUid == null &&
              s.drivers.firstWhere((d) => d.uid == '1').role == 'admin' &&
              s.drivers.firstWhere((d) => d.uid == '2').role == 'driver',
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
      seed: () => AdminState(drivers: [_driver('1')]),
      act: (bloc) =>
          bloc.add(AdminRoleChangeRequested(uid: '1', role: 'admin')),
      expect: () => [
        predicate<AdminState>((s) => s.actionUid == '1'),
        predicate<AdminState>(
          (s) =>
              s.actionUid == null &&
              s.errorMessage == 'no se pudo actualizar' &&
              s.drivers.first.role == 'driver',
        ),
      ],
    );
  });
}

List<AdminDriverEntity> _twoOnFirstPage() =>
    List.generate(10, (i) => _driver('page-$i'));
