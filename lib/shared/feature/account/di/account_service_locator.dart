import 'package:driver_app/shared/feature/account/data/repository/account_repository_impl.dart';
import 'package:driver_app/shared/feature/account/domain/repository/account_repository.dart';
import 'package:driver_app/shared/feature/account/presentation/cubit/account_cubit.dart';
import 'package:get_it/get_it.dart';

void initAccountDI(GetIt sl) {
  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl());
  // Factory (no singleton): es una acción puntual disparada desde Settings,
  // no estado que deba sobrevivir a la pantalla -- mismo criterio que
  // ProfileBloc.
  sl.registerFactory(
    () => AccountCubit(accountRepository: sl<AccountRepository>()),
  );
}
