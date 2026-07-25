import 'package:get_it/get_it.dart';
import '../data/repository/auth_repository_impl.dart';
import '../domain/repository/auth_repository.dart';
import '../presentation/bloc/auth_bloc.dart';


void initAuthDI(GetIt sl) {
  sl.registerFactory<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerFactory(() => AuthBloc(authRepository: sl<AuthRepository>()));
}
