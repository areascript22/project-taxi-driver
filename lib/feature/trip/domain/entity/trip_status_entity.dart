class TripStatusEntity {
  final String status;
  // Quién canceló el viaje ('passenger' | 'driver'), solo relevante cuando
  // status == 'cancelled'.
  final String? cancelledBy;

  TripStatusEntity({required this.status, this.cancelledBy});

  factory TripStatusEntity.fromMap(Map<dynamic, dynamic> map) {
    return TripStatusEntity(
      status: map['status'] ?? '',
      cancelledBy: map['cancelledBy'] as String?,
    );
  }
}
