import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../domain/dispatch_config_rules.dart';
import '../../domain/entity/dispatch_config_entity.dart';
import '../../domain/entity/dispatch_ring_entity.dart';
import '../../domain/repository/dispatch_admin_repository.dart';

part 'dispatch_config_event.dart';
part 'dispatch_config_state.dart';

// La pantalla de configuración del despacho. Mantiene un BORRADOR separado de lo
// guardado: la persona edita el borrador, y solo "Guardar" lo manda al servidor.
//
// Quién puede editar lo dice el servidor en la configuración (canEdit): un
// administrador con el interruptor apagado ve todo pero no puede cambiar nada,
// y el bloc ignora cualquier edición en ese caso.
class DispatchConfigBloc
    extends Bloc<DispatchConfigEvent, DispatchConfigState> {
  DispatchConfigBloc({required this.repository})
    : super(const DispatchConfigState()) {
    on<DispatchConfigLoadRequested>(_onLoadRequested);
    on<DispatchRingChanged>(_onRingChanged);
    on<DispatchRingAdded>(_onRingAdded);
    on<DispatchRingRemoved>(_onRingRemoved);
    on<DispatchLocationMaxAgeChanged>(_onLocationMaxAgeChanged);
    on<DispatchDraftDiscarded>(_onDraftDiscarded);
    on<DispatchSaveRequested>(_onSaveRequested);
    on<DispatchAdminEditingToggled>(_onAdminEditingToggled);
  }

  final DispatchAdminRepository repository;

  Future<void> _onLoadRequested(
    DispatchConfigLoadRequested event,
    Emitter<DispatchConfigState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorCode: null));

    final result = await repository.getConfig();

    result.fold(
      (failure) => emit(_withError(state.copyWith(isLoading: false), failure)),
      (config) => emit(_loaded(config)),
    );
  }

  void _onRingChanged(
    DispatchRingChanged event,
    Emitter<DispatchConfigState> emit,
  ) {
    if (!_canEditDraft || event.index < 0 || event.index >= state.draftRings.length) {
      return;
    }
    final rings = [...state.draftRings];
    rings[event.index] = event.ring;
    emit(state.copyWith(draftRings: rings));
  }

  void _onRingAdded(
    DispatchRingAdded event,
    Emitter<DispatchConfigState> emit,
  ) {
    final config = state.config;
    if (!_canEditDraft || config == null) return;
    if (state.draftRings.length >= config.limits.maxRings) return;

    // El nuevo anillo arranca un poco más allá del último, con sus mismas
    // esperas: es lo que casi siempre se quiere, y cumple "el radio crece".
    final last = state.draftRings.isEmpty ? null : state.draftRings.last;
    final radius =
        last == null
            ? config.limits.minRadiusMeters
            : (last.radiusMeters + 1000).clamp(
              config.limits.minRadiusMeters,
              config.limits.maxRadiusMeters,
            );
    final added = DispatchRingEntity(
      radiusMeters: radius,
      waitSeconds: last?.waitSeconds ?? 10,
      maxDrivers: last?.maxDrivers ?? 10,
    );
    emit(state.copyWith(draftRings: [...state.draftRings, added]));
  }

  void _onRingRemoved(
    DispatchRingRemoved event,
    Emitter<DispatchConfigState> emit,
  ) {
    if (!_canEditDraft || event.index < 0 || event.index >= state.draftRings.length) {
      return;
    }
    final rings = [...state.draftRings]..removeAt(event.index);
    emit(state.copyWith(draftRings: rings));
  }

  void _onLocationMaxAgeChanged(
    DispatchLocationMaxAgeChanged event,
    Emitter<DispatchConfigState> emit,
  ) {
    if (!_canEditDraft) return;
    emit(state.copyWith(draftLocationMaxAgeSeconds: event.seconds));
  }

  void _onDraftDiscarded(
    DispatchDraftDiscarded event,
    Emitter<DispatchConfigState> emit,
  ) {
    final config = state.config;
    if (config == null || state.isSaving) return;
    emit(
      state.copyWith(
        draftRings: config.rings,
        draftLocationMaxAgeSeconds: config.locationMaxAgeSeconds,
      ),
    );
  }

  Future<void> _onSaveRequested(
    DispatchSaveRequested event,
    Emitter<DispatchConfigState> emit,
  ) async {
    final config = state.config;
    // Mismas guardas que el botón: un doble toque, un borrador inválido o sin
    // cambios, o una persona sin permiso no llegan al servidor.
    if (config == null || !state.canSave) return;

    emit(state.copyWith(isSaving: true, errorCode: null));

    final result = await repository.saveConfig(
      rings: state.draftRings,
      locationMaxAgeSeconds: state.draftLocationMaxAgeSeconds,
      expectedVersion: config.version,
    );

    await result.fold(
      (failure) async {
        if (failure.code == FailureCode.dispatchConfigConflict) {
          // Otro administrador guardó antes. Se recarga lo vigente (y se
          // descarta el borrador, que ya está desactualizado) para que la
          // persona vea con qué volver a aplicar sus cambios.
          final reloaded = await repository.getConfig();
          reloaded.fold(
            (_) => emit(
              _withError(state.copyWith(isSaving: false), failure),
            ),
            (fresh) => emit(
              _withError(_loaded(fresh).copyWith(isSaving: false), failure),
            ),
          );
          return;
        }
        emit(_withError(state.copyWith(isSaving: false), failure));
      },
      (saved) async {
        emit(
          _withNotice(
            _loaded(saved).copyWith(isSaving: false),
            DispatchConfigNotice.saved,
          ),
        );
      },
    );
  }

  Future<void> _onAdminEditingToggled(
    DispatchAdminEditingToggled event,
    Emitter<DispatchConfigState> emit,
  ) async {
    if (!state.canChangeAdminEditing || state.isTogglingAdminEditing) return;
    if (state.config?.adminsCanEdit == event.enabled) return;

    emit(state.copyWith(isTogglingAdminEditing: true, errorCode: null));

    final result = await repository.setAdminEditing(enabled: event.enabled);

    result.fold(
      (failure) => emit(
        _withError(state.copyWith(isTogglingAdminEditing: false), failure),
      ),
      (updated) => emit(
        // Solo cambia lo guardado: el borrador que la persona tenga a medias no
        // se toca (mover el interruptor no cambia los anillos).
        _withNotice(
          state.copyWith(isTogglingAdminEditing: false, config: updated),
          event.enabled
              ? DispatchConfigNotice.adminEditingEnabled
              : DispatchConfigNotice.adminEditingDisabled,
        ),
      ),
    );
  }

  bool get _canEditDraft => state.canEdit && !state.isSaving && !state.isLoading;

  DispatchConfigState _loaded(DispatchConfigEntity config) {
    return state.copyWith(
      isLoading: false,
      config: config,
      draftRings: config.rings,
      draftLocationMaxAgeSeconds: config.locationMaxAgeSeconds,
    );
  }

  DispatchConfigState _withError(DispatchConfigState base, Failure failure) {
    return base.copyWith(
      errorCode: failure.code,
      errorSerial: state.errorSerial + 1,
    );
  }

  DispatchConfigState _withNotice(
    DispatchConfigState base,
    DispatchConfigNotice notice,
  ) {
    return base.copyWith(
      notice: notice,
      noticeSerial: state.noticeSerial + 1,
    );
  }
}
