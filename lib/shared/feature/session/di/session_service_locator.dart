import 'package:driver_app/shared/domain/repository/session_repository.dart';
import 'package:driver_app/shared/feature/session/data/repository/session_repository_impl.dart';
import 'package:driver_app/shared/feature/session/presentation/bloc/session/session_bloc.dart';
import 'package:get_it/get_it.dart';

void initSessionDI(GetIt sl) {
  sl.registerLazySingleton<SessionRepository>(() => SessionRepositoryImpl());
  sl.registerFactory(
    () => SessionBloc(sessionRepository: sl<SessionRepository>()),
  );
}
