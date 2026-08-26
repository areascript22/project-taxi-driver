import 'package:get_it/get_it.dart';
import '../data/repository/admin_repository_impl.dart';
import '../domain/repository/admin_repository.dart';
import '../presentation/bloc/admin_bloc.dart';

void initAdminDI(GetIt sl) {
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl());
  sl.registerFactory(
    () => AdminBloc(adminRepository: sl<AdminRepository>()),
  );
}
