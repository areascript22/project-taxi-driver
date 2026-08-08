import 'package:get_it/get_it.dart';
import '../../../shared/foreground_location/service/driver_foreground_service.dart';
import '../data/repository/trip_repository_impl.dart';
import '../domain/repository/trip_repository.dart';
import '../presentation/bloc/trip_bloc.dart';

void initTripDI(GetIt sl) {
  sl.registerLazySingleton<TripRepository>(() => TripRepositoryImpl());
  // Singleton (no factory): TripScreen y ConfirmCancelTripDialog deben
  // compartir la MISMA instancia -- si no, el diálogo escucha un bloc
  // huérfano que nunca arrancó StartWatchingTrip y nunca se cierra solo.
  sl.registerLazySingleton(
    () => TripBloc(
      repository: sl<TripRepository>(),
      driverForegroundService: sl<DriverForegroundService>(),
    ),
  );
}
