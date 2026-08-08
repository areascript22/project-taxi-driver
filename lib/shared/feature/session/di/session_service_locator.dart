import 'package:driver_app/feature/trip/domain/repository/trip_repository.dart';
import 'package:driver_app/shared/domain/repository/session_repository.dart';
import 'package:driver_app/shared/feature/session/data/repository/session_repository_impl.dart';
import 'package:driver_app/shared/feature/session/presentation/bloc/session/session_bloc.dart';
import 'package:get_it/get_it.dart';

void initSessionDI(GetIt sl) {
  sl.registerLazySingleton<SessionRepository>(() => SessionRepositoryImpl());
  sl.registerFactory(
    () => SessionBloc(
      sessionRepository: sl<SessionRepository>(),
      // TripRepository se registra en initTripDI, que corre después de
      // initSessionDI -- no es un problema porque SessionBloc es un
      // registerFactory: este closure solo se ejecuta la primera vez que
      // alguien pide SessionBloc (mucho después de que termina el arranque).
      tripRepository: sl<TripRepository>(),
    ),
  );
}
