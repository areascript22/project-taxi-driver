import '../../domain/entity/admin_driver_entity.dart';
import 'admin_vehicle_model.dart';

class AdminDriverModel {
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
  final AdminVehicleModel? vehicle;

  AdminDriverModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    required this.fcmToken,
    required this.rating,
    required this.role,
    this.createdAt,
    this.updatedAt,
    this.vehicle,
  });

  factory AdminDriverModel.fromJson(Map<String, dynamic> json) {
    return AdminDriverModel(
      uid: json['uid'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      fcmToken: json['fcmToken'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      role: json['role'] as String? ?? 'driver',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      vehicle:
          json['vehicle'] != null
              ? AdminVehicleModel.fromJson(
                json['vehicle'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'rating': rating,
      'role': role,
    };
  }

  AdminDriverEntity toEntity() {
    return AdminDriverEntity(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      fcmToken: fcmToken,
      rating: rating,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
      vehicle: vehicle?.toEntity(),
    );
  }
}
