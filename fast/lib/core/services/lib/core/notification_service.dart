import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _announcementChannelId = 'announcements';
  static const String _urgentChannelId = 'urgent_announcements';
  static const String _generalChannelId = 'general_notifications';

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _supportsNativeNotifications => _isAndroid || _isIOS;

  String get _platformLabel {
    if (kIsWeb) {
      return 'web';
    }
    if (_isAndroid) {
      return 'android';
    }
    if (_isIOS) {
      return 'ios';
    }
    return defaultTargetPlatform.name;
  }

  Future<void> initialize() async {
    try {
      if (!_supportsNativeNotifications) {
        if (kDebugMode) {
          debugPrint(
            'Notification service skipped on unsupported platform: $_platformLabel',
          );
        }
        return;
      }

      await _requestPermissions();
      await _initializeLocalNotifications();
      await _configureFCM();
      await _subscribeToTopics();

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      if (kDebugMode) {
        debugPrint('Notification service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing notification service: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (_isAndroid) {
      await Permission.notification.request();
    }

    if (kDebugMode) {
      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (_isAndroid) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    final channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        _announcementChannelId,
        'Announcements',
        description: 'New announcements from FAST',
        importance: Importance.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
      ),
      AndroidNotificationChannel(
        _urgentChannelId,
        'Urgent Announcements',
        description: 'Urgent announcements requiring immediate attention',
        importance: Importance.max,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ),
      const AndroidNotificationChannel(
        _generalChannelId,
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _configureFCM() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      if (kDebugMode) {
        debugPrint('FCM token received');
      }
    }

    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': _platformLabel,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  Future<void> _subscribeToTopics() async {
    try {
      await _messaging.subscribeToTopic('announcements');
      await _messaging.subscribeToTopic('urgent_announcements');
      await _messaging.subscribeToTopic('academic');
      await _messaging.subscribeToTopic('events');
      await _messaging.subscribeToTopic('deadlines');
      await _messaging.subscribeToTopic('general');

      if (kDebugMode) {
        debugPrint('Subscribed to notification topics');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error subscribing to topics: $e');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('Received foreground message: ${message.messageId}');
    }

    await _showLocalNotification(message);
    await _storeNotificationHistory(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'FAST Connect';
    final body =
        message.notification?.body ?? 'New announcement available';
    final data = message.data;

    var channelId = _generalChannelId;
    if (data['priority'] == 'urgent') {
      channelId = _urgentChannelId;
    } else if (data['type'] == 'announcement') {
      channelId = _announcementChannelId;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Announcements',
      channelDescription: 'New announcements from FAST',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body),
      ticker: 'New announcement',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default.wav',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) {
      return;
    }

    final data = jsonDecode(payload) as Map<String, dynamic>;
    _handleNotificationNavigation(data);
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${message.messageId}');
    }
    _handleNotificationNavigation(message.data);
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final announcementId = data['announcementId'] as String?;
    final type = data['type'] as String?;

    if (announcementId != null && type == 'announcement' && kDebugMode) {
      debugPrint('Navigate to announcement: $announcementId');
    }
  }

  Future<void> _storeNotificationHistory(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
            'title': message.notification?.title,
            'body': message.notification?.body,
            'data': message.data,
            'receivedAt': FieldValue.serverTimestamp(),
            'read': false,
            'messageId': message.messageId,
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error storing notification history: $e');
      }
    }
  }

  Stream<List<Map<String, dynamic>>> getNotificationHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('receivedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking notification as read: $e');
      }
    }
  }

  Stream<int> getUnreadNotificationCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> subscribeToCategory(String category) async {
    try {
      await _messaging.subscribeToTopic(category.toLowerCase());
      if (kDebugMode) {
        debugPrint('Subscribed to category: $category');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error subscribing to category: $e');
      }
    }
  }

  Future<void> unsubscribeFromCategory(String category) async {
    try {
      await _messaging.unsubscribeFromTopic(category.toLowerCase());
      if (kDebugMode) {
        debugPrint('Unsubscribed from category: $category');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error unsubscribing from category: $e');
      }
    }
  }

  Future<void> sendTestNotification() async {
    if (!kDebugMode || !_isAndroid) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _announcementChannelId,
      'Announcements',
      channelDescription: 'Test notification',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      999,
      'Test Notification',
      'This is a test notification from FAST Connect',
      details,
    );
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  void dispose() {}
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Background message received: ${message.messageId}');
  }
}
