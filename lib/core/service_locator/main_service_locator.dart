import 'package:driver_app/feature/auth/di/auth_service_locator.dart';
import 'package:driver_app/shared/feature/session/di/session_service_locator.dart';
import 'package:driver_app/shared/geolocator/di/geolocator_service_locator.dart';
import 'package:get_it/get_it.dart';
import '../../feature/incoming_request/di/incoming_request_service_locator.dart';
import '../../shared/services/dotenv/dotenv_service_locator.dart';


final GetIt mainServiceLocator = GetIt.instance;

Future<void> initMainServiceLocator() async {
  initDotEnvDI(mainServiceLocator);
  initSessionDI(mainServiceLocator);
  initAuthDI(mainServiceLocator);
  initGeolocator(mainServiceLocator);
  initIncomingRequestDI(mainServiceLocator);
}
