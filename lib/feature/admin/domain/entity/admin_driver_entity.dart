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
  // 'pending' | 'approved' | 'rejected' -- si un admin no ha aprobado al
  // conductor todavía, no puede recibir carreras (ver SessionBloc).
  final String approvalStatus;
  final bool isBlocked;
  final String? blockReason;
  final DateTime? blockedAt;
  final String? blockedBy;
  final String? rejectionReason;
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
    this.approvalStatus = 'approved',
    this.isBlocked = false,
    this.blockReason,
    this.blockedAt,
    this.blockedBy,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.vehicle,
  });

  String get fullName => '$firstName $lastName'.trim();

  AdminDriverEntity copyWith({
    String? role,
    String? approvalStatus,
    bool? isBlocked,
    String? blockReason,
    DateTime? blockedAt,
    String? blockedBy,
    String? rejectionReason,
    bool clearBlockInfo = false,
    bool clearRejectionReason = false,
  }) {
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
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: clearBlockInfo ? null : (blockReason ?? this.blockReason),
      blockedAt: clearBlockInfo ? null : (blockedAt ?? this.blockedAt),
      blockedBy: clearBlockInfo ? null : (blockedBy ?? this.blockedBy),
      rejectionReason:
          clearRejectionReason ? null : (rejectionReason ?? this.rejectionReason),
      createdAt: createdAt,
      updatedAt: updatedAt,
      vehicle: vehicle,
    );
  }
}
