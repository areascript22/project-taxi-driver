import '../../domain/entity/admin_driver_entity.dart';

class AdminDriverModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final String role;

  AdminDriverModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    required this.role,
  });

  factory AdminDriverModel.fromJson(Map<String, dynamic> json) {
    return AdminDriverModel(
      uid: json['uid'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String? ?? 'driver',
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
      role: role,
    );
  }
}
