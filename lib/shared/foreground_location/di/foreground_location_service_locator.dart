import 'package:get_it/get_it.dart';
import '../../battery_optimization/service/battery_optimization_service.dart';
import '../../presence/data/repository/driver_presence_repository_impl.dart';
import '../../presence/domain/repository/driver_presence_repository.dart';
import '../presentation/bloc/foreground_service_bloc.dart';
import '../service/driver_foreground_service.dart';
import '../service/driver_foreground_service_impl.dart';

void initForegroundLocationDI(GetIt sl) {
  // Singleton: hay un único foreground service real por app; TripBloc y
  // el toggle de prueba deben controlar la misma instancia.
  sl.registerLazySingleton<DriverForegroundService>(
    () => DriverForegroundServiceImpl(),
  );
  sl.registerLazySingleton<DriverPresenceRepository>(
    () => DriverPresenceRepositoryImpl(),
  );
  sl.registerFactory(
    () => ForegroundServiceBloc(
      driverForegroundService: sl<DriverForegroundService>(),
      batteryOptimizationService: sl<BatteryOptimizationService>(),
      driverPresenceRepository: sl<DriverPresenceRepository>(),
    ),
  );
}
