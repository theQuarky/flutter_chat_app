// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Initialize local notifications
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // iOS: IOSInitializationSettings(),
      );
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Get the token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token'); // Debug print
        await _saveTokenToFirestore(token);
      }

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((String token) {
        print('FCM Token refreshed: $token'); // Debug print
        _saveTokenToFirestore(token);
      });

      // Handle incoming messages
      FirebaseMessaging.onMessage.listen(_handleMessage);
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'deviceTokens': FieldValue.arrayUnion([token])
      });
    }
  }

  void _handleMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_match_notification',
            'Chat Match Notification',
            icon: android.smallIcon,
          ),
        ),
      );
    }
  }
}
