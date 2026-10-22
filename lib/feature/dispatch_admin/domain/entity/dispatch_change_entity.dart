import 'dispatch_ring_entity.dart';

/// Qué tipo de cambio fue.
enum DispatchChangeType {
  /// Se editaron los anillos o la frescura de la ubicación.
  config,

  /// El superuser movió el interruptor "los admins pueden editar".
  adminsCanEdit,
}

/// La configuración en un instante (antes o después de un cambio).
class DispatchSnapshotEntity {
  const DispatchSnapshotEntity({
    required this.rings,
    required this.locationMaxAgeSeconds,
    required this.adminsCanEdit,
  });

  final List<DispatchRingEntity> rings;
  final int locationMaxAgeSeconds;
  final bool adminsCanEdit;
}

/// Una entrada del historial: quién, cuándo, qué tipo de cambio y cómo estaba
/// todo antes y después.
class DispatchChangeEntity {
  const DispatchChangeEntity({
    required this.id,
    required this.changedAt,
    required this.changedByName,
    required this.type,
    required this.before,
    required this.after,
  });

  final int id;
  final DateTime? changedAt;

  /// Vacío si la persona se borró después.
  final String changedByName;
  final DispatchChangeType type;
  final DispatchSnapshotEntity before;
  final DispatchSnapshotEntity after;
}

/// Una página del historial. [nextBeforeId] es lo que se manda como `beforeId`
/// para pedir la siguiente; null = no hay más.
class DispatchHistoryPageEntity {
  const DispatchHistoryPageEntity({
    required this.changes,
    required this.nextBeforeId,
  });

  final List<DispatchChangeEntity> changes;
  final int? nextBeforeId;
}
