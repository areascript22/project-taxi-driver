import 'package:driver_app/shared/feature/session/presentation/bloc/session/session_bloc.dart';
import 'package:driver_app/shared/feature/settings/presentation/bloc/settings_bloc.dart';
import 'package:driver_app/shared/services/services_initializer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'core/routing/app_routing.dart';
import 'core/service_locator/main_service_locator.dart';
import 'core/theme/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initMainServiceLocator();
  await ServicesInitializer.initializeServices();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>(
          create: (context) => GetIt.instance<SessionBloc>(),
        ),
        BlocProvider<SettingsBloc>(
          create:
              (context) => GetIt.instance<SettingsBloc>()..add(LoadSettings()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'Taxi project - Driver',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsState.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
