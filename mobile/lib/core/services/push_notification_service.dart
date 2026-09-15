import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../di/app_di.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Types mapping to backend and FCM notification events.
enum PushType {
  nearbyMissing,
  caseUpdate,
  sighting,
  possibleMatch,
  caseResolved,
}

class PushPayload {
  const PushPayload({
    required this.type,
    required this.title,
    required this.body,
    this.caseId,
    this.metadata = const {},
  });

  final PushType type;
  final String title;
  final String body;
  final String? caseId;
  final Map<String, String> metadata;
}

abstract class PushNotificationService {
  Future<String?> getToken();
  Future<void> show(PushPayload payload);
  List<PushPayload> get received;
}

/// Background message handler for FCM. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM Background] Received message: ${message.messageId}');
}

/// Production FCM + Local Notifications implementation.
class FcmPushNotificationService implements PushNotificationService {
  FcmPushNotificationService({ApiClient? apiClient}) : _apiClient = apiClient;

  final ApiClient? _apiClient;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final List<PushPayload> _received = [];
  bool _initialized = false;
  String? _fcmToken;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description:
        'This channel is used for emergency alerts and critical case updates.',
    importance: Importance.max,
  );

  @override
  List<PushPayload> get received => List.unmodifiable(_received);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      debugPrint('[FCM] Web platform detected. Native background FCM listeners skipped.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // 2. Setup Android notification channel for heads-up notifications
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_channel);
        await androidImplementation.requestNotificationsPermission();
      }

      // 3. Initialize Flutter Local Notifications
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[Notification] User tapped local notification: ${response.payload}');
        },
      );

      // 4. Foreground notification presentation options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Retrieve device FCM token and sync with backend
      _fcmToken = await messaging.getToken();
      debugPrint('[FCM] Device FCM Token: $_fcmToken');
      if (_fcmToken != null) {
        await _syncTokenWithBackend(_fcmToken!);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _syncTokenWithBackend(newToken);
      });

      // 6. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message received: ${message.data}');
        final payload = _parseRemoteMessage(message);
        _received.add(payload);
        show(payload);
      });

      // 7. Background message tap listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] App opened from background notification: ${message.data}');
        final payload = _parseRemoteMessage(message);
        _received.add(payload);
      });

      // 8. Check if launched from terminated state via notification tap
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] App launched from terminated state via notification: ${initialMessage.data}');
        final payload = _parseRemoteMessage(initialMessage);
        _received.add(payload);
      }
    } catch (e, stack) {
      debugPrint('[FCM] Error during initialization: $e\n$stack');
    }
  }

  Future<void> _syncTokenWithBackend(String token) async {
    try {
      final client = _apiClient ??
          (getIt.isRegistered<ApiClient>() ? getIt<ApiClient>() : null);
      if (client != null) {
        await client.run(
          (dio) => dio.post(
            ApiEndpoints.registerDeviceToken,
            data: {
              'token': token,
              'platform': defaultTargetPlatform.name.toLowerCase(),
            },
          ),
        );
        debugPrint('[FCM] Device token registered with backend successfully.');
      }
    } catch (e) {
      debugPrint('[FCM] Could not sync token with backend: $e');
    }
  }

  PushPayload _parseRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    final typeStr = data['type']?.toString().toLowerCase();

    PushType type = PushType.caseUpdate;
    if (typeStr == 'emergency' || typeStr == 'nearbymissing') {
      type = PushType.nearbyMissing;
    } else if (typeStr == 'sighting') {
      type = PushType.sighting;
    } else if (typeStr == 'possiblematch' || typeStr == 'match') {
      type = PushType.possibleMatch;
    } else if (typeStr == 'caseresolved' || typeStr == 'success') {
      type = PushType.caseResolved;
    }

    return PushPayload(
      type: type,
      title: notification?.title ??
          data['title']?.toString() ??
          'Reunitee Alert',
      body: notification?.body ?? data['body']?.toString() ?? '',
      caseId: data['caseId']?.toString() ?? data['report_id']?.toString(),
      metadata: data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }

  @override
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    if (kIsWeb) return 'web-simulated-token';
    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  @override
  Future<void> show(PushPayload payload) async {
    _received.add(payload);

    if (kIsWeb) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotifications.show(
        id,
        payload.title,
        payload.body,
        notificationDetails,
        payload: payload.caseId,
      );
    } catch (e) {
      debugPrint('[FCM] Error showing local notification: $e');
    }
  }
}

/// Fallback mock service for offline or test environments.
class MockPushNotificationService implements PushNotificationService {
  MockPushNotificationService();

  final List<PushPayload> _received = [];

  @override
  List<PushPayload> get received => List.unmodifiable(_received);

  @override
  Future<String?> getToken() async => 'demo-fcm-token';

  @override
  Future<void> show(PushPayload payload) async {
    _received.add(payload);
  }
}