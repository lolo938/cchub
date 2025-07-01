import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  await NotificationService._handleBackgroundMessage(message);
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static bool _isInitialized = false;

  // Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      // Setup message handlers
      _setupMessageHandlers();
      
      _isInitialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    // Request Firebase messaging permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');

    // Request additional permissions for Android
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  // Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    const consultationChannel = AndroidNotificationChannel(
      'consultation_channel',
      'Consultation Notifications',
      description: 'Notifications for consultation requests and updates',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    const generalChannel = AndroidNotificationChannel(
      'general_channel',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    const urgentChannel = AndroidNotificationChannel(
      'urgent_channel',
      'Urgent Notifications',
      description: 'Urgent medical notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(consultationChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(urgentChannel);
  }

  // Initialize Firebase messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // Set foreground notification presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save FCM token
    await _saveFCMToken();
    
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);
  }

  // Setup message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Handle message opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Handle initial message when app is opened from terminated state
    _checkInitialMessage();
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification
    await _showLocalNotification(message);
    
    // Save notification to Firestore
    await _saveNotificationToFirestore(message);
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Received background message: ${message.messageId}');
    
    // Save notification to Firestore
    await _saveNotificationToFirestore(message);
  }

  // Handle message opened from notification
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');
    
    // Navigate to appropriate screen based on notification data
    await _handleNotificationNavigation(message);
  }

  // Check for initial message when app is opened from terminated state
  static Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state via notification: ${initialMessage.messageId}');
      await _handleNotificationNavigation(initialMessage);
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final channelId = _getChannelId(message.data['type'] ?? 'general');
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: _getImportance(message.data['priority'] ?? 'default'),
      priority: _getPriority(message.data['priority'] ?? 'default'),
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: _getNotificationStyle(message),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // Handle local notification tap
  static void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final message = RemoteMessage(data: Map<String, String>.from(data));
        _handleNotificationNavigation(message);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Handle notification navigation
  static Future<void> _handleNotificationNavigation(RemoteMessage message) async {
    final type = message.data['type'];
    final route = message.data['route'];
    
    // Store navigation data for app to handle when ready
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_notification_route', route ?? '/');
    await prefs.setString('pending_notification_data', jsonEncode(message.data));
    
    print('Stored navigation data for type: $type, route: $route');
  }

  // Save FCM token
  static Future<void> _saveFCMToken([String? token]) async {
    try {
      token ??= await _firebaseMessaging.getToken();
      if (token == null) return;

      print('FCM Token: $token');
      
      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      
      // TODO: Save token to user document in Firestore when user is logged in
      // This will be handled by the auth service when user logs in
      
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Save notification to Firestore
  static Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final userId = message.data['userId'];
      if (userId == null || userId.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'isRead': false,
        'receivedAt': FieldValue.serverTimestamp(),
        'messageId': message.messageId,
      });
    } catch (e) {
      print('Error saving notification to Firestore: $e');
    }
  }

  // Send notification to user
  static Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
    NotificationType type = NotificationType.general,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken == null) {
        print('No FCM token found for user: $userId');
        return false;
      }

      // Send notification via FCM (this would typically be done from your backend)
      // For now, we'll save it to Firestore and let the client handle it
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'type': type.name,
        'priority': priority.name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'sentViaFCM': true,
      });

      return true;
    } catch (e) {
      print('Error sending notification to user: $e');
      return false;
    }
  }

  // Send consultation notification
  static Future<bool> sendConsultationNotification({
    required String doctorId,
    required String parentId,
    required String consultationId,
    required ConsultationNotificationType notificationType,
    Map<String, String>? additionalData,
  }) async {
    final notification = _getConsultationNotificationContent(notificationType);
    
    final data = {
      'type': 'consultation',
      'consultationId': consultationId,
      'notificationType': notificationType.name,
      'route': '/consultation/$consultationId',
      ...?additionalData,
    };

    // Send to appropriate user based on notification type
    final targetUserId = notificationType == ConsultationNotificationType.newRequest
        ? doctorId
        : parentId;

    return await sendNotificationToUser(
      userId: targetUserId,
      title: notification['title']!,
      body: notification['body']!,
      data: data,
      type: NotificationType.consultation,
      priority: NotificationPriority.high,
    );
  }

  // Get consultation notification content
  static Map<String, String> _getConsultationNotificationContent(ConsultationNotificationType type) {
    switch (type) {
      case ConsultationNotificationType.newRequest:
        return {
          'title': 'New Consultation Request',
          'body': 'You have a new consultation request from a patient',
        };
      case ConsultationNotificationType.accepted:
        return {
          'title': 'Consultation Accepted',
          'body': 'Your consultation request has been accepted by the doctor',
        };
      case ConsultationNotificationType.rejected:
        return {
          'title': 'Consultation Request Declined',
          'body': 'Your consultation request has been declined',
        };
      case ConsultationNotificationType.started:
        return {
          'title': 'Consultation Started',
          'body': 'Your consultation is ready to begin',
        };
      case ConsultationNotificationType.completed:
        return {
          'title': 'Consultation Completed',
          'body': 'Your consultation has been completed',
        };
      case ConsultationNotificationType.reminder:
        return {
          'title': 'Consultation Reminder',
          'body': 'Your consultation is starting in 15 minutes',
        };
    }
  }

  // Update user FCM token in Firestore
  static Future<void> updateUserFCMToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('Updated FCM token for user: $userId');
      }
    } catch (e) {
      print('Error updating user FCM token: $e');
    }
  }

  // Clear pending navigation data
  static Future<void> clearPendingNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_notification_route');
    await prefs.remove('pending_notification_data');
  }

  // Get pending navigation data
  static Future<Map<String, String>?> getPendingNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString('pending_notification_route');
    final data = prefs.getString('pending_notification_data');
    
    if (route != null && data != null) {
      return {
        'route': route,
        'data': data,
      };
    }
    return null;
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get user notifications stream
  static Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('receivedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Helper methods for notification styling
  static String _getChannelId(String type) {
    switch (type) {
      case 'consultation':
        return 'consultation_channel';
      case 'urgent':
        return 'urgent_channel';
      default:
        return 'general_channel';
    }
  }

  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'consultation_channel':
        return 'Consultation Notifications';
      case 'urgent_channel':
        return 'Urgent Notifications';
      default:
        return 'General Notifications';
    }
  }

  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'consultation_channel':
        return 'Notifications for consultation requests and updates';
      case 'urgent_channel':
        return 'Urgent medical notifications';
      default:
        return 'General app notifications';
    }
  }

  static Importance _getImportance(String priority) {
    switch (priority) {
      case 'high':
        return Importance.high;
      case 'max':
        return Importance.max;
      case 'low':
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  static Priority _getPriority(String priority) {
    switch (priority) {
      case 'high':
        return Priority.high;
      case 'max':
        return Priority.max;
      case 'low':
        return Priority.low;
      default:
        return Priority.defaultPriority;
    }
  }

  static StyleInformation? _getNotificationStyle(RemoteMessage message) {
    final style = message.data['style'];
    if (style == 'big_text') {
      return BigTextStyleInformation(
        message.notification?.body ?? '',
        contentTitle: message.notification?.title,
      );
    }
    return null;
  }
}

// Notification types
enum NotificationType {
  general,
  consultation,
  appointment,
  reminder,
  urgent,
}

enum NotificationPriority {
  low,
  normal,
  high,
  max,
}

enum ConsultationNotificationType {
  newRequest,
  accepted,
  rejected,
  started,
  completed,
  reminder,
}