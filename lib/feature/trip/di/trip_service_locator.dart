import 'package:get_it/get_it.dart';
import '../data/repository/trip_repository_impl.dart';
import '../domain/repository/trip_repository.dart';
import '../presentation/bloc/trip_bloc.dart';

void initTripDI(GetIt sl) {
  sl.registerLazySingleton<TripRepository>(() => TripRepositoryImpl());
  sl.registerFactory(() => TripBloc(repository: sl<TripRepository>()));
}
