import 'dispatch_limits_entity.dart';
import 'dispatch_ring_entity.dart';

/// La configuración del despacho como la ve el panel de administración.
///
/// [version] es la que el servidor espera de vuelta al guardar (si ya cambió,
/// responde conflicto). [canEdit] y [canChangeAdminEditing] dicen qué puede
/// hacer QUIEN pregunta: la pantalla no adivina permisos por el rol.
class DispatchConfigEntity {
  const DispatchConfigEntity({
    required this.rings,
    required this.locationMaxAgeSeconds,
    required this.adminsCanEdit,
    required this.version,
    required this.updatedAt,
    required this.updatedByName,
    required this.totalWaitSeconds,
    required this.requestExpirySeconds,
    required this.canEdit,
    required this.canChangeAdminEditing,
    required this.limits,
  });

  final List<DispatchRingEntity> rings;
  final int locationMaxAgeSeconds;
  final bool adminsCanEdit;
  final int version;
  final DateTime? updatedAt;

  /// Vacío si nadie la editó todavía (valores iniciales) o la persona se borró.
  final String updatedByName;
  final int totalWaitSeconds;
  final int requestExpirySeconds;
  final bool canEdit;
  final bool canChangeAdminEditing;
  final DispatchLimitsEntity limits;
}
