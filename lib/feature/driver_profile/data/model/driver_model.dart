import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entity/driver_entity.dart';

class DriverModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final String fcmToken;
  final String vehicleId;
  final double rating;
  final String role;
  final String approvalStatus;
  final bool isBlocked;
  final String? blockReason;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DriverModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    required this.fcmToken,
    required this.vehicleId,
    required this.rating,
    this.role = 'driver',
    this.approvalStatus = 'pending',
    this.isBlocked = false,
    this.blockReason,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json, {required String id}) {
    return DriverModel(
      id: id,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      fcmToken: json['fcmToken'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      role: json['role'] as String? ?? 'driver',
      // Conductores creados antes de introducir este campo no lo tienen en
      // Firestore -- se tratan como aprobados (ver backfill en el server)
      // en vez de dejarlos bloqueados por default.
      approvalStatus: json['approvalStatus'] as String? ?? 'approved',
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockReason: json['blockReason'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory DriverModel.fromEntity(DriverEntity entity) {
    return DriverModel(
      id: entity.id,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      photoUrl: entity.photoUrl,
      fcmToken: entity.fcmToken,
      vehicleId: entity.vehicleId,
      rating: entity.rating,
      role: entity.role,
      approvalStatus: entity.approvalStatus,
      isBlocked: entity.isBlocked,
    );
  }

  // No incluye id/createdAt/updatedAt: el id es el nombre del documento y
  // las marcas de tiempo las agrega el repositorio con FieldValue.serverTimestamp().
  // approvalStatus/isBlocked sí se incluyen explícitamente al crear (siempre
  // 'pending'/false para un registro nuevo) -- las reglas de Firestore
  // exigen que un conductor no pueda nacer ya aprobado o desbloqueado.
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'vehicleId': vehicleId,
      'rating': rating,
      'role': role,
      'approvalStatus': approvalStatus,
      'isBlocked': isBlocked,
    };
  }

  DriverEntity toEntity() {
    return DriverEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      fcmToken: fcmToken,
      vehicleId: vehicleId,
      rating: rating,
      role: role,
      approvalStatus: approvalStatus,
      isBlocked: isBlocked,
      blockReason: blockReason,
      rejectionReason: rejectionReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
