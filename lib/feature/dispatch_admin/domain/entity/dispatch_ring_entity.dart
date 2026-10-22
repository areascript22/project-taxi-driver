/// Un anillo de búsqueda: a quiénes se les ofrece una carrera (los disponibles
/// a menos de [radiusMeters], hasta [maxDrivers]) y cuánto se espera
/// ([waitSeconds]) antes de ampliar al siguiente. El número del anillo es su
/// posición en la lista (el primero es el 1).
class DispatchRingEntity {
  const DispatchRingEntity({
    required this.radiusMeters,
    required this.waitSeconds,
    required this.maxDrivers,
  });

  final int radiusMeters;
  final int waitSeconds;
  final int maxDrivers;

  DispatchRingEntity copyWith({
    int? radiusMeters,
    int? waitSeconds,
    int? maxDrivers,
  }) {
    return DispatchRingEntity(
      radiusMeters: radiusMeters ?? this.radiusMeters,
      waitSeconds: waitSeconds ?? this.waitSeconds,
      maxDrivers: maxDrivers ?? this.maxDrivers,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DispatchRingEntity &&
        other.radiusMeters == radiusMeters &&
        other.waitSeconds == waitSeconds &&
        other.maxDrivers == maxDrivers;
  }

  @override
  int get hashCode => Object.hash(radiusMeters, waitSeconds, maxDrivers);
}
