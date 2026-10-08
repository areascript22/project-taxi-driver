part of 'admin_bloc.dart';

@immutable
sealed class AdminEvent {}

// (Re)carga desde cero: según el modo actual, pide la primera página al
// server (navegación) o el fetch completo (búsqueda). Se usa para la carga
// inicial de la pantalla y para el pull-to-refresh.
class AdminLoadRequested extends AdminEvent {}

class AdminSearchChanged extends AdminEvent {
  final String query;

  AdminSearchChanged({required this.query});
}

class AdminStatusFilterChanged extends AdminEvent {
  final AdminStatusFilter filter;

  AdminStatusFilterChanged({required this.filter});
}

// Solo avanza/retrocede un paso -- no se puede "saltar" a una página
// arbitraria bajo paginación por cursor (hay que recorrerlas en orden para
// obtener el cursor de cada una). Coincide con los botones de flecha que ya
// tenía la UI.
class AdminNextPageRequested extends AdminEvent {}

class AdminPreviousPageRequested extends AdminEvent {}

class AdminRoleChangeRequested extends AdminEvent {
  final String uid;
  final String role;

  AdminRoleChangeRequested({required this.uid, required this.role});
}

// Resincroniza un solo conductor -- se dispara al volver de la pantalla de
// detalle (donde pudo haberse aprobado/rechazado/bloqueado/desbloqueado/
// eliminado), sin perder la página actual de la lista.
class AdminDriverRefreshRequested extends AdminEvent {
  final String uid;

  AdminDriverRefreshRequested({required this.uid});
}
