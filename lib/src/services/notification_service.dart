import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  /// Chave global para navegação a partir de notificações fora da árvore de widgets.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Chave global para exibição confiável de SnackBars em foreground.
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Última mensagem recebida em foreground, útil para observação reativa ou testes.
  final ValueNotifier<RemoteMessage?> lastForegroundMessage =
      ValueNotifier<RemoteMessage?>(null);

  bool _handlersConfigured = false;

  Future<void> initialize() async {
    // 1. Solicita permissão ao usuário (iOS e Android 13+)
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Habilita exibição em foreground também no iOS (banner, badge e som)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final bool hasPermission =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (hasPermission) {
      debugPrint('Permissão de notificação concedida pelo usuário.');

      final String? token = await _fcm.getToken();
      debugPrint('====================================');
      debugPrint('FCM TOKEN DO DISPOSITIVO: $token');
      debugPrint('====================================');

      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token atualizado: $newToken');
      });

      _setupMessageHandlers();
    } else {
      debugPrint('Permissão de notificação negada ou não configurada.');
    }
  }

  void _setupMessageHandlers() {
    if (_handlersConfigured) return;
    _handlersConfigured = true;

    // Foreground: app aberto em primeiro plano
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);

    // Background: app minimizado e aberto pelo toque na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Toque na notificação (Background): ${message.data}');
      _handleDeepLink(message);
    });

    // Terminated: app fechado e iniciado pelo toque na notificação
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App inicializado a partir de notificação: ${message.data}');
        _handleDeepLink(message);
      }
    });
  }

  /// Processa e exibe visualmente notificações recebidas com o app em foreground.
  @visibleForTesting
  void handleForegroundMessage(RemoteMessage message) {
    lastForegroundMessage.value = message;

    final String title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'Alerta climático';
    final String body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        'Nova atualização de previsão disponível.';
    final String? city = message.data['city']?.toString();

    debugPrint('Mensagem recebida em Foreground: $title - $body');

    final ScaffoldMessengerState? messenger =
        scaffoldMessengerKey.currentState ??
        (navigatorKey.currentContext != null
            ? ScaffoldMessenger.maybeOf(navigatorKey.currentContext!)
            : null);

    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF00457D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF7693FF), width: 1.2),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF7693FF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (body.isNotEmpty)
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          action: city != null && city.trim().isNotEmpty
              ? SnackBarAction(
                  label: 'Ver clima',
                  textColor: const Color(0xFF7693FF),
                  onPressed: () => _handleDeepLink(message),
                )
              : null,
        ),
      );
  }

  void _handleDeepLink(RemoteMessage message) {
    final String? city = message.data['city']?.toString().trim();
    if (city != null && city.isNotEmpty) {
      navigatorKey.currentState?.pushNamed('/weather', arguments: city);
    }
  }
}
