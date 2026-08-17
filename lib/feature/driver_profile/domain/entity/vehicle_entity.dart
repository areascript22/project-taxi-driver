class VehicleEntity {
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

  VehicleEntity({
    required this.vehicleId,
    required this.driverId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.registrationNumber,
    this.verificationStatus = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  VehicleEntity copyWith({String? vehicleId, String? driverId}) {
    return VehicleEntity(
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
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
