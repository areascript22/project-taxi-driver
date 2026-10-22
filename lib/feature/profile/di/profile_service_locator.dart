import 'package:get_it/get_it.dart';
import '../../driver_profile/domain/repository/driver_profile_repository.dart';
import '../presentation/bloc/profile_bloc.dart';

void initProfileDI(GetIt sl) {
  sl.registerFactory(
    () => ProfileBloc(driverProfileRepository: sl<DriverProfileRepository>()),
  );
}
