class DriverEntity {
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
  // 'pending' | 'approved' | 'rejected'. Un conductor nuevo nace 'pending'
  // (ver registro en driver_onboarding_bloc.dart) y necesita que un admin lo
  // apruebe antes de poder recibir carreras -- ver SessionBloc.
  final String approvalStatus;
  final bool isBlocked;
  final String? blockReason;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DriverEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    this.fcmToken = '',
    this.vehicleId = '',
    this.rating = 5.0,
    this.role = 'driver',
    this.approvalStatus = 'pending',
    this.isBlocked = false,
    this.blockReason,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  DriverEntity copyWith({String? photoUrl, String? vehicleId}) {
    return DriverEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken,
      vehicleId: vehicleId ?? this.vehicleId,
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
