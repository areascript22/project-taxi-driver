class PassengerEntity {
  final String name;
  final String profileImage;

  PassengerEntity({required this.name, required this.profileImage});

  factory PassengerEntity.fromMap(Map<dynamic, dynamic> map) {
    return PassengerEntity(
      name: map['name'] ?? '',
      profileImage: map['profileImage'] ?? '',
    );
  }
}

class PickupLocationEntity {
  final String address;

  /// Sector de Riobamba donde hay que recoger al pasajero (ej. "La Condamine").
  /// Es la referencia que se le anuncia al conductor por voz y la que ve en la
  /// lista de solicitudes; la dirección exacta la ve al aceptar la carrera.
  ///
  /// Vacío en carreras viejas (anteriores al campo) o si passenger_app no pudo
  /// resolverlo: ahí se cae a [address], que es lo que se hacía antes.
  final String sector;

  final double latitude;
  final double longitude;

  PickupLocationEntity({
    required this.address,
    required this.sector,
    required this.latitude,
    required this.longitude,
  });

  factory PickupLocationEntity.fromMap(Map<dynamic, dynamic> map) {
    return PickupLocationEntity(
      address: map['address'] ?? '',
      sector: map['sector'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class IncomingRequestEntity {
  final String rideId;
  final String userId;
  final String status;
  final int createdAt;
  final int updatedAt;
  final PassengerEntity passenger;
  final PickupLocationEntity pickupLocation;

  IncomingRequestEntity({
    required this.rideId,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.passenger,
    required this.pickupLocation,
  });

  factory IncomingRequestEntity.fromMap(Map<dynamic, dynamic> map) {
    return IncomingRequestEntity(
      rideId: map['rideId'] ?? '',
      userId: map['userId'] ?? '',
      status: map['status'] ?? '',
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
      passenger: PassengerEntity.fromMap(map['passenger'] ?? {}),
      pickupLocation: PickupLocationEntity.fromMap(map['pickupLocation'] ?? {}),
    );
  }

  /// Una oferta de la bandeja `driver_offers/{uid}/{passengerId}`: lo que el
  /// despacho le dejo a ESTE conductor. Tiene otra forma que el nodo de la
  /// carrera (el conductor ya no lee el nodo de la carrera hasta aceptarla):
  ///
  ///   { rideId, passengerId, passengerName, pickup: {latitude, longitude,
  ///     address, sector}, ring, distanceMeters, expiresAt }
  ///
  /// Una oferta siempre es de una solicitud pendiente, por eso `status` es
  /// 'pending' y no viene en el mapa.
  factory IncomingRequestEntity.fromOffer(Map<dynamic, dynamic> map) {
    return IncomingRequestEntity(
      rideId: map['rideId'] ?? '',
      userId: map['passengerId'] ?? '',
      status: 'pending',
      createdAt: 0,
      updatedAt: 0,
      passenger: PassengerEntity(
        name: map['passengerName'] ?? '',
        // La oferta no lleva foto: el conductor la ve al aceptar.
        profileImage: '',
      ),
      pickupLocation: PickupLocationEntity.fromMap(map['pickup'] ?? {}),
    );
  }

  /// Si una oferta ya perdio sentido (el servidor la retira al terminar la
  /// busqueda; esto es la red de seguridad si ese retiro fallo o la app estuvo
  /// sin conexion). Una oferta sin vencimiento no vence.
  static bool isOfferExpired(Map<dynamic, dynamic> map, {DateTime? now}) {
    final expiresAt = map['expiresAt'];
    if (expiresAt is! num) return false;
    final nowMillis = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return expiresAt <= nowMillis;
  }
}
