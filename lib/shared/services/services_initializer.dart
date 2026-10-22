import '../../core/service_locator/main_service_locator.dart';
import '../foreground_location/service/driver_foreground_service.dart';
import 'dotenv/dotenv_service.dart';

class ServicesInitializer{
  static Future<void> initializeServices() async {
    await mainServiceLocator<DotEnvService>().initialize();
    await mainServiceLocator<DriverForegroundService>().configure();
  }
}