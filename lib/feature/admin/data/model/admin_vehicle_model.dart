import '../../domain/entity/admin_vehicle_entity.dart';

class AdminVehicleModel {
  final String vehicleId;
  final String driverId;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String registrationNumber;
  final String verificationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminVehicleModel({
    required this.vehicleId,
    required this.driverId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.registrationNumber,
    required this.verificationStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminVehicleModel.fromJson(Map<String, dynamic> json) {
    return AdminVehicleModel(
      vehicleId: json['vehicleId'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      color: json['color'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      verificationStatus: json['verificationStatus'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  AdminVehicleEntity toEntity() {
    return AdminVehicleEntity(
      vehicleId: vehicleId,
      driverId: driverId,
      plate: plate,
      brand: brand,
      model: model,
      year: year,
      color: color,
      registrationNumber: registrationNumber,
      verificationStatus: verificationStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
