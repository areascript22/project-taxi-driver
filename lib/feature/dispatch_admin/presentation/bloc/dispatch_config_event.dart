part of 'dispatch_config_bloc.dart';

@immutable
sealed class DispatchConfigEvent {}

class DispatchConfigLoadRequested extends DispatchConfigEvent {}

/// Se editó un campo de un anillo del borrador. [index] es la posición (0 = el
/// anillo 1).
class DispatchRingChanged extends DispatchConfigEvent {
  DispatchRingChanged({required this.index, required this.ring});

  final int index;
  final DispatchRingEntity ring;
}

class DispatchRingAdded extends DispatchConfigEvent {}

class DispatchRingRemoved extends DispatchConfigEvent {
  DispatchRingRemoved({required this.index});

  final int index;
}

class DispatchLocationMaxAgeChanged extends DispatchConfigEvent {
  DispatchLocationMaxAgeChanged({required this.seconds});

  final int seconds;
}

/// Vuelve el borrador a lo guardado.
class DispatchDraftDiscarded extends DispatchConfigEvent {}

class DispatchSaveRequested extends DispatchConfigEvent {}

/// Solo el superuser: enciende o apaga "los admins pueden editar".
class DispatchAdminEditingToggled extends DispatchConfigEvent {
  DispatchAdminEditingToggled({required this.enabled});

  final bool enabled;
}
