import 'package:driver_app/feature/admin/di/admin_service_locator.dart';
import 'package:driver_app/feature/auth/di/auth_service_locator.dart';
import 'package:driver_app/feature/driver_profile/di/driver_profile_service_locator.dart';
import 'package:driver_app/feature/profile/di/profile_service_locator.dart';
import 'package:driver_app/shared/feature/session/di/session_service_locator.dart';
import 'package:driver_app/shared/feature/settings/di/settings_service_locator.dart';
import 'package:driver_app/shared/feedback/di/feedback_service_locator.dart';
import 'package:driver_app/shared/foreground_location/di/foreground_location_service_locator.dart';
import 'package:driver_app/shared/geolocator/di/geolocator_service_locator.dart';
import 'package:driver_app/shared/image_picker/di/image_picker_service_locator.dart';
import 'package:driver_app/shared/notifications/di/push_notifications_service_locator.dart';
import 'package:driver_app/shared/vibration/di/vibration_service_locator.dart';
import 'package:driver_app/shared/voice/di/voice_service_locator.dart';
import 'package:get_it/get_it.dart';
import '../../feature/incoming_request/di/incoming_request_service_locator.dart';
import '../../feature/trip/di/trip_service_locator.dart';
import '../../shared/services/dotenv/dotenv_service_locator.dart';


final GetIt mainServiceLocator = GetIt.instance;

Future<void> initMainServiceLocator() async {
  initDotEnvDI(mainServiceLocator);
  initPushNotificationsDI(mainServiceLocator);
  initImagePickerDI(mainServiceLocator);
  initDriverProfileDI(mainServiceLocator);
  initProfileDI(mainServiceLocator);
  initSessionDI(mainServiceLocator);
  initAuthDI(mainServiceLocator);
  initGeolocator(mainServiceLocator);
  initForegroundLocationDI(mainServiceLocator);
  initIncomingRequestDI(mainServiceLocator);
  initTripDI(mainServiceLocator);
  initSettingsDI(mainServiceLocator);
  initVoiceDI(mainServiceLocator);
  initVibrationDI(mainServiceLocator);
  initFeedbackDI(mainServiceLocator);
  initAdminDI(mainServiceLocator);
}
