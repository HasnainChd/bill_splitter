import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../router/app_router.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class PushNotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  bool _initialized = false;

  PushNotificationService(this._ref) {
    _init();
  }

  void dispose() {
    // Clean up if needed
  }

  // Helper to generate a stable device ID from the FCM token
  String _getDeviceIdFromToken(String token) {
    // Use the last 32 characters of the token as a unique device ID
    return token.length > 32 ? token.substring(token.length - 32) : token;
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Request notification permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 PushNotificationService: Notification permissions granted.');
      } else {
        debugPrint('🔔 PushNotificationService: Notification permissions denied.');
      }

      // 2. Configure Android Local Notifications for foreground
      if (!kIsWeb) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);

        const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initializationSettingsIOS = DarwinInitializationSettings();
        const initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

        await _localNotifications.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            debugPrint('🔔 PushNotificationService: Notification tapped from foreground.');
            // We don't have the full RemoteMessage data here easily, but we can pass payload
            if (response.payload != null && response.payload!.isNotEmpty) {
              AppRouter.router.push(AppRouter.settleUp, extra: response.payload);
            }
          },
        );
      }

      // 3. Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 PushNotificationService: Foreground Message Received: ${message.notification?.title}');
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && !kIsWeb) {
          // Extract groupId for payload
          String? payloadGroupId;
          if (message.data.containsKey('groupId')) {
            payloadGroupId = message.data['groupId'];
          }

          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: payloadGroupId,
          );
        }
      });

      // 4. Handle token lifecycle and sync
      _fcm.onTokenRefresh.listen((token) async {
        debugPrint('🔔 PushNotificationService: FCM Token refreshed.');
        await _uploadToken(token);
      });

      // 5. Watch auth state changes to trigger token uploads/removals
      _ref.listen<User?>(supabaseUserProvider, (previous, current) async {
        if (current != null) {
          debugPrint('🔔 PushNotificationService: User logged in. Syncing token...');
          final token = await _fcm.getToken();
          if (token != null) {
            await _uploadToken(token);
          }
        } else if (previous != null) {
          debugPrint('🔔 PushNotificationService: User logged out. Removing token...');
          await _deleteToken(previous.id);
        }
      });

      // 6. Sync immediately if already logged in
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        final token = await _fcm.getToken();
        if (token != null) {
          await _uploadToken(token);
        }
      }

      // 7. Handle Background/Terminated Taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 PushNotificationService: Notification tapped in background.');
        _handleNotificationTap(message);
      });

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 PushNotificationService: Notification tapped from terminated state.');
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('🔔 PushNotificationService error during init: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('table') && data['table'] == 'requests') {
      final groupId = data['groupId'];
      if (groupId != null) {
        AppRouter.router.push(AppRouter.settleUp, extra: groupId);
      }
    }
  }

  // Upload token to Supabase user_tokens table
  Future<void> _uploadToken(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final deviceId = _getDeviceIdFromToken(token);
    
    // First, delete this token if it belongs to any other user (prevents cross-account notifications)
    try {
      await _supabase.from('user_tokens').delete().eq('fcm_token', token).neq('user_id', user.id);
    } catch (_) {}
    try {
      await _supabase.from('user_tokens').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'device_id': deviceId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('🔔 PushNotificationService: FCM token successfully registered for user ${user.id} and device $deviceId');
    } catch (e) {
      debugPrint('🔔 PushNotificationService: Failed to upload FCM token: $e');
    }
  }

  // Remove token from Supabase user_tokens table
  Future<void> _deleteToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      
      final deviceId = _getDeviceIdFromToken(token);
      await _supabase
          .from('user_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('device_id', deviceId);
      debugPrint('🔔 PushNotificationService: FCM token successfully deleted for user $userId and device $deviceId');
    } catch (e) {
      debugPrint('🔔 PushNotificationService: Failed to delete FCM token: $e');
    }
  }
}
