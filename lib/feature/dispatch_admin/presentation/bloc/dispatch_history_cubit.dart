import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../domain/entity/dispatch_change_entity.dart';
import '../../domain/repository/dispatch_admin_repository.dart';

@immutable
class DispatchHistoryState {
  const DispatchHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorCode,
    this.changes = const [],
    this.nextBeforeId,
    this.loaded = false,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final FailureCode? errorCode;
  final List<DispatchChangeEntity> changes;

  /// null = no hay más páginas.
  final int? nextBeforeId;

  /// true cuando ya terminó al menos una carga (para distinguir "vacío" de
  /// "todavía no cargó").
  final bool loaded;

  bool get hasMore => nextBeforeId != null;
}

// El historial de cambios, de más nuevo a más viejo, por páginas.
class DispatchHistoryCubit extends Cubit<DispatchHistoryState> {
  DispatchHistoryCubit({required this.repository})
    : super(const DispatchHistoryState());

  static const pageSize = 20;

  final DispatchAdminRepository repository;

  Future<void> load() async {
    if (state.isLoading) return;
    emit(const DispatchHistoryState(isLoading: true));

    final result = await repository.getHistory(limit: pageSize);

    result.fold(
      (failure) => emit(
        DispatchHistoryState(errorCode: failure.code, loaded: true),
      ),
      (page) => emit(
        DispatchHistoryState(
          changes: page.changes,
          nextBeforeId: page.nextBeforeId,
          loaded: true,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final cursor = state.nextBeforeId;
    if (cursor == null || state.isLoading || state.isLoadingMore) return;

    emit(
      DispatchHistoryState(
        changes: state.changes,
        nextBeforeId: cursor,
        isLoadingMore: true,
        loaded: true,
      ),
    );

    final result = await repository.getHistory(
      limit: pageSize,
      beforeId: cursor,
    );

    result.fold(
      // Lo ya cargado se queda: un fallo al pedir más no borra la lista.
      (failure) => emit(
        DispatchHistoryState(
          changes: state.changes,
          nextBeforeId: cursor,
          errorCode: failure.code,
          loaded: true,
        ),
      ),
      (page) => emit(
        DispatchHistoryState(
          changes: [...state.changes, ...page.changes],
          nextBeforeId: page.nextBeforeId,
          loaded: true,
        ),
      ),
    );
  }
}
