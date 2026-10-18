import '../../domain/entity/driver_entity.dart';

/// El conductor tal como lo devuelve `GET /api/me`.
///
/// La respuesta mezcla la identidad (nombre, rol, bloqueo: viven en `users`)
/// con el perfil (`driver`: teléfono, aprobación, calificación); este modelo
/// los junta. `fcmToken` no viaja: el servidor no lo expone y la app no lo
/// necesita para decidir su ruta.
class DriverModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final double rating;
  final String role;
  final String approvalStatus;
  final bool isBlocked;
  final String? blockReason;
  final String? rejectionReason;

  DriverModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    required this.rating,
    required this.role,
    required this.approvalStatus,
    required this.isBlocked,
    this.blockReason,
    this.rejectionReason,
  });

  /// `null` si la persona existe pero no tiene perfil de conductor.
  static DriverModel? fromMe(Map<String, dynamic> me) {
    final driver = me['driver'] as Map<String, dynamic>?;
    if (driver == null) {
      return null;
    }
    return DriverModel(
      id: me['uid'] as String? ?? '',
      firstName: me['firstName'] as String? ?? '',
      lastName: me['lastName'] as String? ?? '',
      email: me['email'] as String? ?? '',
      phoneNumber: driver['phoneNumber'] as String? ?? '',
      photoUrl: driver['photoUrl'] as String?,
      rating: (driver['rating'] as num?)?.toDouble() ?? 5.0,
      role: me['role'] as String? ?? 'user',
      approvalStatus: driver['approvalStatus'] as String? ?? 'pending',
      isBlocked: me['blocked'] as bool? ?? false,
      blockReason: me['blockReason'] as String?,
      rejectionReason: driver['rejectionReason'] as String?,
    );
  }

  DriverEntity toEntity() {
    return DriverEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      fcmToken: '',
      vehicleId: '',
      rating: rating,
      // 'user' es el rol base del servidor; en esta app es un conductor.
      role: role == 'user' ? 'driver' : role,
      approvalStatus: approvalStatus,
      isBlocked: isBlocked,
      blockReason: blockReason,
      rejectionReason: rejectionReason,
    );
  }
}
