import 'package:get_it/get_it.dart';
import '../data/repository/dispatch_admin_repository_impl.dart';
import '../domain/repository/dispatch_admin_repository.dart';
import '../presentation/bloc/dispatch_config_bloc.dart';
import '../presentation/bloc/dispatch_history_cubit.dart';

void initDispatchAdminDI(GetIt sl) {
  sl.registerLazySingleton<DispatchAdminRepository>(
    () => DispatchAdminRepositoryImpl(),
  );
  sl.registerFactory(
    () => DispatchConfigBloc(repository: sl<DispatchAdminRepository>()),
  );
  sl.registerFactory(
    () => DispatchHistoryCubit(repository: sl<DispatchAdminRepository>()),
  );
}
