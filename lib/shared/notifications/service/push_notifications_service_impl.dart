import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/error/errors.dart';
import '../../../core/routing/app_routing.dart';
import '../../chat_presence/service/chat_presence_tracker.dart';
import '../../chat_presence/service/pending_chat_navigation_tracker.dart';
import 'push_notifications_service.dart';

const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificaciones importantes',
  description: 'Usado para mostrar notificaciones mientras la app está abierta',
  importance: Importance.high,
);

class PushNotificationsServiceImpl implements PushNotificationsService {
  PushNotificationsServiceImpl({
    required this.chatPresenceTracker,
    required this.pendingChatNavigationTracker,
  });

  final ChatPresenceTracker chatPresenceTracker;
  final PendingChatNavigationTracker pendingChatNavigationTracker;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  Future<Either<Failure, Unit>> initialize() async {
    try {
      await _messaging.requestPermission();

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          _navigate(response.payload);
        },
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      // App en foreground o en background pero con el proceso vivo: en
      // cualquiera de los dos casos TripScreen ya está montada dentro del
      // stack del branch (se llegó ahí al aceptar la carrera), así que basta
      // con avisarle al tracker -- su listener reacciona al instante.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (initialMessage.data['type'] == 'chat_message') {
          // Cold-start: TripScreen todavía no existe (SessionBloc recién va
          // a resolver si hay un viaje en curso) -- no navegar ahora mismo,
          // solo dejar el pedido pendiente para que TripScreen lo recoja en
          // cuanto se monte con la misma carrera.
          _requestChatNavigation(initialMessage.data);
        } else {
          final route = initialMessage.data['route'] as String?;
          WidgetsBinding.instance.addPostFrameCallback((_) => _navigate(route));
        }
      }

      return const Right(unit);
    } catch (e) {
      debugPrint('NotificationsDebug | Error en initialize: $e');
      return Left(
        Failure(message: 'No se pudo inicializar las notificaciones push'),
      );
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // El chat de esa misma carrera ya está abierto y renderiza el mensaje
    // en vivo vía su stream de Firestore: mostrar el banner sería duplicado.
    final data = message.data;
    if (data['type'] == 'chat_message' &&
        chatPresenceTracker.isOpen(rideId: data['rideId'] as String? ?? '')) {
      return;
    }

    try {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // Los pushes de chat codifican el rideId en el payload (con un
        // prefijo para distinguirlos) en vez de la route genérica, para que
        // el tap navegue directo al chat -- ver _navigate.
        payload:
            data['type'] == 'chat_message'
                ? 'chat:${data['rideId']}'
                : data['route'] as String?,
      );
    } catch (e) {
      debugPrint(
        'NotificationsDebug | Error en _showForegroundNotification: $e',
      );
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      _requestChatNavigation(message.data);
      return;
    }
    _navigate(message.data['route'] as String?);
  }

  void _requestChatNavigation(Map<String, dynamic> data) {
    final rideId = data['rideId'] as String?;
    if (rideId == null || rideId.isEmpty) return;
    pendingChatNavigationTracker.request(rideId: rideId);
  }

  static const _chatPayloadPrefix = 'chat:';

  void _navigate(String? payload) {
    if (payload == null || payload.isEmpty) return;

    if (payload.startsWith(_chatPayloadPrefix)) {
      final rideId = payload.substring(_chatPayloadPrefix.length);
      if (rideId.isEmpty) return;
      pendingChatNavigationTracker.request(rideId: rideId);
      return;
    }

    AppRouter.router.push(payload);
  }

  @override
  Future<Either<Failure, String?>> getToken() async {
    try {
      final token = await _messaging.getToken();
      return Right(token);
    } catch (e) {
      debugPrint('NotificationsDebug | Error en getToken: $e');
      return Left(
        Failure(message: 'No se pudo obtener el token de notificaciones'),
      );
    }
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
