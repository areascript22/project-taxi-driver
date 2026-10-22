/// Los topes de lo que se puede configurar, tal como los dicta el servidor (la
/// app valida el formulario con estos mismos números, no con copias).
class DispatchLimitsEntity {
  const DispatchLimitsEntity({
    required this.maxRings,
    required this.maxTotalWaitSeconds,
    required this.minLocationMaxAgeSeconds,
    required this.maxLocationMaxAgeSeconds,
    required this.minRadiusMeters,
    required this.maxRadiusMeters,
    required this.minWaitSeconds,
    required this.maxWaitSeconds,
    required this.minMaxDrivers,
    required this.maxMaxDrivers,
  });

  final int maxRings;
  final int maxTotalWaitSeconds;
  final int minLocationMaxAgeSeconds;
  final int maxLocationMaxAgeSeconds;
  final int minRadiusMeters;
  final int maxRadiusMeters;
  final int minWaitSeconds;
  final int maxWaitSeconds;
  final int minMaxDrivers;
  final int maxMaxDrivers;
}
