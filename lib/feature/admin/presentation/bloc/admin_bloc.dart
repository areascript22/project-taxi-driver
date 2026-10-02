import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../domain/entity/admin_driver_entity.dart';
import '../../domain/repository/admin_repository.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository adminRepository;

  AdminBloc({required this.adminRepository}) : super(const AdminState()) {
    on<AdminLoadRequested>(_onLoadRequested);
    on<AdminSearchChanged>(_onSearchChanged);
    on<AdminNextPageRequested>(_onNextPageRequested);
    on<AdminPreviousPageRequested>(_onPreviousPageRequested);
    on<AdminRoleChangeRequested>(_onRoleChangeRequested);
    on<AdminDriverRefreshRequested>(_onDriverRefreshRequested);
  }

  Future<void> _onLoadRequested(
    AdminLoadRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, currentPage: 0));

    if (state.isSearching) {
      await _loadSearchResults(emit);
      return;
    }

    final result = await adminRepository.listDriversPage(pageSize: _pageSize);

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (page) => emit(
        state.copyWith(
          isLoading: false,
          loadedDrivers: page.drivers,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _loadSearchResults(Emitter<AdminState> emit) async {
    final result = await adminRepository.searchAllDrivers();

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (drivers) =>
          emit(state.copyWith(isLoading: false, searchResults: drivers)),
    );
  }

  Future<void> _onSearchChanged(
    AdminSearchChanged event,
    Emitter<AdminState> emit,
  ) async {
    final willSearch = event.query.trim().isNotEmpty;
    emit(state.copyWith(searchQuery: event.query, currentPage: 0));

    // Se busca una sola vez por sesión de búsqueda -- si ya hay resultados
    // cacheados (de una búsqueda anterior), no hace falta volver a pedirlos
    // en cada tecla.
    if (willSearch && state.searchResults == null) {
      emit(state.copyWith(isLoading: true, clearError: true));
      await _loadSearchResults(emit);
    }
  }

  Future<void> _onNextPageRequested(
    AdminNextPageRequested event,
    Emitter<AdminState> emit,
  ) async {
    if (!state.canGoNext) return;

    final hasCachedNextPage =
        (state.currentPage + 1) * _pageSize < state.filteredDrivers.length;
    if (hasCachedNextPage) {
      emit(state.copyWith(currentPage: state.currentPage + 1));
      return;
    }

    // Modo navegación únicamente: en modo búsqueda ya está todo cargado, así
    // que canGoNext ya habría sido false si no hubiera página cacheada.
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await adminRepository.listDriversPage(
      pageSize: _pageSize,
      cursor: state.nextCursor,
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (page) => emit(
        state.copyWith(
          isLoading: false,
          loadedDrivers: [...state.loadedDrivers, ...page.drivers],
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          hasMore: page.hasMore,
          currentPage: state.currentPage + 1,
        ),
      ),
    );
  }

  void _onPreviousPageRequested(
    AdminPreviousPageRequested event,
    Emitter<AdminState> emit,
  ) {
    if (!state.canGoPrevious) return;
    emit(state.copyWith(currentPage: state.currentPage - 1));
  }

  Future<void> _onRoleChangeRequested(
    AdminRoleChangeRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(actionUid: event.uid, clearError: true));

    final result = await adminRepository.updateDriverRole(
      uid: event.uid,
      role: event.role,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(clearActionUid: true, errorMessage: failure.message),
      ),
      (_) {
        AdminDriverEntity patch(AdminDriverEntity driver) =>
            driver.uid == event.uid
                ? driver.copyWith(role: event.role)
                : driver;

        emit(
          state.copyWith(
            loadedDrivers: state.loadedDrivers.map(patch).toList(),
            searchResults: state.searchResults?.map(patch).toList(),
            clearActionUid: true,
          ),
        );
      },
    );
  }

  Future<void> _onDriverRefreshRequested(
    AdminDriverRefreshRequested event,
    Emitter<AdminState> emit,
  ) async {
    final result = await adminRepository.getDriver(uid: event.uid);

    result.fold(
      (failure) {
        // Error transitorio (red, etc.) -- no interrumpe al admin, se queda
        // con los datos cacheados hasta el próximo refresh real.
      },
      (driver) {
        if (driver == null) {
          // Se eliminó mientras se veía el detalle -- se quita de ambas listas.
          emit(
            state.copyWith(
              loadedDrivers:
                  state.loadedDrivers
                      .where((d) => d.uid != event.uid)
                      .toList(),
              searchResults:
                  state.searchResults
                      ?.where((d) => d.uid != event.uid)
                      .toList(),
            ),
          );
          return;
        }

        AdminDriverEntity patch(AdminDriverEntity d) =>
            d.uid == event.uid ? driver : d;

        emit(
          state.copyWith(
            loadedDrivers: state.loadedDrivers.map(patch).toList(),
            searchResults: state.searchResults?.map(patch).toList(),
          ),
        );
      },
    );
  }
}
