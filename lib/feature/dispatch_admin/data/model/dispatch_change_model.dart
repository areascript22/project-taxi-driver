import '../../domain/entity/dispatch_change_entity.dart';
import 'dispatch_config_model.dart';

/// `GET /api/admin/dispatch/config/history`.
class DispatchHistoryPageModel {
  const DispatchHistoryPageModel({
    required this.changes,
    required this.nextBeforeId,
  });

  final List<DispatchChangeEntity> changes;
  final int? nextBeforeId;

  factory DispatchHistoryPageModel.fromJson(Map<String, dynamic> json) {
    return DispatchHistoryPageModel(
      changes:
          (json['changes'] as List)
              .map((e) => _changeFromJson(e as Map<String, dynamic>))
              .toList(),
      nextBeforeId: (json['nextBeforeId'] as num?)?.toInt(),
    );
  }

  DispatchHistoryPageEntity toEntity() =>
      DispatchHistoryPageEntity(changes: changes, nextBeforeId: nextBeforeId);

  static DispatchChangeEntity _changeFromJson(Map<String, dynamic> json) {
    return DispatchChangeEntity(
      id: (json['id'] as num).toInt(),
      changedAt: parseDispatchDate(json['changedAt']),
      changedByName: json['changedByName'] as String? ?? '',
      type: _typeOf(json['type'] as String?),
      before: _snapshotFromJson(json['before'] as Map<String, dynamic>),
      after: _snapshotFromJson(json['after'] as Map<String, dynamic>),
    );
  }

  // Un tipo que esta versión de la app no conoce se muestra como edición de
  // configuración: es lo más cercano a la verdad y no tumba el historial.
  static DispatchChangeType _typeOf(String? wire) {
    return wire == 'admins_can_edit'
        ? DispatchChangeType.adminsCanEdit
        : DispatchChangeType.config;
  }

  static DispatchSnapshotEntity _snapshotFromJson(Map<String, dynamic> json) {
    return DispatchSnapshotEntity(
      rings:
          (json['rings'] as List)
              .map((e) => DispatchRingModel.fromJson(e as Map<String, dynamic>))
              .map((ring) => ring.toEntity())
              .toList(),
      locationMaxAgeSeconds: (json['locationMaxAgeSeconds'] as num).toInt(),
      adminsCanEdit: json['adminsCanEdit'] as bool? ?? false,
    );
  }
}
