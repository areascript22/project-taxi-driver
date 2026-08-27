class AdminVehicleEntity {
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

  AdminVehicleEntity({
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
}
