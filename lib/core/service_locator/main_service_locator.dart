import 'package:driver_app/feature/auth/di/auth_service_locator.dart';
import 'package:driver_app/shared/feature/session/di/session_service_locator.dart';
import 'package:get_it/get_it.dart';
import '../../shared/services/dotenv/dotenv_service_locator.dart';


final GetIt mainServiceLocator = GetIt.instance;

Future<void> initMainServiceLocator() async {
  initDotEnvDI(mainServiceLocator);
  initSessionDI(mainServiceLocator);
  initAuthDI(mainServiceLocator);
}
