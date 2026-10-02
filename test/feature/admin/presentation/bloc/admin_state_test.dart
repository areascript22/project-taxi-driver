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
    test('without a search query, returns loadedDrivers as-is (browse mode)', () {
      final state = AdminState(loadedDrivers: [_driver('1'), _driver('2')]);

      expect(state.filteredDrivers.map((d) => d.uid), ['1', '2']);
    });

    test('with a search query, filters over searchResults, not loadedDrivers', () {
      final state = AdminState(
        loadedDrivers: [_driver('1', firstName: 'Ana')],
        searchResults: [_driver('1', firstName: 'Ana'), _driver('2', firstName: 'Beto')],
        searchQuery: 'ana',
      );

      expect(state.filteredDrivers.map((d) => d.uid), ['1']);
    });

    test('with a search query but no searchResults loaded yet, returns empty', () {
      final state = AdminState(
        loadedDrivers: [_driver('1', firstName: 'Ana')],
        searchQuery: 'ana',
      );

      expect(state.filteredDrivers, isEmpty);
    });

    test('filters by email', () {
      final state = AdminState(
        searchResults: [_driver('1'), _driver('2')],
        searchQuery: '2@example.com',
      );

      expect(state.filteredDrivers.map((d) => d.uid), ['2']);
    });

    test('filters by phone number', () {
      final state = AdminState(
        searchResults: [_driver('1'), _driver('2')],
        searchQuery: '555-1',
      );

      expect(state.filteredDrivers.map((d) => d.uid), ['1']);
    });

    test('trims whitespace around the query', () {
      final state = AdminState(
        searchResults: [_driver('1', firstName: 'Ana')],
        searchQuery: '  ana  ',
      );

      expect(state.filteredDrivers, hasLength(1));
    });

    test('returns an empty list when nothing matches', () {
      final state = AdminState(
        searchResults: [_driver('1')],
        searchQuery: 'nadie-coincide',
      );

      expect(state.filteredDrivers, isEmpty);
    });
  });

  group('AdminState.totalPages / pageDrivers', () {
    test('totalPages is 1 even with zero drivers', () {
      const state = AdminState(loadedDrivers: [], hasMore: false);

      expect(state.totalPages, 1);
      expect(state.pageDrivers, isEmpty);
    });

    test('totalPages is null (unknown) in browse mode while hasMore is true', () {
      final drivers = List.generate(10, (i) => _driver('$i'));
      final state = AdminState(loadedDrivers: drivers, hasMore: true);

      expect(state.totalPages, isNull);
      expect(state.pageDrivers, hasLength(10));
    });

    test('totalPages is known once browse mode has no more pages left', () {
      final drivers = List.generate(25, (i) => _driver('$i'));
      final state = AdminState(loadedDrivers: drivers, hasMore: false);

      expect(state.totalPages, 3);
      expect(state.pageDrivers, hasLength(10));
    });

    test('pageDrivers returns the correct slice for a middle page', () {
      final drivers = List.generate(25, (i) => _driver('$i'));
      final state = AdminState(loadedDrivers: drivers, hasMore: false, currentPage: 1);

      expect(state.pageDrivers.first.uid, '10');
      expect(state.pageDrivers.last.uid, '19');
    });

    test('pageDrivers returns the remainder on the last (partial) page', () {
      final drivers = List.generate(25, (i) => _driver('$i'));
      final state = AdminState(loadedDrivers: drivers, hasMore: false, currentPage: 2);

      expect(state.pageDrivers, hasLength(5));
    });

    test('pageDrivers is empty when currentPage is beyond available data', () {
      final drivers = List.generate(5, (i) => _driver('$i'));
      final state = AdminState(loadedDrivers: drivers, hasMore: false, currentPage: 5);

      expect(state.pageDrivers, isEmpty);
    });

    test('in search mode, totalPages is always known (everything is already loaded)', () {
      final drivers = List.generate(
        15,
        (i) => _driver('$i', firstName: i == 0 ? 'Unico' : 'Otro'),
      );
      final state = AdminState(searchResults: drivers, searchQuery: 'Unico');

      expect(state.totalPages, 1);
      expect(state.pageDrivers, hasLength(1));
    });
  });

  group('AdminState.canGoNext / canGoPrevious', () {
    test('canGoPrevious is false on the first page', () {
      const state = AdminState(currentPage: 0);
      expect(state.canGoPrevious, isFalse);
    });

    test('canGoPrevious is true past the first page', () {
      const state = AdminState(currentPage: 1);
      expect(state.canGoPrevious, isTrue);
    });

    test('canGoNext is true when the next page is already cached', () {
      final drivers = List.generate(20, (i) => _driver('$i'));
      final state = AdminState(loadedDrivers: drivers, hasMore: false, currentPage: 0);
      expect(state.canGoNext, isTrue);
    });

    test('canGoNext is true in browse mode when hasMore is true, even without a cached next page', () {
      final drivers = List.generate(10, (i) => _driver('$i'));
      final state = AdminState(loadedDrivers: drivers, hasMore: true, currentPage: 0);
      expect(state.canGoNext, isTrue);
    });

    test('canGoNext is false in browse mode once hasMore is false and nothing cached ahead', () {
      final drivers = List.generate(10, (i) => _driver('$i'));
      final state = AdminState(loadedDrivers: drivers, hasMore: false, currentPage: 0);
      expect(state.canGoNext, isFalse);
    });

    test('canGoNext ignores hasMore while searching (everything is already loaded)', () {
      final drivers = List.generate(10, (i) => _driver('$i'));
      final state = AdminState(
        searchResults: drivers,
        searchQuery: 'x',
        hasMore: true,
        currentPage: 0,
      );
      expect(state.canGoNext, isFalse);
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

    test('clearNextCursor resets nextCursor to null regardless of value passed', () {
      const state = AdminState(nextCursor: 'cursor-1');

      final result = state.copyWith(clearNextCursor: true, nextCursor: 'ignored');

      expect(result.nextCursor, isNull);
    });

    test('clearSearchResults resets searchResults to null', () {
      final state = AdminState(searchResults: [_driver('1')]);

      final result = state.copyWith(clearSearchResults: true);

      expect(result.searchResults, isNull);
    });

    test('preserves fields that are not overridden', () {
      final state = AdminState(
        loadedDrivers: [_driver('1')],
        currentPage: 2,
        nextCursor: 'cursor-1',
        hasMore: true,
      );

      final result = state.copyWith(isLoading: true);

      expect(result.loadedDrivers, state.loadedDrivers);
      expect(result.currentPage, 2);
      expect(result.nextCursor, 'cursor-1');
      expect(result.hasMore, isTrue);
    });
  });
}
