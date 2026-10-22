import 'package:driver_app/shared/feature/settings/domain/repository/settings_repository.dart';
import 'package:get_it/get_it.dart';
import '../service/voice_service.dart';
import '../service/voice_service_impl.dart';

void initVoiceDI(GetIt sl) {
  sl.registerLazySingleton<VoiceService>(
    () => VoiceServiceImpl(settingsRepository: sl<SettingsRepository>()),
  );
}
