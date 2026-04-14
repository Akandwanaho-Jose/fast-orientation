import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification channels
  static const String _announcementChannelId = 'announcements';
  static const String _urgentChannelId = 'urgent_announcements';
  static const String _generalChannelId = 'general_notifications';

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Configure FCM
      await _configureFCM();
      
      // Subscribe to topics
      await _subscribeToTopics();
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      if (kDebugMode) {
        print('✅ Notification service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing notification service: $e');
      }
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request FCM permissions
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    // Request system notification permissions (Android 13+)
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    if (kDebugMode) {
      print('🔔 Notification permission status: ${settings.authorizationStatus}');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Fixed: Removed const and fixed vibration patterns
    final List<AndroidNotificationChannel> channels = [
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
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureFCM() async {
    // Get FCM token
    final String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      if (kDebugMode) {
        print('🔑 FCM Token: $token');
      }
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error saving FCM token: $e');
        }
      }
    }
  }

  /// Subscribe to notification topics
  Future<void> _subscribeToTopics() async {
    try {
      // Subscribe to general announcements
      await _messaging.subscribeToTopic('announcements');
      
      // Subscribe to urgent announcements
      await _messaging.subscribeToTopic('urgent_announcements');
      
      // Subscribe to category-specific topics
      await _messaging.subscribeToTopic('academic');
      await _messaging.subscribeToTopic('events');
      await _messaging.subscribeToTopic('deadlines');
      await _messaging.subscribeToTopic('general');
      
      if (kDebugMode) {
        print('📬 Subscribed to notification topics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topics: $e');
      }
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('📱 Received foreground message: ${message.messageId}');
    }

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
    
    // Store notification in Firestore for notification history
    await _storeNotificationHistory(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final String title = message.notification?.title ?? 'FAST Connect';
    final String body = message.notification?.body ?? 'New announcement available';
    final Map<String, dynamic> data = message.data;

    // Determine channel based on priority
    String channelId = _generalChannelId;
    if (data['priority'] == 'urgent') {
      channelId = _urgentChannelId;
    } else if (data['type'] == 'announcement') {
      channelId = _announcementChannelId;
    }

    // Fixed: Removed const from AndroidNotificationDetails
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId, // Use the determined channel ID
      'Announcements',
      channelDescription: 'New announcements from FAST',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body), // Use actual body content
      ticker: 'New announcement',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default.wav',
    );

    final NotificationDetails details = NotificationDetails(
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

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final Map<String, dynamic> data = jsonDecode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  /// Handle notification tap from FCM
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 Notification tapped: ${message.messageId}');
    }
    _handleNotificationNavigation(message.data);
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Navigate to appropriate screen based on notification data
    final String? announcementId = data['announcementId'];
    final String? type = data['type'];
    
    if (announcementId != null && type == 'announcement') {
      // Navigate to announcement details
      // You'll need to implement this navigation logic
      // NavigationService.navigateToAnnouncement(announcementId);
      if (kDebugMode) {
        print('🔔 Navigate to announcement: $announcementId');
      }
    }
  }

  /// Store notification history
  Future<void> _storeNotificationHistory(RemoteMessage message) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
          print('❌ Error storing notification history: $e');
        }
      }
    }
  }

  /// Get notification history
  Stream<List<Map<String, dynamic>>> getNotificationHistory() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('receivedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
          print('❌ Error marking notification as read: $e');
        }
      }
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadNotificationCount() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Subscribe to specific category
  Future<void> subscribeToCategory(String category) async {
    try {
      await _messaging.subscribeToTopic(category.toLowerCase());
      if (kDebugMode) {
        print('📬 Subscribed to category: $category');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to category: $e');
      }
    }
  }

  /// Unsubscribe from specific category
  Future<void> unsubscribeFromCategory(String category) async {
    try {
      await _messaging.unsubscribeFromTopic(category.toLowerCase());
      if (kDebugMode) {
        print('📭 Unsubscribed from category: $category');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from category: $e');
      }
    }
  }

  /// Test notification (for development)
  Future<void> sendTestNotification() async {
    if (kDebugMode) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _announcementChannelId,
        'Announcements',
        channelDescription: 'Test notification',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        999,
        'Test Notification',
        'This is a test notification from FAST Connect',
        details,
      );
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Dispose resources
  void dispose() {
    // Clean up if needed
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('📱 Background message received: ${message.messageId}');
  }
  
  // Handle background message
  // You can store to local database or perform other background tasks
}