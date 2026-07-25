import '../../core/service_locator/main_service_locator.dart';
import 'dotenv/dotenv_service.dart';

class ServicesInitializer{
  static Future<void> initializeServices() async {
    await mainServiceLocator<DotEnvService>().initialize();
  }
}