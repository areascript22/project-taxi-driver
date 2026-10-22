import '../../domain/entity/dispatch_config_entity.dart';
import '../../domain/entity/dispatch_limits_entity.dart';
import '../../domain/entity/dispatch_ring_entity.dart';

/// Un anillo tal como viaja en el JSON del servidor.
class DispatchRingModel {
  const DispatchRingModel({
    required this.radiusMeters,
    required this.waitSeconds,
    required this.maxDrivers,
  });

  final int radiusMeters;
  final int waitSeconds;
  final int maxDrivers;

  factory DispatchRingModel.fromJson(Map<String, dynamic> json) {
    return DispatchRingModel(
      radiusMeters: (json['radiusMeters'] as num).toInt(),
      waitSeconds: (json['waitSeconds'] as num).toInt(),
      maxDrivers: (json['maxDrivers'] as num).toInt(),
    );
  }

  /// El número del anillo no se manda: lo da la posición en la lista.
  Map<String, dynamic> toJson() => {
    'radiusMeters': radiusMeters,
    'waitSeconds': waitSeconds,
    'maxDrivers': maxDrivers,
  };

  DispatchRingEntity toEntity() => DispatchRingEntity(
    radiusMeters: radiusMeters,
    waitSeconds: waitSeconds,
    maxDrivers: maxDrivers,
  );

  static DispatchRingModel fromEntity(DispatchRingEntity entity) =>
      DispatchRingModel(
        radiusMeters: entity.radiusMeters,
        waitSeconds: entity.waitSeconds,
        maxDrivers: entity.maxDrivers,
      );
}

/// `GET/PUT /api/admin/dispatch/config`.
class DispatchConfigModel {
  const DispatchConfigModel({
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

  final List<DispatchRingModel> rings;
  final int locationMaxAgeSeconds;
  final bool adminsCanEdit;
  final int version;
  final DateTime? updatedAt;
  final String updatedByName;
  final int totalWaitSeconds;
  final int requestExpirySeconds;
  final bool canEdit;
  final bool canChangeAdminEditing;
  final DispatchLimitsEntity limits;

  factory DispatchConfigModel.fromJson(Map<String, dynamic> json) {
    final limits = json['limits'] as Map<String, dynamic>;
    int limit(String key) => (limits[key] as num).toInt();

    return DispatchConfigModel(
      rings:
          (json['rings'] as List)
              .map((e) => DispatchRingModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      locationMaxAgeSeconds: (json['locationMaxAgeSeconds'] as num).toInt(),
      adminsCanEdit: json['adminsCanEdit'] as bool? ?? false,
      version: (json['version'] as num).toInt(),
      updatedAt: parseDispatchDate(json['updatedAt']),
      updatedByName: json['updatedByName'] as String? ?? '',
      totalWaitSeconds: (json['totalWaitSeconds'] as num).toInt(),
      requestExpirySeconds: (json['requestExpirySeconds'] as num).toInt(),
      canEdit: json['canEdit'] as bool? ?? false,
      canChangeAdminEditing: json['canChangeAdminEditing'] as bool? ?? false,
      limits: DispatchLimitsEntity(
        maxRings: limit('maxRings'),
        maxTotalWaitSeconds: limit('maxTotalWaitSeconds'),
        minLocationMaxAgeSeconds: limit('minLocationMaxAgeSeconds'),
        maxLocationMaxAgeSeconds: limit('maxLocationMaxAgeSeconds'),
        minRadiusMeters: limit('minRadiusMeters'),
        maxRadiusMeters: limit('maxRadiusMeters'),
        minWaitSeconds: limit('minWaitSeconds'),
        maxWaitSeconds: limit('maxWaitSeconds'),
        minMaxDrivers: limit('minMaxDrivers'),
        maxMaxDrivers: limit('maxMaxDrivers'),
      ),
    );
  }

  DispatchConfigEntity toEntity() => DispatchConfigEntity(
    rings: rings.map((ring) => ring.toEntity()).toList(),
    locationMaxAgeSeconds: locationMaxAgeSeconds,
    adminsCanEdit: adminsCanEdit,
    version: version,
    updatedAt: updatedAt,
    updatedByName: updatedByName,
    totalWaitSeconds: totalWaitSeconds,
    requestExpirySeconds: requestExpirySeconds,
    canEdit: canEdit,
    canChangeAdminEditing: canChangeAdminEditing,
    limits: limits,
  );
}

/// Fecha ISO-8601 del servidor; null si falta o no se entiende (una fecha
/// ilegible no debe tumbar la pantalla entera).
DateTime? parseDispatchDate(Object? raw) {
  if (raw is! String) return null;
  return DateTime.tryParse(raw)?.toLocal();
}
