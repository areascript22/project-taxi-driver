import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entity/vehicle_entity.dart';

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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleModel.fromJson(
    Map<String, dynamic> json, {
    required String vehicleId,
  }) {
    return VehicleModel(
      vehicleId: vehicleId,
      driverId: json['driverId'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      color: json['color'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      verificationStatus: json['verificationStatus'] as String? ?? 'pending',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory VehicleModel.fromEntity(VehicleEntity entity) {
    return VehicleModel(
      vehicleId: entity.vehicleId,
      driverId: entity.driverId,
      plate: entity.plate,
      brand: entity.brand,
      model: entity.model,
      year: entity.year,
      color: entity.color,
      registrationNumber: entity.registrationNumber,
      verificationStatus: entity.verificationStatus,
    );
  }

  // No incluye vehicleId/createdAt/updatedAt: vehicleId es el nombre del
  // documento y las marcas de tiempo las agrega el repositorio con
  // FieldValue.serverTimestamp().
  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'plate': plate,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'registrationNumber': registrationNumber,
      'verificationStatus': verificationStatus,
    };
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
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
