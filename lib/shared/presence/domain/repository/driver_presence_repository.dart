import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';

/// Presencia del conductor frente al servidor: si esta "en linea" y donde esta.
///
/// Es lo que el despacho por cercania consulta para decidir a quien ofrecerle un
/// pedido. La app NO escribe esto en Firebase: lo manda al servidor, que decide
/// a donde va (ver ARCHITECTURE.md del servidor, "Un solo endpoint de
/// ubicacion, dos destinos").
abstract class DriverPresenceRepository {
  /// El interruptor "estoy en linea". Ponerse en linea exige estar aprobado y no
  /// bloqueado; desconectarse siempre se acepta.
  Future<Either<Failure, Unit>> setOnline({required bool online});

  /// Lo que el SERVIDOR cree: true si figura "en linea" (drivers.is_online).
  ///
  /// Es la fuente de verdad del interruptor: el servicio de Android local puede
  /// seguir vivo (o haberse caido) sin que el servidor lo sepa, y la base es lo
  /// que usa el despacho para decidir a quien ofrecerle un pedido.
  Future<Either<Failure, bool>> fetchOnline();

  /// Reporta la posicion actual.
  ///
  /// [passengerId] solo se manda cuando el conductor va en una carrera: el
  /// servidor la publica en el nodo de ese viaje para el mapa del pasajero. Sin
  /// el, la guarda para el despacho. La app no decide el destino.
  Future<Either<Failure, Unit>> reportLocation({
    required double latitude,
    required double longitude,
    String? passengerId,
  });
}
