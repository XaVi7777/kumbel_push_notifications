import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ============================================================================
// Обработчик фоновых уведомлений (должен быть top-level функцией)
// ============================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

// ============================================================================
// Канал для локальных уведомлений (Android foreground)
// ============================================================================
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Канал для важных уведомлений',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ============================================================================
// main
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Регистрируем обработчик фоновых сообщений
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Создаём канал уведомлений на Android
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);

  // Инициализируем локальные уведомления
  await _localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  runApp(const PushNotificationApp());
}

// ============================================================================
// App
// ============================================================================
class PushNotificationApp extends StatelessWidget {
  const PushNotificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Push Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================================
// HomePage
// ============================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _fcmToken;
  final List<_NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // 1. Запрос разрешений
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Permission status: ${settings.authorizationStatus}');

    // 2. Получение FCM-токена
    final token = await messaging.getToken();
    setState(() => _fcmToken = token);
    debugPrint('FCM Token: $token');

    // 3. Слушаем обновление токена
    messaging.onTokenRefresh.listen((newToken) {
      setState(() => _fcmToken = newToken);
      debugPrint('Token refreshed: $newToken');
    });

    // 4. Foreground-сообщения
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Нажатие на уведомление (приложение было в background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. Проверяем, не было ли приложение открыто из terminated через уведомление
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _addNotification(
        initialMessage,
        source: 'terminated',
      );
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _addNotification(message, source: 'foreground');

    // Показываем локальное уведомление, чтобы пользователь видел его в шторке
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _addNotification(message, source: 'background (tap)');
  }

  void _addNotification(RemoteMessage message, {required String source}) {
    setState(() {
      _notifications.insert(
        0,
        _NotificationItem(
          title: message.notification?.title ?? 'No title',
          body: message.notification?.body ?? 'No body',
          data: message.data,
          source: source,
          time: DateTime.now(),
        ),
      );
    });
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM Token скопирован в буфер обмена')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // ---- FCM Token ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'FCM Token',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_fcmToken != null)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: _copyToken,
                        tooltip: 'Копировать токен',
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _fcmToken ?? 'Загрузка...',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ---- Заголовок списка ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.notifications, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Полученные уведомления (${_notifications.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // ---- Список уведомлений ----
          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Уведомлений пока нет.\n'
                          'Отправьте тестовое из Firebase Console.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return Card(
                        child: ListTile(
                          leading: _sourceIcon(item.source),
                          title: Text(item.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.body),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _SourceChip(source: item.source),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.time.hour}:${item.time.minute.toString().padLeft(2, '0')}:${item.time.second.toString().padLeft(2, '0')}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              if (item.data.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Data: ${item.data}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontFamily: 'monospace',
                                      ),
                                ),
                              ],
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sourceIcon(String source) {
    return switch (source) {
      'foreground' => const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.visibility, color: Colors.white, size: 18),
        ),
      'background (tap)' => const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.touch_app, color: Colors.white, size: 18),
        ),
      'terminated' => const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.power_settings_new, color: Colors.white, size: 18),
        ),
      _ => const CircleAvatar(
          child: Icon(Icons.notifications, size: 18),
        ),
    };
  }
}

// ============================================================================
// Вспомогательные виджеты и модели
// ============================================================================

class _NotificationItem {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String source;
  final DateTime time;

  _NotificationItem({
    required this.title,
    required this.body,
    required this.data,
    required this.source,
    required this.time,
  });
}

class _SourceChip extends StatelessWidget {
  final String source;
  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (source) {
      'foreground' => (Colors.green, 'Foreground'),
      'background (tap)' => (Colors.orange, 'Background'),
      'terminated' => (Colors.red, 'Terminated'),
      _ => (Colors.grey, source),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
