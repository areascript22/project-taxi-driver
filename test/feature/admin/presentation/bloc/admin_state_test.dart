import 'package:driver_app/feature/admin/domain/entity/admin_driver_entity.dart';
import 'package:driver_app/feature/admin/presentation/bloc/admin_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

AdminDriverEntity _driver(String uid, {String? firstName, String? role}) {
  return AdminDriverEntity(
    uid: uid,
    firstName: firstName ?? 'First$uid',
    lastName: 'Last$uid',
    email: '$uid@example.com',
    phoneNumber: '555-$uid',
    role: role ?? 'driver',
  );
}

void main() {
  group('AdminState.filteredDrivers', () {
    test('returns all drivers when the search query is empty', () {
      final state = AdminState(drivers: [_driver('1'), _driver('2')]);

      expect(state.filteredDrivers, hasLength(2));
    });

    test('filters by full name case-insensitively', () {
      final state = AdminState(
        drivers: [_driver('1', firstName: 'Ana'), _driver('2', firstName: 'Beto')],
        searchQuery: 'ana',
      );

      expect(state.filteredDrivers.map((d) => d.uid), ['1']);
    });

    test('filters by email', () {
      final state = AdminState(
        drivers: [_driver('1'), _driver('2')],
        searchQuery: '2@example.com',
      );

      expect(state.filteredDrivers.map((d) => d.uid), ['2']);
    });

    test('filters by phone number', () {
      final state = AdminState(
        drivers: [_driver('1'), _driver('2')],
        searchQuery: '555-1',
      );

      expect(state.filteredDrivers.map((d) => d.uid), ['1']);
    });

    test('trims whitespace around the query', () {
      final state = AdminState(
        drivers: [_driver('1', firstName: 'Ana')],
        searchQuery: '  ana  ',
      );

      expect(state.filteredDrivers, hasLength(1));
    });

    test('returns an empty list when nothing matches', () {
      final state = AdminState(
        drivers: [_driver('1')],
        searchQuery: 'nadie-coincide',
      );

      expect(state.filteredDrivers, isEmpty);
    });
  });

  group('AdminState.totalPages / pageDrivers', () {
    test('totalPages is 1 even with zero drivers', () {
      const state = AdminState(drivers: []);

      expect(state.totalPages, 1);
      expect(state.pageDrivers, isEmpty);
    });

    test('totalPages accounts for the page size of 10', () {
      final drivers = List.generate(25, (i) => _driver('$i'));
      final state = AdminState(drivers: drivers);

      expect(state.totalPages, 3);
      expect(state.pageDrivers, hasLength(10));
    });

    test('pageDrivers returns the correct slice for a middle page', () {
      final drivers = List.generate(25, (i) => _driver('$i'));
      final state = AdminState(drivers: drivers, currentPage: 1);

      expect(state.pageDrivers.first.uid, '10');
      expect(state.pageDrivers.last.uid, '19');
    });

    test('pageDrivers returns the remainder on the last (partial) page', () {
      final drivers = List.generate(25, (i) => _driver('$i'));
      final state = AdminState(drivers: drivers, currentPage: 2);

      expect(state.pageDrivers, hasLength(5));
    });

    test('pageDrivers is empty when currentPage is beyond available data', () {
      final drivers = List.generate(5, (i) => _driver('$i'));
      final state = AdminState(drivers: drivers, currentPage: 5);

      expect(state.pageDrivers, isEmpty);
    });

    test('totalPages reflects the filtered count, not the raw count', () {
      final drivers = List.generate(15, (i) => _driver('$i', firstName: i == 0 ? 'Unico' : 'Otro'));
      final state = AdminState(drivers: drivers, searchQuery: 'Unico');

      expect(state.totalPages, 1);
      expect(state.pageDrivers, hasLength(1));
    });
  });

  group('AdminState.copyWith', () {
    test('clearError resets errorMessage to null regardless of value passed', () {
      const state = AdminState(errorMessage: 'boom');

      final result = state.copyWith(clearError: true, errorMessage: 'ignored');

      expect(result.errorMessage, isNull);
    });

    test('without clearError, errorMessage falls back to the previous value', () {
      const state = AdminState(errorMessage: 'boom');

      final result = state.copyWith(isLoading: true);

      expect(result.errorMessage, 'boom');
    });

    test('clearActionUid resets actionUid to null', () {
      const state = AdminState(actionUid: 'uid-1');

      final result = state.copyWith(clearActionUid: true);

      expect(result.actionUid, isNull);
    });

    test('preserves fields that are not overridden', () {
      final state = AdminState(drivers: [_driver('1')], currentPage: 2);

      final result = state.copyWith(isLoading: true);

      expect(result.drivers, state.drivers);
      expect(result.currentPage, 2);
    });
  });
}
