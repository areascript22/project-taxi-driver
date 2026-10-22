part of 'dispatch_config_bloc.dart';

/// Avisos de éxito de un solo uso (la pantalla los muestra como toast).
enum DispatchConfigNotice { saved, adminEditingEnabled, adminEditingDisabled }

const Object _keep = Object();

@immutable
class DispatchConfigState {
  const DispatchConfigState({
    this.isLoading = false,
    this.isSaving = false,
    this.isTogglingAdminEditing = false,
    this.errorCode,
    this.errorSerial = 0,
    this.notice,
    this.noticeSerial = 0,
    this.config,
    this.draftRings = const [],
    this.draftLocationMaxAgeSeconds = 0,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isTogglingAdminEditing;

  // El código, no el texto: la pantalla lo traduce con context.failureText.
  // errorSerial sube con cada error para que el mismo error dos veces seguidas
  // se vuelva a mostrar (con el mismo código, el estado "no cambiaría").
  final FailureCode? errorCode;
  final int errorSerial;

  final DispatchConfigNotice? notice;
  final int noticeSerial;

  /// Lo guardado en el servidor. null mientras no se haya podido cargar.
  final DispatchConfigEntity? config;

  /// Lo que la persona está editando. Arranca igual a [config].
  final List<DispatchRingEntity> draftRings;
  final int draftLocationMaxAgeSeconds;

  bool get canEdit => config?.canEdit ?? false;
  bool get canChangeAdminEditing => config?.canChangeAdminEditing ?? false;

  bool get isDirty {
    final saved = config;
    if (saved == null) return false;
    if (draftLocationMaxAgeSeconds != saved.locationMaxAgeSeconds) return true;
    if (draftRings.length != saved.rings.length) return true;
    for (var i = 0; i < draftRings.length; i++) {
      if (draftRings[i] != saved.rings[i]) return true;
    }
    return false;
  }

  DispatchDraftValidation? get validation {
    final saved = config;
    if (saved == null) return null;
    return validateDispatchDraft(
      rings: draftRings,
      locationMaxAgeSeconds: draftLocationMaxAgeSeconds,
      limits: saved.limits,
    );
  }

  bool get canSave =>
      canEdit &&
      isDirty &&
      !isSaving &&
      !isLoading &&
      (validation?.isValid ?? false);

  int get draftTotalWaitSeconds => totalWaitSecondsOf(rings: draftRings);

  DispatchConfigState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isTogglingAdminEditing,
    Object? errorCode = _keep,
    int? errorSerial,
    Object? notice = _keep,
    int? noticeSerial,
    DispatchConfigEntity? config,
    List<DispatchRingEntity>? draftRings,
    int? draftLocationMaxAgeSeconds,
  }) {
    return DispatchConfigState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isTogglingAdminEditing:
          isTogglingAdminEditing ?? this.isTogglingAdminEditing,
      errorCode:
          identical(errorCode, _keep)
              ? this.errorCode
              : errorCode as FailureCode?,
      errorSerial: errorSerial ?? this.errorSerial,
      notice:
          identical(notice, _keep)
              ? this.notice
              : notice as DispatchConfigNotice?,
      noticeSerial: noticeSerial ?? this.noticeSerial,
      config: config ?? this.config,
      draftRings: draftRings ?? this.draftRings,
      draftLocationMaxAgeSeconds:
          draftLocationMaxAgeSeconds ?? this.draftLocationMaxAgeSeconds,
    );
  }
}
