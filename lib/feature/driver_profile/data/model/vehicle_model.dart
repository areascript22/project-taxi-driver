import '../../domain/entity/vehicle_entity.dart';

/// El vehículo tal como viene dentro de `GET /api/me` (`driver.vehicle`).
class VehicleModel {
  final String vehicleId;
  final String driverId;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String registrationNumber;
  final String verificationStatus;

  VehicleModel({
    required this.vehicleId,
    required this.driverId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.registrationNumber,
    required this.verificationStatus,
  });

  /// `null` si no hay perfil de conductor o este no tiene vehículo.
  static VehicleModel? fromMe(Map<String, dynamic> me) {
    final driver = me['driver'] as Map<String, dynamic>?;
    final vehicle = driver?['vehicle'] as Map<String, dynamic>?;
    if (vehicle == null) {
      return null;
    }
    return VehicleModel(
      vehicleId: vehicle['vehicleId'] as String? ?? '',
      driverId: me['uid'] as String? ?? '',
      plate: vehicle['plate'] as String? ?? '',
      brand: vehicle['brand'] as String? ?? '',
      model: vehicle['model'] as String? ?? '',
      year: (vehicle['year'] as num?)?.toInt() ?? 0,
      color: vehicle['color'] as String? ?? '',
      registrationNumber: vehicle['registrationNumber'] as String? ?? '',
      verificationStatus: vehicle['verificationStatus'] as String? ?? 'pending',
    );
  }

  VehicleEntity toEntity() {
    return VehicleEntity(
      vehicleId: vehicleId,
      driverId: driverId,
      plate: plate,
      brand: brand,
      model: model,
      year: year,
      color: color,
      registrationNumber: registrationNumber,
      verificationStatus: verificationStatus,
    );
  }
}
