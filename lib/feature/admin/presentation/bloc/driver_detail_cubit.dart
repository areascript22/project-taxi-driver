import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../domain/entity/admin_driver_entity.dart';
import '../../domain/repository/admin_repository.dart';

@immutable
class DriverDetailState {
  final AdminDriverEntity driver;
  final bool isProcessing;
  final String? errorMessage;
  final bool wasDeleted;

  const DriverDetailState({
    required this.driver,
    this.isProcessing = false,
    this.errorMessage,
    this.wasDeleted = false,
  });

  DriverDetailState copyWith({
    AdminDriverEntity? driver,
    bool? isProcessing,
    String? errorMessage,
    bool? wasDeleted,
    bool clearError = false,
  }) {
    return DriverDetailState(
      driver: driver ?? this.driver,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      wasDeleted: wasDeleted ?? this.wasDeleted,
    );
  }
}

// Cubit propio de la pantalla de detalle, independiente del AdminBloc de la
// lista -- opera sobre un único conductor (aprobar/rechazar/bloquear/
// desbloquear/eliminar) sin necesitar la lista completa. AdminScreen se
// encarga de refrescarse sola al volver de esta pantalla (ver admin_screen.dart).
class DriverDetailCubit extends Cubit<DriverDetailState> {
  final AdminRepository adminRepository;

  DriverDetailCubit({
    required this.adminRepository,
    required AdminDriverEntity driver,
  }) : super(DriverDetailState(driver: driver));

  Future<void> approve() async {
    emit(state.copyWith(isProcessing: true, clearError: true));

    final result = await adminRepository.updateApprovalStatus(
      uid: state.driver.uid,
      status: 'approved',
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isProcessing: false, errorMessage: failure.message),
      ),
      (_) => emit(
        state.copyWith(
          isProcessing: false,
          driver: state.driver.copyWith(
            approvalStatus: 'approved',
            clearRejectionReason: true,
          ),
        ),
      ),
    );
  }

  Future<void> reject({required String reason}) async {
    emit(state.copyWith(isProcessing: true, clearError: true));

    final result = await adminRepository.updateApprovalStatus(
      uid: state.driver.uid,
      status: 'rejected',
      reason: reason,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isProcessing: false, errorMessage: failure.message),
      ),
      (_) => emit(
        state.copyWith(
          isProcessing: false,
          driver: state.driver.copyWith(
            approvalStatus: 'rejected',
            rejectionReason: reason,
          ),
        ),
      ),
    );
  }

  Future<void> block({required String reason}) async {
    emit(state.copyWith(isProcessing: true, clearError: true));

    final result = await adminRepository.updateBlockStatus(
      uid: state.driver.uid,
      blocked: true,
      reason: reason,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isProcessing: false, errorMessage: failure.message),
      ),
      (_) => emit(
        state.copyWith(
          isProcessing: false,
          driver: state.driver.copyWith(isBlocked: true, blockReason: reason),
        ),
      ),
    );
  }

  Future<void> unblock() async {
    emit(state.copyWith(isProcessing: true, clearError: true));

    final result = await adminRepository.updateBlockStatus(
      uid: state.driver.uid,
      blocked: false,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isProcessing: false, errorMessage: failure.message),
      ),
      (_) => emit(
        state.copyWith(
          isProcessing: false,
          driver: state.driver.copyWith(isBlocked: false, clearBlockInfo: true),
        ),
      ),
    );
  }

  Future<void> delete() async {
    emit(state.copyWith(isProcessing: true, clearError: true));

    final result = await adminRepository.deleteDriver(uid: state.driver.uid);

    result.fold(
      (failure) => emit(
        state.copyWith(isProcessing: false, errorMessage: failure.message),
      ),
      (_) => emit(state.copyWith(isProcessing: false, wasDeleted: true)),
    );
  }
}
