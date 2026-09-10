import 'package:get_it/get_it.dart';
import '../service/battery_optimization_service.dart';
import '../service/battery_optimization_service_impl.dart';

void initBatteryOptimizationDI(GetIt sl) {
  sl.registerLazySingleton<BatteryOptimizationService>(
    () => BatteryOptimizationServiceImpl(),
  );
}
