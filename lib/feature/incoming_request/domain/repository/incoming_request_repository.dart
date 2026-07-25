import 'package:firebase_database/firebase_database.dart';
import '../entity/incoming_request_entity.dart';

class IncomingRequestRepository {
  // Aplicamos el query directamente a nivel de base de datos
  final Query _pendingRequestsQuery = FirebaseDatabase.instance
      .ref('taxi_requests')
      .orderByChild('status')
      .equalTo('pending');

  Stream<IncomingRequestEntity> get onRequestAdded {
    return _pendingRequestsQuery.onChildAdded.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return IncomingRequestEntity.fromMap(data);
    });
  }

  Stream<IncomingRequestEntity> get onRequestChanged {
    return _pendingRequestsQuery.onChildChanged.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return IncomingRequestEntity.fromMap(data);
    });
  }

  Stream<String> get onRequestRemoved {
    return _pendingRequestsQuery.onChildRemoved.map((event) {
      // En Firebase, onChildRemoved devuelve el snapshot con la data original
      // antes de que fuera eliminada o dejara de coincidir con el query.
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      // Extraemos el rideId exacto directamente del objeto
      if (data != null && data.containsKey('rideId')) {
        return data['rideId'].toString();
      }

      // Fallback por seguridad
      return event.snapshot.key ?? '';
    });
  }
}
