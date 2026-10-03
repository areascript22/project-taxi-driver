import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// Nombre de la app que ve el sistema operativo (ej. el selector de apps de Android)
  ///
  /// In es, this message translates to:
  /// **'Taxi project - Driver'**
  String get appTitle;

  /// Botón para descartar una acción, compartido por varios diálogos
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// Título del AppBar de la pantalla de ajustes
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// Encabezado de sección. Va en mayúsculas a propósito (estilo visual de la pantalla), no es un grito
  ///
  /// In es, this message translates to:
  /// **'APARIENCIA'**
  String get settingsSectionAppearance;

  /// Opción de tema oscuro
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// Opción de tema claro
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// Opción de tema que sigue al sistema operativo
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// Encabezado de sección, en mayúsculas por estilo visual
  ///
  /// In es, this message translates to:
  /// **'NOTIFICACIONES'**
  String get settingsSectionNotifications;

  /// Switch que activa los anuncios hablados (TTS)
  ///
  /// In es, this message translates to:
  /// **'Voz'**
  String get settingsVoiceTitle;

  /// Descripción del switch de voz
  ///
  /// In es, this message translates to:
  /// **'Anuncios hablados de la app'**
  String get settingsVoiceSubtitle;

  /// Switch que activa la vibración
  ///
  /// In es, this message translates to:
  /// **'Vibración'**
  String get settingsVibrationTitle;

  /// Descripción del switch de vibración
  ///
  /// In es, this message translates to:
  /// **'Vibrar en eventos importantes'**
  String get settingsVibrationSubtitle;

  /// Encabezado de sección, en mayúsculas por estilo visual
  ///
  /// In es, this message translates to:
  /// **'CUENTA'**
  String get settingsSectionAccount;

  /// Usado en el tile de ajustes, en el título del diálogo de confirmación y en su botón de confirmar
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccountTitle;

  /// Subtítulo del tile de eliminar cuenta en ajustes
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer'**
  String get deleteAccountSubtitle;

  /// Cuerpo del diálogo de confirmación. Menciona el vehículo porque en driver_app el borrado también elimina el vehículo registrado
  ///
  /// In es, this message translates to:
  /// **'Esta acción es irreversible. Se eliminarán tu perfil, tu foto, tu vehículo registrado y tus chats. No podrás recuperar esta información.\n\n¿Seguro que deseas eliminar tu cuenta?'**
  String get deleteAccountDialogBody;

  /// Toast de éxito tras eliminar la cuenta, justo antes del logout
  ///
  /// In es, this message translates to:
  /// **'Cuenta eliminada correctamente'**
  String get deleteAccountSuccess;

  /// Botón para reintentar una operación que falló
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// Acción de cerrar sesión: título del diálogo de confirmación, su botón, y el botón del perfil
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get commonSignOut;

  /// Etiqueta del campo de correo
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get commonEmail;

  /// Etiqueta del campo de teléfono
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get commonPhone;

  /// Valor mostrado cuando un dato opcional está vacío
  ///
  /// In es, this message translates to:
  /// **'No registrado'**
  String get commonNotProvided;

  /// Pestaña del bottom nav con las peticiones de carrera
  ///
  /// In es, this message translates to:
  /// **'Carreras'**
  String get navRides;

  /// Pestaña del bottom nav de administración (solo visible para admin/superuser)
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// Pestaña del bottom nav del perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// Versión de la app mostrada al pie de algunas pantallas
  ///
  /// In es, this message translates to:
  /// **'Versión: {version}'**
  String appVersionLabel(String version);

  /// Texto mientras se consulta la versión al plugin
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get appVersionLoading;

  /// El plugin no devolvió ninguna versión
  ///
  /// In es, this message translates to:
  /// **'Versión no disponible'**
  String get appVersionUnavailable;

  /// Falló la consulta de la versión (PlatformException)
  ///
  /// In es, this message translates to:
  /// **'Error al obtener la versión'**
  String get appVersionError;

  /// Subtítulo bajo el nombre de la marca en splash y login. 'TaxiGo' NO se traduce (es nombre propio), esto sí
  ///
  /// In es, this message translates to:
  /// **'Conductor'**
  String get brandRoleLabel;

  /// Frase bajo el logo en la pantalla de login
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para comenzar a conducir'**
  String get signInTagline;

  /// Botón de login con Google
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get signInGoogle;

  /// Versión al pie del splash. OJO: el número está hardcodeado y quedó desfasado del pubspec (1.0.6+18); se migra tal cual para no cambiar comportamiento
  ///
  /// In es, this message translates to:
  /// **'Versión 1.0.0'**
  String get splashVersionLabel;

  /// Cuerpo del diálogo de confirmación de cierre de sesión
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión?'**
  String get logoutDialogBody;

  /// Mensaje cuando el perfil carga pero no hay datos del conductor
  ///
  /// In es, this message translates to:
  /// **'No se encontró información del conductor'**
  String get profileDriverNotFound;

  /// Nombre mostrado cuando el conductor no tiene nombre cargado
  ///
  /// In es, this message translates to:
  /// **'Conductor'**
  String get profileFallbackName;

  /// Etiqueta del campo de rol en el perfil
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get profileRoleLabel;

  /// Título de la tarjeta de vehículo cuando el conductor no tiene uno registrado
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get profileVehicleFallback;

  /// Nombre del rol superuser para mostrar (el valor 'superuser' del backend no se traduce)
  ///
  /// In es, this message translates to:
  /// **'Superusuario'**
  String get roleSuperuser;

  /// Nombre del rol admin para mostrar
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get roleAdmin;

  /// Nombre del rol driver para mostrar
  ///
  /// In es, this message translates to:
  /// **'Conductor'**
  String get roleDriver;

  /// Boton para descartar un dialogo sin hacer la accion
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get commonNotNow;

  /// Boton que confirma activar un permiso o ajuste
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get commonActivate;

  /// Boton que solo cierra un dialogo informativo
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get commonUnderstood;

  /// Etiqueta del punto donde se recoge al pasajero
  ///
  /// In es, this message translates to:
  /// **'Punto de recogida'**
  String get commonPickupPoint;

  /// Titulo del banner cuando falta el permiso de optimizacion de bateria
  ///
  /// In es, this message translates to:
  /// **'No puedes recibir carreras todavía'**
  String get batteryBannerTitle;

  /// Cuerpo del banner de optimizacion de bateria
  ///
  /// In es, this message translates to:
  /// **'Necesitas excluir a TaxiGo Conductor de la optimización de batería para que tu ubicación no se pierda durante un viaje.'**
  String get batteryBannerBody;

  /// Boton que abre los ajustes del sistema para excluir la app de la optimizacion de bateria
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get batteryOpenSettings;

  /// Titulo del dialogo que pide excluir la app de la optimizacion de bateria
  ///
  /// In es, this message translates to:
  /// **'Necesitamos un permiso más'**
  String get batteryDialogTitle;

  /// Cuerpo del dialogo de optimizacion de bateria
  ///
  /// In es, this message translates to:
  /// **'Para no perder tu ubicación durante un viaje -- incluso si la app se cierra por accidente -- necesitamos que excluyas a TaxiGo Conductor de la optimización de batería del sistema.'**
  String get batteryDialogBody;

  /// Titulo de la pantalla que se muestra sin permiso de ubicacion
  ///
  /// In es, this message translates to:
  /// **'Necesitamos tu ubicación'**
  String get locationDeniedTitle;

  /// Cuerpo cuando el permiso esta denegado permanentemente (hay que ir a ajustes)
  ///
  /// In es, this message translates to:
  /// **'El acceso a tu ubicación está bloqueado. Actívalo desde la configuración del dispositivo para poder ver y aceptar carreras.'**
  String get locationDeniedBlockedBody;

  /// Cuerpo cuando el permiso todavia se puede pedir desde la app
  ///
  /// In es, this message translates to:
  /// **'Para ver y aceptar las carreras de los pasajeros necesitamos acceso a tu ubicación.'**
  String get locationDeniedBody;

  /// Boton que lleva a la configuracion del dispositivo cuando el permiso esta bloqueado
  ///
  /// In es, this message translates to:
  /// **'Abrir configuración'**
  String get locationOpenSettings;

  /// Boton que dispara el pedido de permiso de ubicacion
  ///
  /// In es, this message translates to:
  /// **'Dar permiso de ubicación'**
  String get locationGrantPermission;

  /// Toast de error al intentar aceptar una carrera sin permiso de ubicacion
  ///
  /// In es, this message translates to:
  /// **'Se necesita acceso a tu ubicación para aceptar carreras.'**
  String get locationRequiredToAccept;

  /// Titulo del aviso cuando el conductor no esta recibiendo carreras
  ///
  /// In es, this message translates to:
  /// **'Estás offline'**
  String get offlineTitle;

  /// Cuerpo del aviso de offline
  ///
  /// In es, this message translates to:
  /// **'Activa el switch en la parte superior para empezar a recibir peticiones de carrera.'**
  String get offlineBody;

  /// Boton que pone al conductor online
  ///
  /// In es, this message translates to:
  /// **'Conectarme'**
  String get offlineConnect;

  /// Titulo de la pantalla de peticiones de carrera
  ///
  /// In es, this message translates to:
  /// **'Peticiones Entrantes'**
  String get requestsTitle;

  /// Mensaje cuando no hay ninguna peticion. El salto de linea es intencional (centrado en dos lineas)
  ///
  /// In es, this message translates to:
  /// **'No hay clientes buscando\ntaxi en este momento.'**
  String get requestsEmpty;

  /// Cuenta atras en cada peticion: segundos que lleva esperando antes de que el backend la cancele
  ///
  /// In es, this message translates to:
  /// **'Esperando conductor · {seconds}s'**
  String requestWaitingSeconds(int seconds);

  /// Boton que acepta una peticion de carrera
  ///
  /// In es, this message translates to:
  /// **'Aceptar carrera'**
  String get requestAccept;

  /// Toast de error cuando falla aceptar la carrera y el backend no dio un motivo
  ///
  /// In es, this message translates to:
  /// **'No se pudo aceptar la carrera.'**
  String get requestAcceptFailed;

  /// Saludo hablado (TTS) al entrar a la pantalla de peticiones
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a TaxiGo conductor'**
  String get welcomeAnnouncement;

  /// Titulo del AppBar del chat, y etiqueta del boton de chat en el viaje
  ///
  /// In es, this message translates to:
  /// **'Chat con el pasajero'**
  String get chatTitle;

  /// Mensaje cuando la conversacion esta vacia
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay mensajes'**
  String get chatEmpty;

  /// Placeholder del campo de texto del chat
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get chatInputHint;

  /// Titulo de la pantalla del viaje activo
  ///
  /// In es, this message translates to:
  /// **'Viaje en curso'**
  String get tripInProgressTitle;

  /// Boton para cancelar la carrera ya aceptada
  ///
  /// In es, this message translates to:
  /// **'Cancelar carrera'**
  String get tripCancel;

  /// Etiqueta de la tarjeta con los datos del pasajero
  ///
  /// In es, this message translates to:
  /// **'Pasajero'**
  String get tripPassengerLabel;

  /// Boton que abre Google Maps en el punto de recogida
  ///
  /// In es, this message translates to:
  /// **'Abrir en Google Maps'**
  String get tripOpenInMaps;

  /// Subtitulo del boton de Google Maps
  ///
  /// In es, this message translates to:
  /// **'Navega hasta el punto de recogida'**
  String get tripNavigateToPickup;

  /// Toast de error si map_launcher no encuentra Google Maps en el dispositivo
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir Google Maps. ¿Está instalado?'**
  String get tripOpenMapsFailed;

  /// Aviso (hablado y toast) de que el pasajero salio hacia el auto
  ///
  /// In es, this message translates to:
  /// **'El pasajero está en camino al auto'**
  String get tripPassengerOnTheWay;

  /// Aviso hablado (TTS) de que el pasajero cancelo
  ///
  /// In es, this message translates to:
  /// **'El pasajero canceló la carrera'**
  String get tripPassengerCancelledAnnouncement;

  /// Titulo del dialogo de confirmacion para cancelar una carrera aceptada
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar carrera?'**
  String get cancelTripDialogTitle;

  /// Cuerpo del dialogo de confirmacion de cancelacion
  ///
  /// In es, this message translates to:
  /// **'Ya aceptaste esta carrera y el pasajero te está esperando. Si cancelas ahora podría afectar tu reputación como conductor.'**
  String get cancelTripDialogBody;

  /// Boton que descarta la cancelacion y sigue con la carrera
  ///
  /// In es, this message translates to:
  /// **'Continuar carrera'**
  String get cancelTripContinue;

  /// Titulo del dialogo que avisa que el pasajero cancelo
  ///
  /// In es, this message translates to:
  /// **'Carrera cancelada'**
  String get passengerCancelledTitle;

  /// Cuerpo del dialogo de carrera cancelada por el pasajero
  ///
  /// In es, this message translates to:
  /// **'El pasajero canceló esta carrera. Ya puedes volver a la lista de peticiones entrantes.'**
  String get passengerCancelledBody;

  /// Estado del boton 'He llegado' mientras el backend confirma
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get tripArrivedSending;

  /// Boton con el que el conductor avisa que llego al punto de recogida
  ///
  /// In es, this message translates to:
  /// **'He llegado'**
  String get tripArrived;

  /// Estado del boton 'Finalizar viaje' mientras el backend confirma
  ///
  /// In es, this message translates to:
  /// **'Finalizando...'**
  String get tripFinishing;

  /// Boton que marca el viaje como completado
  ///
  /// In es, this message translates to:
  /// **'Finalizar viaje'**
  String get tripFinish;

  /// Boton para avanzar al paso siguiente de un formulario
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get commonNext;

  /// Boton para volver al paso anterior de un formulario
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get commonBack;

  /// Error de validacion corto para campos obligatorios
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get commonRequired;

  /// Valor mostrado cuando un dato no existe
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get commonNoData;

  /// Mostrado cuando un conductor no tiene nombre cargado
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get commonNoName;

  /// Etiqueta del motivo de un bloqueo o rechazo
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get commonReason;

  /// Motivo mostrado en linea junto a su valor
  ///
  /// In es, this message translates to:
  /// **'Motivo: {reason}'**
  String commonReasonWithValue(String reason);

  /// Boton que vuelve a consultar el estado de la cuenta
  ///
  /// In es, this message translates to:
  /// **'Verificar de nuevo'**
  String get commonVerifyAgain;

  /// Tooltip del menu de acciones de una fila
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get commonMoreOptions;

  /// Mensaje cuando falla el chequeo de sesion (no sabemos si el conductor existe)
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar tu sesión. Revisa tu conexión e intenta de nuevo.'**
  String get sessionCheckFailed;

  /// Titulo de la pantalla de cuenta bloqueada por un admin
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está bloqueada'**
  String get sessionBlockedTitle;

  /// Cuerpo de la pantalla de cuenta bloqueada
  ///
  /// In es, this message translates to:
  /// **'Un administrador bloqueó temporalmente tu cuenta y no puedes recibir carreras mientras tanto.'**
  String get sessionBlockedBody;

  /// Titulo cuando approvalStatus es 'rejected'
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud fue rechazada'**
  String get sessionRejectedTitle;

  /// Titulo cuando approvalStatus es 'pending'
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está en revisión'**
  String get sessionPendingTitle;

  /// Cuerpo cuando la solicitud fue rechazada
  ///
  /// In es, this message translates to:
  /// **'Un administrador revisó tu registro y no fue aprobado.'**
  String get sessionRejectedBody;

  /// Cuerpo cuando la solicitud esta pendiente de aprobacion
  ///
  /// In es, this message translates to:
  /// **'Un administrador está revisando tu registro. Te avisaremos apenas puedas empezar a recibir carreras.'**
  String get sessionPendingBody;

  /// Encabezado con el progreso del registro
  ///
  /// In es, this message translates to:
  /// **'Paso {step} de {totalSteps}'**
  String onboardingStepOf(int step, int totalSteps);

  /// Titulo del paso de datos personales del registro
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get onboardingPersonalTitle;

  /// Subtitulo del paso de datos personales
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos quién eres para poder verificarte.'**
  String get onboardingPersonalSubtitle;

  /// Etiqueta del campo de nombres
  ///
  /// In es, this message translates to:
  /// **'Nombres'**
  String get fieldFirstName;

  /// Etiqueta del campo de apellidos
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get fieldLastName;

  /// Etiqueta del campo de celular
  ///
  /// In es, this message translates to:
  /// **'Número de celular'**
  String get fieldMobile;

  /// Error de validacion del campo de nombres
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus nombres'**
  String get validationFirstName;

  /// Error de validacion del campo de apellidos
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus apellidos'**
  String get validationLastName;

  /// Error de validacion cuando el celular esta vacio
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu número de celular'**
  String get validationMobileRequired;

  /// Error de validacion cuando el celular no cumple el formato de Ecuador (9 + 8 digitos)
  ///
  /// In es, this message translates to:
  /// **'Número de celular ecuatoriano inválido'**
  String get validationMobileInvalid;

  /// Enlace para cerrar sesion desde el registro, si la cuenta de Google no es la correcta
  ///
  /// In es, this message translates to:
  /// **'¿No eres tú? Cerrar sesión'**
  String get onboardingSignOutPrompt;

  /// Titulo del paso de datos del vehiculo
  ///
  /// In es, this message translates to:
  /// **'Tu vehículo'**
  String get onboardingVehicleTitle;

  /// Subtitulo del paso de datos del vehiculo
  ///
  /// In es, this message translates to:
  /// **'Estos datos serán revisados por nuestro equipo.'**
  String get onboardingVehicleSubtitle;

  /// Etiqueta del campo de placa
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get vehiclePlate;

  /// Etiqueta del campo de marca del vehiculo
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get vehicleBrand;

  /// Etiqueta del campo de modelo del vehiculo
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get vehicleModel;

  /// Etiqueta del campo de anio del vehiculo
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get vehicleYear;

  /// Etiqueta del campo de color del vehiculo
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get vehicleColor;

  /// Ejemplo en el campo de color. Se traduce porque es una palabra; en cambio 'Toyota'/'Corolla' y las mascaras de placa quedan hardcodeadas (nombres propios y formatos)
  ///
  /// In es, this message translates to:
  /// **'Blanco'**
  String get vehicleColorHint;

  /// Etiqueta del campo de numero de matricula
  ///
  /// In es, this message translates to:
  /// **'Número de matrícula'**
  String get vehicleRegistrationNumber;

  /// Error de validacion del campo de placa
  ///
  /// In es, this message translates to:
  /// **'Ingresa la placa'**
  String get validationPlate;

  /// Error de validacion cuando el anio esta fuera de rango
  ///
  /// In es, this message translates to:
  /// **'Año inválido'**
  String get validationYearInvalid;

  /// Error de validacion del campo de matricula
  ///
  /// In es, this message translates to:
  /// **'Ingresa el número de matrícula'**
  String get validationRegistrationNumber;

  /// Estado del boton de registro mientras se guarda
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get onboardingSaving;

  /// Boton que completa el registro del conductor
  ///
  /// In es, this message translates to:
  /// **'Registrarme'**
  String get onboardingSubmit;

  /// Titulo del bottom sheet para elegir el origen de la foto
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil'**
  String get photoSheetTitle;

  /// Opcion de usar la camara
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get photoTakePhoto;

  /// Opcion de elegir una foto existente
  ///
  /// In es, this message translates to:
  /// **'Elegir de galería'**
  String get photoFromGallery;

  /// Titulo de la pantalla con el vehiculo del propio conductor
  ///
  /// In es, this message translates to:
  /// **'Mi vehículo'**
  String get myVehicleTitle;

  /// Estado del vehiculo cuando verificationStatus es 'approved'
  ///
  /// In es, this message translates to:
  /// **'Vehículo aprobado'**
  String get vehicleStatusApproved;

  /// Estado del vehiculo cuando verificationStatus es 'rejected'
  ///
  /// In es, this message translates to:
  /// **'Vehículo rechazado'**
  String get vehicleStatusRejected;

  /// Estado del vehiculo o del registro cuando todavia no se reviso
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get vehicleStatusInReview;

  /// Titulo de la pantalla de administracion
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get adminTitle;

  /// Placeholder del buscador de conductores
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, correo o teléfono'**
  String get adminSearchHint;

  /// Pill de filtro: sin filtrar por estado
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get adminFilterAll;

  /// Pill de filtro: solicitudes pendientes
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get adminFilterPending;

  /// Pill de filtro: solicitudes rechazadas
  ///
  /// In es, this message translates to:
  /// **'Rechazados'**
  String get adminFilterRejected;

  /// Pill de filtro: conductores activos
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get adminFilterActive;

  /// Pill de filtro: conductores bloqueados
  ///
  /// In es, this message translates to:
  /// **'Bloqueados'**
  String get adminFilterBlocked;

  /// Lista vacia porque la busqueda o el filtro no devolvieron nada
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get adminNoResults;

  /// Lista vacia porque todavia no hay ningun conductor
  ///
  /// In es, this message translates to:
  /// **'No hay conductores registrados'**
  String get adminNoDrivers;

  /// Accion del menu que abre el detalle del conductor
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get adminReview;

  /// Accion del menu y titulo del dialogo para cambiar el rol
  ///
  /// In es, this message translates to:
  /// **'Cambiar rol'**
  String get adminChangeRole;

  /// Indicador de paginacion cuando se conoce el total
  ///
  /// In es, this message translates to:
  /// **'Página {page} de {totalPages}'**
  String adminPageOf(int page, int totalPages);

  /// Indicador de paginacion cuando no se conoce el total
  ///
  /// In es, this message translates to:
  /// **'Página {page}'**
  String adminPage(int page);

  /// Chip de estado: cuenta bloqueada
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get adminStatusBlocked;

  /// Chip de estado: solicitud aprobada
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get adminStatusApproved;

  /// Chip de estado: solicitud rechazada
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get adminStatusRejected;

  /// Chip de estado: solicitud pendiente
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get adminStatusPending;

  /// Titulo de la pantalla de detalle de un conductor
  ///
  /// In es, this message translates to:
  /// **'Detalle del conductor'**
  String get adminDriverDetailTitle;

  /// Tooltip y titulo del dialogo para eliminar un conductor
  ///
  /// In es, this message translates to:
  /// **'Eliminar conductor'**
  String get adminDeleteDriver;

  /// Cuerpo del dialogo de confirmacion para eliminar un conductor
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que deseas eliminar a {driverName}? Esta acción no se puede deshacer.'**
  String adminDeleteDriverBody(String driverName);

  /// Aviso cuando el rol del admin no alcanza para moderar a este conductor
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos para gestionar el estado de esta cuenta.'**
  String get adminNoModeratePermission;

  /// Boton que desbloquea a un conductor
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get adminUnblock;

  /// Titulo del dialogo de confirmacion para desbloquear
  ///
  /// In es, this message translates to:
  /// **'Desbloquear conductor'**
  String get adminUnblockDriver;

  /// Cuerpo del dialogo de confirmacion para desbloquear
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que deseas desbloquear a {driverName}? Podrá volver a recibir carreras de inmediato.'**
  String adminUnblockDriverBody(String driverName);

  /// Boton que bloquea a un conductor
  ///
  /// In es, this message translates to:
  /// **'Bloquear'**
  String get adminBlock;

  /// Titulo del dialogo que pide el motivo del bloqueo
  ///
  /// In es, this message translates to:
  /// **'Bloquear conductor'**
  String get adminBlockDriver;

  /// Ayuda del dialogo de motivo de bloqueo
  ///
  /// In es, this message translates to:
  /// **'Este motivo se le mostrará directamente al conductor en la app.'**
  String get adminBlockReasonHelp;

  /// Boton que rechaza la solicitud de un conductor
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get adminReject;

  /// Titulo del dialogo que pide el motivo del rechazo
  ///
  /// In es, this message translates to:
  /// **'Rechazar conductor'**
  String get adminRejectDriver;

  /// Ayuda del dialogo de motivo de rechazo
  ///
  /// In es, this message translates to:
  /// **'Cuéntale al conductor qué debe corregir para volver a postularse.'**
  String get adminRejectReasonHelp;

  /// Boton que aprueba la solicitud de un conductor
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get adminApprove;

  /// Placeholder del campo de motivo
  ///
  /// In es, this message translates to:
  /// **'Escribe el motivo...'**
  String get adminReasonHint;

  /// Error cuando se intenta confirmar sin escribir un motivo
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get adminReasonRequired;

  /// Boton de confirmacion del dialogo de eliminar conductor
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get adminDelete;

  /// Etiqueta corta de correo en el detalle del conductor (la pantalla de perfil usa la version larga)
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get adminEmailLabel;

  /// Etiqueta de la calificacion del conductor
  ///
  /// In es, this message translates to:
  /// **'Calificación'**
  String get adminRating;

  /// Etiqueta del token de FCM en el detalle (dato tecnico, solo visible para admins)
  ///
  /// In es, this message translates to:
  /// **'Token de notificaciones'**
  String get adminFcmToken;

  /// Etiqueta de la fecha de registro
  ///
  /// In es, this message translates to:
  /// **'Registrado el'**
  String get adminRegisteredAt;

  /// Etiqueta de la fecha de ultima actualizacion
  ///
  /// In es, this message translates to:
  /// **'Última actualización'**
  String get adminUpdatedAt;

  /// Encabezado de la seccion del vehiculo en el detalle
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get adminVehicleSection;

  /// Mensaje cuando el conductor no tiene vehiculo
  ///
  /// In es, this message translates to:
  /// **'Este conductor no tiene un vehículo registrado'**
  String get adminNoVehicle;

  /// Banner de estado en el detalle: cuenta bloqueada
  ///
  /// In es, this message translates to:
  /// **'Cuenta bloqueada'**
  String get adminAccountBlocked;

  /// Banner de estado en el detalle: conductor aprobado
  ///
  /// In es, this message translates to:
  /// **'Conductor activo'**
  String get adminDriverActive;

  /// Banner de estado en el detalle: solicitud rechazada
  ///
  /// In es, this message translates to:
  /// **'Solicitud rechazada'**
  String get adminApplicationRejected;

  /// Banner de estado en el detalle: solicitud pendiente
  ///
  /// In es, this message translates to:
  /// **'Pendiente de aprobación'**
  String get adminPendingApproval;

  /// Descripcion del banner de pendiente de aprobacion
  ///
  /// In es, this message translates to:
  /// **'Este conductor todavía no puede recibir carreras.'**
  String get adminPendingApprovalBody;

  /// Mensaje de error para FailureCode.noPermission
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos para esta acción'**
  String get failureNoPermission;

  /// Mensaje de error para FailureCode.driverNotFound
  ///
  /// In es, this message translates to:
  /// **'El conductor ya no existe'**
  String get failureDriverNotFound;

  /// Mensaje de error para FailureCode.driversFetchFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la lista de conductores'**
  String get failureDriversFetchFailed;

  /// Mensaje de error para FailureCode.driverUpdateFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar la información del conductor'**
  String get failureDriverUpdateFailed;

  /// Mensaje de error para FailureCode.driverDeleteFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar al conductor'**
  String get failureDriverDeleteFailed;

  /// Mensaje de error para FailureCode.blockReasonMissing
  ///
  /// In es, this message translates to:
  /// **'Falta el motivo del bloqueo'**
  String get failureBlockReasonMissing;

  /// Mensaje de error para FailureCode.rejectReasonMissing
  ///
  /// In es, this message translates to:
  /// **'Falta el motivo para rechazar al conductor'**
  String get failureRejectReasonMissing;

  /// Mensaje de error para FailureCode.driverNotApproved
  ///
  /// In es, this message translates to:
  /// **'No se puede bloquear a un conductor que no está aprobado'**
  String get failureDriverNotApproved;

  /// Mensaje de error para FailureCode.gpsDisabled
  ///
  /// In es, this message translates to:
  /// **'El servicio de GPS del dispositivo está desactivado.'**
  String get failureGpsDisabled;

  /// Mensaje de error para FailureCode.locationUpdateFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar la ubicación del conductor.'**
  String get failureLocationUpdateFailed;

  /// Mensaje de error para FailureCode.rideTaken
  ///
  /// In es, this message translates to:
  /// **'La carrera ya fue tomada por otro conductor o ya no está disponible.'**
  String get failureRideTaken;

  /// Mensaje de error para FailureCode.rideUnavailable
  ///
  /// In es, this message translates to:
  /// **'La solicitud ya no está disponible.'**
  String get failureRideUnavailable;

  /// Mensaje de error para FailureCode.rideAcceptFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo aceptar la carrera.'**
  String get failureRideAcceptFailed;

  /// Mensaje de error para FailureCode.rideCancelNotAllowed
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para cancelar esta carrera.'**
  String get failureRideCancelNotAllowed;

  /// Mensaje de error para FailureCode.rideCancelUnavailable
  ///
  /// In es, this message translates to:
  /// **'La carrera ya no está disponible para cancelar.'**
  String get failureRideCancelUnavailable;

  /// Mensaje de error para FailureCode.rideCancelFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar la carrera. Intenta de nuevo.'**
  String get failureRideCancelFailed;

  /// Mensaje de error para FailureCode.tripFinishNotAllowed
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para finalizar este viaje.'**
  String get failureTripFinishNotAllowed;

  /// Mensaje de error para FailureCode.tripFinishUnavailable
  ///
  /// In es, this message translates to:
  /// **'El viaje ya no está disponible para finalizar.'**
  String get failureTripFinishUnavailable;

  /// Mensaje de error para FailureCode.tripFinishFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo finalizar el viaje. Intenta de nuevo.'**
  String get failureTripFinishFailed;

  /// Mensaje de error para FailureCode.arrivalNotifyFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo notificar tu llegada. Intenta de nuevo.'**
  String get failureArrivalNotifyFailed;

  /// Mensaje de error para FailureCode.activeTripCheckFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar si tienes un viaje en curso.'**
  String get failureActiveTripCheckFailed;

  /// Mensaje de error para FailureCode.chatWriteNotAllowed
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para escribir en esta carrera.'**
  String get failureChatWriteNotAllowed;

  /// Mensaje de error para FailureCode.chatRideFinished
  ///
  /// In es, this message translates to:
  /// **'La carrera ya finalizó, no se pueden enviar más mensajes.'**
  String get failureChatRideFinished;

  /// Mensaje de error para FailureCode.chatSendFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el mensaje. Intenta de nuevo.'**
  String get failureChatSendFailed;

  /// Mensaje de error para FailureCode.accountHasActiveRide
  ///
  /// In es, this message translates to:
  /// **'Tienes un viaje activo. Finalízalo o cancélalo antes de eliminar tu cuenta.'**
  String get failureAccountHasActiveRide;

  /// Mensaje de error para FailureCode.accountDeleteFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar tu cuenta. Intenta nuevamente.'**
  String get failureAccountDeleteFailed;

  /// Mensaje de error para FailureCode.driverProfileCheckFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar tu información de conductor'**
  String get failureDriverProfileCheckFailed;

  /// Mensaje de error para FailureCode.vehicleFetchFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la información del vehículo'**
  String get failureVehicleFetchFailed;

  /// Mensaje de error para FailureCode.profileSaveFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar tu información. Intenta nuevamente.'**
  String get failureProfileSaveFailed;

  /// Mensaje de error para FailureCode.imagePickFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la imagen seleccionada'**
  String get failureImagePickFailed;

  /// Mensaje de error para FailureCode.sessionVerifyFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar tu sesión. Intenta de nuevo.'**
  String get failureSessionVerifyFailed;

  /// Mensaje de error para FailureCode.signInFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión. Intenta de nuevo.'**
  String get failureSignInFailed;

  /// Mensaje de error para FailureCode.signOutFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo cerrar sesión. Intenta de nuevo.'**
  String get failureSignOutFailed;

  /// Mensaje de error para FailureCode.unexpected
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado. Intenta de nuevo.'**
  String get failureUnexpected;

  /// Mensaje de error para FailureCode.chatMessagesLoadFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los mensajes. Intenta de nuevo.'**
  String get failureChatMessagesLoadFailed;

  /// Mensaje de error para FailureCode.profileLoadFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar tu información'**
  String get failureProfileLoadFailed;

  /// Alerta hablada de carrera nueva, emitida desde el isolate del foreground service (ver shared/l10n/isolate_localizations.dart)
  ///
  /// In es, this message translates to:
  /// **'Carrera hacia {address}'**
  String isolateRideTowards(String address);

  /// Alerta hablada cuando la carrera nueva no trae direccion legible
  ///
  /// In es, this message translates to:
  /// **'Nueva carrera'**
  String get isolateNewRide;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
