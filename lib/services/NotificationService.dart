import 'package:chat_app/services/AppStateService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String CHANNEL_ID = 'chat_match_notification';
  static const String CHANNEL_NAME = 'Chat Match Notification';
  static const String CHANNEL_DESCRIPTION =
      'This channel is used for chat match notifications.';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Function(String, String)? onNotificationTap;

  Future<void> initialize() async {
    print('NotificationService: Initializing...');

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _createNotificationChannel();
    await _initializeLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('NotificationService: FCM Token: $token');
      await _saveTokenToFirestore(token);
    }

    print('NotificationService: Initialization complete');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      CHANNEL_ID,
      CHANNEL_NAME,
      description: CHANNEL_DESCRIPTION,
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        final payload = details.payload?.split('|');
        if (payload != null && payload.length == 2) {
          _handleNotificationClick(RemoteMessage(data: {
            'chatId': payload[0],
            'senderId': payload[1],
          }));
        }
      },
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'deviceTokens': FieldValue.arrayUnion([token])
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      final chatId = message.data['chatId'];

      if (_shouldShowNotification(chatId)) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              CHANNEL_ID,
              CHANNEL_NAME,
              channelDescription: CHANNEL_DESCRIPTION,
              icon: android.smallIcon,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: '${message.data['chatId']}|${message.data['senderId']}',
        );
      }
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final chatId = message.data['chatId'];
    final senderId = message.data['senderId'];
    if (chatId != null && senderId != null && onNotificationTap != null) {
      onNotificationTap!(chatId, senderId);
    }
  }

  bool _shouldShowNotification(String? chatId) {
    if (AppState.currentScreen == AppScreen.friendsList) {
      return false;
    }
    if (AppState.currentScreen == AppScreen.chat &&
        AppState.currentChatId == chatId) {
      return false;
    }
    return true;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // You can add logic here to handle the background message if needed
}
