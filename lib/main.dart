import 'dart:async';
import 'package:driver_app/core/l10n/app_language.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import 'package:driver_app/shared/connectivity/presentation/component/connectivity_banner.dart';
import 'package:driver_app/shared/connectivity/presentation/cubit/connectivity_cubit.dart';
import 'package:driver_app/shared/feature/session/presentation/bloc/session/session_bloc.dart';
import 'package:driver_app/shared/feature/settings/presentation/bloc/settings_bloc.dart';
import 'package:driver_app/shared/notifications/service/push_notifications_service.dart';
import 'package:driver_app/shared/services/services_initializer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'core/routing/app_routing.dart';
import 'core/service_locator/main_service_locator.dart';
import 'core/theme/app_theme.dart';

// Debe ser una función top-level (o estática): FCM la ejecuta en un isolate
// separado cuando llega un mensaje con la app en background, así que no
// tiene acceso al estado ya inicializado en main().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  // Checkpoints temporales para diagnosticar cuelgues de arranque cuando la
  // app se reabre con el foreground service ya corriendo (pantalla negra
  // sin crash ni log -- ver BatteryOptimizationService/DriverForegroundService).
  // Si vuelve a colgarse, el último "BootstrapDebug" impreso indica
  // exactamente en qué paso se quedó, en vez de tener que adivinar.
  debugPrint('BootstrapDebug | main() arrancando');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('BootstrapDebug | WidgetsFlutterBinding.ensureInitialized() listo');
  await Firebase.initializeApp();
  debugPrint('BootstrapDebug | Firebase.initializeApp() completado');
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  initMainServiceLocator();
  debugPrint('BootstrapDebug | initMainServiceLocator() completado');
  await ServicesInitializer.initializeServices();
  debugPrint('BootstrapDebug | ServicesInitializer.initializeServices() completado');
  unawaited(GetIt.instance<PushNotificationsService>().initialize());
  runApp(const MyApp());
  debugPrint('BootstrapDebug | runApp() llamado');
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
        // Singleton de GetIt: vive durante toda la sesión, no solo mientras
        // este widget está montado (igual que SessionBloc/SettingsBloc de
        // arriba) -- así el banner de conectividad puede mostrarse desde el
        // primer frame (splash) hasta el último.
        BlocProvider<ConnectivityCubit>(
          create: (context) => GetIt.instance<ConnectivityCubit>(),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            // onGenerateTitle en vez de `title`: se evalúa con un context que
            // ya tiene las localizaciones, así el nombre que muestra el
            // sistema operativo también sale del .arb.
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // null cuando el usuario eligio "Sistema": ahi resuelve
            // localeListResolutionCallback con los idiomas del dispositivo.
            locale: settingsState.language.locale,
            // El fallback de Flutter cuando nada matchea es el PRIMER elemento
            // de supportedLocales, que el generador ordena alfabeticamente
            // ([en, es]). Sin esto, un telefono en portugues abriria la app en
            // ingles en vez de espaniol -- ver resolveAppLocale.
            localeListResolutionCallback:
                (deviceLocales, _) => resolveAppLocale(
                  preference: settingsState.language,
                  deviceLocales: deviceLocales?.toList(),
                ),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsState.themeMode,
            routerConfig: AppRouter.router,
            // Envuelve TODO lo que arma go_router (incluidas splash/login,
            // fuera del StatefulShellRoute) para que el banner de "sin
            // conexión" pueda mostrarse sin importar la pantalla -- ver
            // ConnectivityBannerOverlay.
            builder: (context, child) {
              return ConnectivityBannerOverlay(
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
