import 'entity/dispatch_limits_entity.dart';
import 'entity/dispatch_ring_entity.dart';

/// Problemas de UN anillo del borrador.
enum DispatchRingIssue {
  radiusOutOfRange,

  /// El radio no es mayor que el del anillo anterior (un anillo que no amplía
  /// nada no busca a nadie nuevo).
  radiusNotIncreasing,
  waitOutOfRange,
  maxDriversOutOfRange,
}

/// Problemas del borrador en conjunto.
enum DispatchDraftIssue {
  noRings,
  tooManyRings,
  totalWaitTooLong,
  locationAgeOutOfRange,
}

/// El resultado de validar un borrador: qué le pasa a cada anillo (por
/// posición) y qué le pasa al conjunto.
class DispatchDraftValidation {
  const DispatchDraftValidation({
    required this.ringIssues,
    required this.draftIssues,
  });

  final Map<int, Set<DispatchRingIssue>> ringIssues;
  final Set<DispatchDraftIssue> draftIssues;

  bool get isValid => ringIssues.isEmpty && draftIssues.isEmpty;
}

/// Lo que dura la búsqueda completa: la suma de las esperas.
int totalWaitSecondsOf({required List<DispatchRingEntity> rings}) {
  return rings.fold(0, (sum, ring) => sum + ring.waitSeconds);
}

/// Valida un borrador con los topes que dicta el servidor. Es el mismo criterio
/// que el servidor aplica al guardar (que sigue siendo quien decide): sirve para
/// mostrar el problema junto al campo y no dejar enviar algo que va a rechazar.
DispatchDraftValidation validateDispatchDraft({
  required List<DispatchRingEntity> rings,
  required int locationMaxAgeSeconds,
  required DispatchLimitsEntity limits,
}) {
  final ringIssues = <int, Set<DispatchRingIssue>>{};
  final draftIssues = <DispatchDraftIssue>{};

  void addRingIssue(int index, DispatchRingIssue issue) {
    ringIssues.putIfAbsent(index, () => <DispatchRingIssue>{}).add(issue);
  }

  if (rings.isEmpty) {
    draftIssues.add(DispatchDraftIssue.noRings);
  }
  if (rings.length > limits.maxRings) {
    draftIssues.add(DispatchDraftIssue.tooManyRings);
  }

  for (var i = 0; i < rings.length; i++) {
    final ring = rings[i];
    if (ring.radiusMeters < limits.minRadiusMeters ||
        ring.radiusMeters > limits.maxRadiusMeters) {
      addRingIssue(i, DispatchRingIssue.radiusOutOfRange);
    } else if (i > 0 && ring.radiusMeters <= rings[i - 1].radiusMeters) {
      addRingIssue(i, DispatchRingIssue.radiusNotIncreasing);
    }
    if (ring.waitSeconds < limits.minWaitSeconds ||
        ring.waitSeconds > limits.maxWaitSeconds) {
      addRingIssue(i, DispatchRingIssue.waitOutOfRange);
    }
    if (ring.maxDrivers < limits.minMaxDrivers ||
        ring.maxDrivers > limits.maxMaxDrivers) {
      addRingIssue(i, DispatchRingIssue.maxDriversOutOfRange);
    }
  }

  if (totalWaitSecondsOf(rings: rings) > limits.maxTotalWaitSeconds) {
    draftIssues.add(DispatchDraftIssue.totalWaitTooLong);
  }
  if (locationMaxAgeSeconds < limits.minLocationMaxAgeSeconds ||
      locationMaxAgeSeconds > limits.maxLocationMaxAgeSeconds) {
    draftIssues.add(DispatchDraftIssue.locationAgeOutOfRange);
  }

  return DispatchDraftValidation(
    ringIssues: ringIssues,
    draftIssues: draftIssues,
  );
}
