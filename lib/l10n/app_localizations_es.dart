// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Taxi project - Driver';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionAppearance => 'APARIENCIA';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsSectionNotifications => 'NOTIFICACIONES';

  @override
  String get settingsVoiceTitle => 'Voz';

  @override
  String get settingsVoiceSubtitle => 'Anuncios hablados de la app';

  @override
  String get settingsVibrationTitle => 'Vibración';

  @override
  String get settingsVibrationSubtitle => 'Vibrar en eventos importantes';

  @override
  String get settingsSectionAccount => 'CUENTA';

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountSubtitle => 'Esta acción no se puede deshacer';

  @override
  String get deleteAccountDialogBody => 'Esta acción es irreversible. Se eliminarán tu perfil, tu foto, tu vehículo registrado y tus chats. No podrás recuperar esta información.\n\n¿Seguro que deseas eliminar tu cuenta?';

  @override
  String get deleteAccountSuccess => 'Cuenta eliminada correctamente';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSignOut => 'Cerrar sesión';

  @override
  String get commonEmail => 'Correo electrónico';

  @override
  String get commonPhone => 'Teléfono';

  @override
  String get commonNotProvided => 'No registrado';

  @override
  String get navRides => 'Carreras';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navProfile => 'Perfil';

  @override
  String appVersionLabel(String version) {
    return 'Versión: $version';
  }

  @override
  String get appVersionLoading => 'Cargando...';

  @override
  String get appVersionUnavailable => 'Versión no disponible';

  @override
  String get appVersionError => 'Error al obtener la versión';

  @override
  String get brandRoleLabel => 'Conductor';

  @override
  String get signInTagline => 'Inicia sesión para comenzar a conducir';

  @override
  String get signInGoogle => 'Continuar con Google';

  @override
  String get splashVersionLabel => 'Versión 1.0.0';

  @override
  String get logoutDialogBody => '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get profileDriverNotFound => 'No se encontró información del conductor';

  @override
  String get profileFallbackName => 'Conductor';

  @override
  String get profileRoleLabel => 'Rol';

  @override
  String get profileVehicleFallback => 'Vehículo';

  @override
  String get roleSuperuser => 'Superusuario';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleDriver => 'Conductor';

  @override
  String get commonNotNow => 'Ahora no';

  @override
  String get commonActivate => 'Activar';

  @override
  String get commonUnderstood => 'Entendido';

  @override
  String get commonPickupPoint => 'Punto de recogida';

  @override
  String get batteryBannerTitle => 'No puedes recibir carreras todavía';

  @override
  String get batteryBannerBody => 'Necesitas excluir a TaxiGo Conductor de la optimización de batería para que tu ubicación no se pierda durante un viaje.';

  @override
  String get batteryOpenSettings => 'Abrir ajustes';

  @override
  String get batteryDialogTitle => 'Necesitamos un permiso más';

  @override
  String get batteryDialogBody => 'Para no perder tu ubicación durante un viaje -- incluso si la app se cierra por accidente -- necesitamos que excluyas a TaxiGo Conductor de la optimización de batería del sistema.';

  @override
  String get locationDeniedTitle => 'Necesitamos tu ubicación';

  @override
  String get locationDeniedBlockedBody => 'El acceso a tu ubicación está bloqueado. Actívalo desde la configuración del dispositivo para poder ver y aceptar carreras.';

  @override
  String get locationDeniedBody => 'Para ver y aceptar las carreras de los pasajeros necesitamos acceso a tu ubicación.';

  @override
  String get locationOpenSettings => 'Abrir configuración';

  @override
  String get locationGrantPermission => 'Dar permiso de ubicación';

  @override
  String get locationRequiredToAccept => 'Se necesita acceso a tu ubicación para aceptar carreras.';

  @override
  String get offlineTitle => 'Estás offline';

  @override
  String get offlineBody => 'Activa el switch en la parte superior para empezar a recibir peticiones de carrera.';

  @override
  String get offlineConnect => 'Conectarme';

  @override
  String get requestsTitle => 'Peticiones Entrantes';

  @override
  String get requestsEmpty => 'No hay clientes buscando\ntaxi en este momento.';

  @override
  String requestWaitingSeconds(int seconds) {
    return 'Esperando conductor · ${seconds}s';
  }

  @override
  String get requestAccept => 'Aceptar carrera';

  @override
  String get requestAcceptFailed => 'No se pudo aceptar la carrera.';

  @override
  String get welcomeAnnouncement => 'Bienvenido a TaxiGo conductor';

  @override
  String get chatTitle => 'Chat con el pasajero';

  @override
  String get chatEmpty => 'Todavía no hay mensajes';

  @override
  String get chatInputHint => 'Escribe un mensaje...';

  @override
  String get tripInProgressTitle => 'Viaje en curso';

  @override
  String get tripCancel => 'Cancelar carrera';

  @override
  String get tripPassengerLabel => 'Pasajero';

  @override
  String get tripOpenInMaps => 'Abrir en Google Maps';

  @override
  String get tripNavigateToPickup => 'Navega hasta el punto de recogida';

  @override
  String get tripOpenMapsFailed => 'No se pudo abrir Google Maps. ¿Está instalado?';

  @override
  String get tripPassengerOnTheWay => 'El pasajero está en camino al auto';

  @override
  String get tripPassengerCancelledAnnouncement => 'El pasajero canceló la carrera';

  @override
  String get cancelTripDialogTitle => '¿Cancelar carrera?';

  @override
  String get cancelTripDialogBody => 'Ya aceptaste esta carrera y el pasajero te está esperando. Si cancelas ahora podría afectar tu reputación como conductor.';

  @override
  String get cancelTripContinue => 'Continuar carrera';

  @override
  String get passengerCancelledTitle => 'Carrera cancelada';

  @override
  String get passengerCancelledBody => 'El pasajero canceló esta carrera. Ya puedes volver a la lista de peticiones entrantes.';

  @override
  String get tripArrivedSending => 'Enviando...';

  @override
  String get tripArrived => 'He llegado';

  @override
  String get tripFinishing => 'Finalizando...';

  @override
  String get tripFinish => 'Finalizar viaje';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonRequired => 'Requerido';

  @override
  String get commonNoData => 'Sin datos';

  @override
  String get commonNoName => 'Sin nombre';

  @override
  String get commonReason => 'Motivo';

  @override
  String commonReasonWithValue(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get commonVerifyAgain => 'Verificar de nuevo';

  @override
  String get commonMoreOptions => 'Más opciones';

  @override
  String get sessionCheckFailed => 'No se pudo verificar tu sesión. Revisa tu conexión e intenta de nuevo.';

  @override
  String get sessionBlockedTitle => 'Tu cuenta está bloqueada';

  @override
  String get sessionBlockedBody => 'Un administrador bloqueó temporalmente tu cuenta y no puedes recibir carreras mientras tanto.';

  @override
  String get sessionRejectedTitle => 'Tu solicitud fue rechazada';

  @override
  String get sessionPendingTitle => 'Tu cuenta está en revisión';

  @override
  String get sessionRejectedBody => 'Un administrador revisó tu registro y no fue aprobado.';

  @override
  String get sessionPendingBody => 'Un administrador está revisando tu registro. Te avisaremos apenas puedas empezar a recibir carreras.';

  @override
  String onboardingStepOf(int step, int totalSteps) {
    return 'Paso $step de $totalSteps';
  }

  @override
  String get onboardingPersonalTitle => 'Tus datos';

  @override
  String get onboardingPersonalSubtitle => 'Cuéntanos quién eres para poder verificarte.';

  @override
  String get fieldFirstName => 'Nombres';

  @override
  String get fieldLastName => 'Apellidos';

  @override
  String get fieldMobile => 'Número de celular';

  @override
  String get validationFirstName => 'Ingresa tus nombres';

  @override
  String get validationLastName => 'Ingresa tus apellidos';

  @override
  String get validationMobileRequired => 'Ingresa tu número de celular';

  @override
  String get validationMobileInvalid => 'Número de celular ecuatoriano inválido';

  @override
  String get onboardingSignOutPrompt => '¿No eres tú? Cerrar sesión';

  @override
  String get onboardingVehicleTitle => 'Tu vehículo';

  @override
  String get onboardingVehicleSubtitle => 'Estos datos serán revisados por nuestro equipo.';

  @override
  String get vehiclePlate => 'Placa';

  @override
  String get vehicleBrand => 'Marca';

  @override
  String get vehicleModel => 'Modelo';

  @override
  String get vehicleYear => 'Año';

  @override
  String get vehicleColor => 'Color';

  @override
  String get vehicleColorHint => 'Blanco';

  @override
  String get vehicleRegistrationNumber => 'Número de matrícula';

  @override
  String get validationPlate => 'Ingresa la placa';

  @override
  String get validationYearInvalid => 'Año inválido';

  @override
  String get validationRegistrationNumber => 'Ingresa el número de matrícula';

  @override
  String get onboardingSaving => 'Guardando...';

  @override
  String get onboardingSubmit => 'Registrarme';

  @override
  String get photoSheetTitle => 'Foto de perfil';

  @override
  String get photoTakePhoto => 'Tomar foto';

  @override
  String get photoFromGallery => 'Elegir de galería';

  @override
  String get myVehicleTitle => 'Mi vehículo';

  @override
  String get vehicleStatusApproved => 'Vehículo aprobado';

  @override
  String get vehicleStatusRejected => 'Vehículo rechazado';

  @override
  String get vehicleStatusInReview => 'En revisión';

  @override
  String get adminTitle => 'Administración';

  @override
  String get adminSearchHint => 'Buscar por nombre, correo o teléfono';

  @override
  String get adminFilterAll => 'Todos';

  @override
  String get adminFilterPending => 'Pendientes';

  @override
  String get adminFilterRejected => 'Rechazados';

  @override
  String get adminFilterActive => 'Activos';

  @override
  String get adminFilterBlocked => 'Bloqueados';

  @override
  String get adminNoResults => 'No se encontraron resultados';

  @override
  String get adminNoDrivers => 'No hay conductores registrados';

  @override
  String get adminReview => 'Revisar';

  @override
  String get adminChangeRole => 'Cambiar rol';

  @override
  String adminPageOf(int page, int totalPages) {
    return 'Página $page de $totalPages';
  }

  @override
  String adminPage(int page) {
    return 'Página $page';
  }

  @override
  String get adminStatusBlocked => 'Bloqueado';

  @override
  String get adminStatusApproved => 'Aprobado';

  @override
  String get adminStatusRejected => 'Rechazado';

  @override
  String get adminStatusPending => 'Pendiente';

  @override
  String get adminDriverDetailTitle => 'Detalle del conductor';

  @override
  String get adminDeleteDriver => 'Eliminar conductor';

  @override
  String adminDeleteDriverBody(String driverName) {
    return '¿Seguro que deseas eliminar a $driverName? Esta acción no se puede deshacer.';
  }

  @override
  String get adminNoModeratePermission => 'No tienes permisos para gestionar el estado de esta cuenta.';

  @override
  String get adminUnblock => 'Desbloquear';

  @override
  String get adminUnblockDriver => 'Desbloquear conductor';

  @override
  String adminUnblockDriverBody(String driverName) {
    return '¿Seguro que deseas desbloquear a $driverName? Podrá volver a recibir carreras de inmediato.';
  }

  @override
  String get adminBlock => 'Bloquear';

  @override
  String get adminBlockDriver => 'Bloquear conductor';

  @override
  String get adminBlockReasonHelp => 'Este motivo se le mostrará directamente al conductor en la app.';

  @override
  String get adminReject => 'Rechazar';

  @override
  String get adminRejectDriver => 'Rechazar conductor';

  @override
  String get adminRejectReasonHelp => 'Cuéntale al conductor qué debe corregir para volver a postularse.';

  @override
  String get adminApprove => 'Aprobar';

  @override
  String get adminReasonHint => 'Escribe el motivo...';

  @override
  String get adminReasonRequired => 'Este campo es obligatorio';

  @override
  String get adminDelete => 'Eliminar';

  @override
  String get adminEmailLabel => 'Correo';

  @override
  String get adminRating => 'Calificación';

  @override
  String get adminFcmToken => 'Token de notificaciones';

  @override
  String get adminRegisteredAt => 'Registrado el';

  @override
  String get adminUpdatedAt => 'Última actualización';

  @override
  String get adminVehicleSection => 'Vehículo';

  @override
  String get adminNoVehicle => 'Este conductor no tiene un vehículo registrado';

  @override
  String get adminAccountBlocked => 'Cuenta bloqueada';

  @override
  String get adminDriverActive => 'Conductor activo';

  @override
  String get adminApplicationRejected => 'Solicitud rechazada';

  @override
  String get adminPendingApproval => 'Pendiente de aprobación';

  @override
  String get adminPendingApprovalBody => 'Este conductor todavía no puede recibir carreras.';

  @override
  String get failureNoPermission => 'No tienes permisos para esta acción';

  @override
  String get failureDriverNotFound => 'El conductor ya no existe';

  @override
  String get failureDriversFetchFailed => 'No se pudo obtener la lista de conductores';

  @override
  String get failureDriverUpdateFailed => 'No se pudo actualizar la información del conductor';

  @override
  String get failureDriverDeleteFailed => 'No se pudo eliminar al conductor';

  @override
  String get failureBlockReasonMissing => 'Falta el motivo del bloqueo';

  @override
  String get failureRejectReasonMissing => 'Falta el motivo para rechazar al conductor';

  @override
  String get failureDriverNotApproved => 'No se puede bloquear a un conductor que no está aprobado';

  @override
  String get failureGpsDisabled => 'El servicio de GPS del dispositivo está desactivado.';

  @override
  String get failureLocationUpdateFailed => 'No se pudo actualizar la ubicación del conductor.';

  @override
  String get failureRideTaken => 'La carrera ya fue tomada por otro conductor o ya no está disponible.';

  @override
  String get failureRideUnavailable => 'La solicitud ya no está disponible.';

  @override
  String get failureRideAcceptFailed => 'No se pudo aceptar la carrera.';

  @override
  String get failureRideCancelNotAllowed => 'No tienes permiso para cancelar esta carrera.';

  @override
  String get failureRideCancelUnavailable => 'La carrera ya no está disponible para cancelar.';

  @override
  String get failureRideCancelFailed => 'No se pudo cancelar la carrera. Intenta de nuevo.';

  @override
  String get failureTripFinishNotAllowed => 'No tienes permiso para finalizar este viaje.';

  @override
  String get failureTripFinishUnavailable => 'El viaje ya no está disponible para finalizar.';

  @override
  String get failureTripFinishFailed => 'No se pudo finalizar el viaje. Intenta de nuevo.';

  @override
  String get failureArrivalNotifyFailed => 'No se pudo notificar tu llegada. Intenta de nuevo.';

  @override
  String get failureActiveTripCheckFailed => 'No se pudo verificar si tienes un viaje en curso.';

  @override
  String get failureChatWriteNotAllowed => 'No tienes permiso para escribir en esta carrera.';

  @override
  String get failureChatRideFinished => 'La carrera ya finalizó, no se pueden enviar más mensajes.';

  @override
  String get failureChatSendFailed => 'No se pudo enviar el mensaje. Intenta de nuevo.';

  @override
  String get failureAccountHasActiveRide => 'Tienes un viaje activo. Finalízalo o cancélalo antes de eliminar tu cuenta.';

  @override
  String get failureAccountDeleteFailed => 'No se pudo eliminar tu cuenta. Intenta nuevamente.';

  @override
  String get failureDriverProfileCheckFailed => 'No se pudo verificar tu información de conductor';

  @override
  String get failureVehicleFetchFailed => 'No se pudo obtener la información del vehículo';

  @override
  String get failureProfileSaveFailed => 'No se pudo guardar tu información. Intenta nuevamente.';

  @override
  String get failureImagePickFailed => 'No se pudo obtener la imagen seleccionada';

  @override
  String get failureSessionVerifyFailed => 'No se pudo verificar tu sesión. Intenta de nuevo.';

  @override
  String get failureSignInFailed => 'No se pudo iniciar sesión. Intenta de nuevo.';

  @override
  String get failureSignOutFailed => 'No se pudo cerrar sesión. Intenta de nuevo.';

  @override
  String get failureUnexpected => 'Ocurrió un error inesperado. Intenta de nuevo.';

  @override
  String get failureChatMessagesLoadFailed => 'No se pudieron cargar los mensajes. Intenta de nuevo.';

  @override
  String get failureProfileLoadFailed => 'No se pudo cargar tu información';

  @override
  String isolateRideTowards(String address) {
    return 'Carrera hacia $address';
  }

  @override
  String get isolateNewRide => 'Nueva carrera';
}
