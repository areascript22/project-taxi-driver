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
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
