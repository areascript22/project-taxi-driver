// Controla el foreground service que mantiene viva la app en background y
// reporta la ubicación del conductor. Es el único punto de entrada que el
// resto de la app debe usar para arrancar/detener ese servicio -- ningún
// feature necesita saber que por debajo hay un plugin nativo + un isolate.
abstract class DriverForegroundService {
  // Registra el callback nativo del servicio. Se llama una sola vez al
  // arrancar la app, antes de que cualquier feature intente start()/stop().
  Future<void> configure();

  // Arranca (o reutiliza, si ya está corriendo) el foreground service.
  // `passengerId` nulo == modo de prueba: el servicio queda vivo con su
  // notificación persistente pero sin escribir ubicación en Firebase.
  // `passengerId` presente == arranca (o reemplaza) el tracking de ese viaje.
  Future<void> start({String? passengerId});

  // Detiene el servicio por completo (deja de trackear y quita la
  // notificación). Es seguro llamarlo aunque ya esté detenido.
  Future<void> stop();

  Future<bool> isRunning();
}
