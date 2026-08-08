import 'package:get_it/get_it.dart';
import '../service/driver_foreground_service.dart';
import '../service/driver_foreground_service_impl.dart';
import '../presentation/bloc/foreground_service_bloc.dart';

void initForegroundLocationDI(GetIt sl) {
  // Singleton: hay un único foreground service real por app; TripBloc y
  // el toggle de prueba deben controlar la misma instancia.
  sl.registerLazySingleton<DriverForegroundService>(
    () => DriverForegroundServiceImpl(),
  );
  sl.registerFactory(
    () => ForegroundServiceBloc(
      driverForegroundService: sl<DriverForegroundService>(),
    ),
  );
}
