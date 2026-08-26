class AdminDriverEntity {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final String role;

  AdminDriverEntity({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    this.role = 'driver',
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
      role: role ?? this.role,
    );
  }
}
