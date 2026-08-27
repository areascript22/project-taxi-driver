import 'admin_vehicle_entity.dart';

class AdminDriverEntity {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final String fcmToken;
  final double rating;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AdminVehicleEntity? vehicle;

  AdminDriverEntity({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    this.fcmToken = '',
    this.rating = 5.0,
    this.role = 'driver',
    this.createdAt,
    this.updatedAt,
    this.vehicle,
  });

  String get fullName => '$firstName $lastName'.trim();

  AdminDriverEntity copyWith({String? role}) {
    return AdminDriverEntity(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      fcmToken: fcmToken,
      rating: rating,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt,
      vehicle: vehicle,
    );
  }
}
