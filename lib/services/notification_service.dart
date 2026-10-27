import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

/// Model for in-app notifications
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'donation', 'approval', 'alert', 'info'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data; // Extra context

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.data,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'info',
      timestamp: _parseDateTime(map['timestamp']),
      isRead: map['isRead'] ?? false,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'data': data,
      };

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}

/// Real-time notification service with local and push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controllers for notifications
  final BehaviorSubject<List<AppNotification>> _notificationsSubject =
      BehaviorSubject<List<AppNotification>>.seeded([]);
  final BehaviorSubject<int> _unreadCountSubject =
      BehaviorSubject<int>.seeded(0);

  // Expose streams
  Stream<List<AppNotification>> get notificationsStream =>
      _notificationsSubject.stream;
  Stream<int> get unreadCountStream => _unreadCountSubject.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      await _firebaseMessaging.requestPermission();

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      debugPrint('🔔 [Notifications] FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      debugPrint('✅ [Notifications] Service initialized');
    } catch (e) {
      debugPrint('❌ [Notifications] Initialization error: $e');
    }
  }

  /// Subscribe to donation notifications
  void subscribeToNotifications(String userId) {
    try {
      // Listen to notifications collection for this user
      _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        final notifications = snapshot.docs
            .map((doc) => AppNotification.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList();

        _notificationsSubject.add(notifications);

        // Update unread count
        final unreadCount =
            notifications.where((n) => !n.isRead).length;
        _unreadCountSubject.add(unreadCount);

        debugPrint('🔔 [Notifications] Updated: ${notifications.length} total, $unreadCount unread');
      });
    } catch (e) {
      debugPrint('❌ [Notifications] Subscription error: $e');
    }
  }

  /// Send notification when new donation is made
  Future<void> notifyNewDonation({
    required String donorName,
    required double amount,
    required String type, // 'Zakat' or 'Sadaqah'
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New $type Donation',
        message: '$donorName donated \$${amount.toStringAsFixed(2)}',
        type: 'donation',
        timestamp: DateTime.now(),
        isRead: false,
        data: {
          'donorName': donorName,
          'amount': amount,
          'donationType': type,
        },
      );

      await _saveNotification(notification);
      _showLocalNotification(notification);
    } catch (e) {
      debugPrint('❌ [Notifications] Error notifying donation: $e');
    }
  }

  /// Send notification for pending approval
  Future<void> notifyPendingApproval({
    required String requestType, // 'Beneficiary' or 'Aid Request'
    required String applicantName,
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Pending Review: $requestType',
        message: '$applicantName submitted a $requestType request for approval',
        type: 'approval',
        timestamp: DateTime.now(),
        isRead: false,
        data: {
          'applicantName': applicantName,
          'requestType': requestType,
        },
      );

      await _saveNotification(notification);
      _showLocalNotification(notification);
    } catch (e) {
      debugPrint('❌ [Notifications] Error notifying approval: $e');
    }
  }

  /// Send milestone notification
  Future<void> notifyMilestone({
    required String title,
    required String message,
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: 'info',
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _saveNotification(notification);
      _showLocalNotification(notification);
    } catch (e) {
      debugPrint('❌ [Notifications] Error notifying milestone: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      debugPrint('✅ [Notifications] Marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ [Notifications] Error marking as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();

      for (final notification in _notificationsSubject.value) {
        if (!notification.isRead) {
          batch.update(
              _firestore.collection('notifications').doc(notification.id),
              {'isRead': true});
        }
      }

      await batch.commit();
      _unreadCountSubject.add(0);
      debugPrint('✅ [Notifications] Marked all as read');
    } catch (e) {
      debugPrint('❌ [Notifications] Error marking all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();

      debugPrint('✅ [Notifications] Deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ [Notifications] Error deleting: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 [Notifications] Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(AppNotification(
        id: message.messageId ?? DateTime.now().toString(),
        title: message.notification!.title ?? 'Notification',
        message: message.notification!.body ?? '',
        type: message.data['type'] ?? 'info',
        timestamp: DateTime.now(),
        isRead: false,
        data: message.data,
      ));
    }
  }

  /// Handle message opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 [Notifications] Message opened: ${message.notification?.title}');
    // Navigate to relevant screen based on notification type
  }

  /// Save notification to Firestore
  Future<void> _saveNotification(AppNotification notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      debugPrint('❌ [Notifications] Error saving notification: $e');
    }
  }

  /// Show local notification (placeholder - implement platform-specific logic)
  void _showLocalNotification(AppNotification notification) {
    debugPrint(
        '🔔 [Notifications] Local: ${notification.title} - ${notification.message}');
    // TODO: Implement local_notifications package for actual toast/popup
  }

  /// Cleanup
  void dispose() {
    _notificationsSubject.close();
    _unreadCountSubject.close();
  }
}
