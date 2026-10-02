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
    on<AdminPageChanged>(_onPageChanged);
    on<AdminRoleChangeRequested>(_onRoleChangeRequested);
  }

  Future<void> _onLoadRequested(
    AdminLoadRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await adminRepository.listDrivers();

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (drivers) {
        // No forzamos currentPage a 0: este evento también se usa para
        // refrescar la lista al volver de la pantalla de detalle (después de
        // aprobar/rechazar/bloquear/eliminar), y el admin no debería perder
        // la página en la que estaba. Si la lista encogió (p.ej. se eliminó
        // un conductor de la última página), solo recortamos al rango válido.
        final newState = state.copyWith(isLoading: false, drivers: drivers);
        final maxPage = newState.totalPages - 1;
        emit(
          newState.copyWith(
            currentPage: newState.currentPage.clamp(0, maxPage < 0 ? 0 : maxPage),
          ),
        );
      },
    );
  }

  void _onSearchChanged(AdminSearchChanged event, Emitter<AdminState> emit) {
    emit(state.copyWith(searchQuery: event.query, currentPage: 0));
  }

  void _onPageChanged(AdminPageChanged event, Emitter<AdminState> emit) {
    final maxPage = state.totalPages - 1;
    final page = event.page.clamp(0, maxPage < 0 ? 0 : maxPage);
    emit(state.copyWith(currentPage: page));
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
        final updatedDrivers =
            state.drivers.map((driver) {
              if (driver.uid != event.uid) return driver;
              return driver.copyWith(role: event.role);
            }).toList();
        emit(state.copyWith(drivers: updatedDrivers, clearActionUid: true));
      },
    );
  }
}
