import 'package:driver_app/feature/incoming_request/data/repository/incoming_request_repository_impl.dart';
import 'package:driver_app/feature/incoming_request/domain/repository/incoming_request_repository.dart';
import 'package:driver_app/feature/incoming_request/presentation/bloc/incoming_request_bloc.dart';
import 'package:get_it/get_it.dart';

void initIncomingRequestDI(GetIt sl) {
  sl.registerLazySingleton<IncomingRequestRepository>(
    () => IncomingRequestRepositoryImpl(),
  );
  sl.registerFactory(() => IncomingRequestBloc(repository: sl()));
}
