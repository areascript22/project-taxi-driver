import 'package:get_it/get_it.dart';
import '../../../shared/image_picker/service/profile_image_picker_service.dart';
import '../data/repository/driver_profile_repository_impl.dart';
import '../domain/repository/driver_profile_repository.dart';
import '../presentation/bloc/driver_onboarding_bloc.dart';

void initDriverProfileDI(GetIt sl) {
  sl.registerLazySingleton<DriverProfileRepository>(
    () => DriverProfileRepositoryImpl(),
  );
  sl.registerFactory(
    () => DriverOnboardingBloc(
      driverProfileRepository: sl<DriverProfileRepository>(),
      imagePickerService: sl<ProfileImagePickerService>(),
    ),
  );
}
