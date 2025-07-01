import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notification_service.dart';
import 'auth_provider.dart';

// User notifications provider
final userNotificationsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return NotificationService.getUserNotifications(userId);
});

// Current user notifications provider
final currentUserNotificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return NotificationService.getUserNotifications(user.uid);
});

// Unread notifications count provider
final unreadNotificationsCountProvider = Provider.family<int, List<Map<String, dynamic>>>((ref, notifications) {
  return notifications.where((notification) => !(notification['isRead'] ?? false)).length;
});

// Current user unread notifications count provider
final currentUserUnreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(currentUserNotificationsProvider);
  return notificationsAsync.when(
    data: (notifications) => ref.watch(unreadNotificationsCountProvider(notifications)),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Notification controller provider
final notificationControllerProvider = StateNotifierProvider<NotificationController, NotificationState>((ref) {
  return NotificationController(ref);
});

// Notification state class
class NotificationState {
  final bool isLoading;
  final String? error;
  final bool permissionGranted;
  final String? fcmToken;

  const NotificationState({
    this.isLoading = false,
    this.error,
    this.permissionGranted = false,
    this.fcmToken,
  });

  NotificationState copyWith({
    bool? isLoading,
    String? error,
    bool? permissionGranted,
    String? fcmToken,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

// Notification controller class
class NotificationController extends StateNotifier<NotificationState> {
  final Ref ref;

  NotificationController(this.ref) : super(const NotificationState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await NotificationService.initialize();
      state = state.copyWith(
        isLoading: false,
        permissionGranted: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Send consultation notification
  Future<bool> sendConsultationNotification({
    required String doctorId,
    required String parentId,
    required String consultationId,
    required ConsultationNotificationType notificationType,
    Map<String, String>? additionalData,
  }) async {
    try {
      return await NotificationService.sendConsultationNotification(
        doctorId: doctorId,
        parentId: parentId,
        consultationId: consultationId,
        notificationType: notificationType,
        additionalData: additionalData,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Send custom notification
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
    NotificationType type = NotificationType.general,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      return await NotificationService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        data: data,
        type: type,
        priority: priority,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await NotificationService.markNotificationAsRead(userId, notificationId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Update user FCM token
  Future<void> updateUserFCMToken(String userId) async {
    try {
      await NotificationService.updateUserFCMToken(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Handle pending navigation
  Future<Map<String, String>?> getPendingNavigation() async {
    try {
      return await NotificationService.getPendingNavigation();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Clear pending navigation
  Future<void> clearPendingNavigation() async {
    try {
      await NotificationService.clearPendingNavigation();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Notification type filter provider
final notificationTypeFilterProvider = StateProvider<NotificationType?>((ref) => null);

// Filtered notifications provider
final filteredNotificationsProvider = Provider.family<List<Map<String, dynamic>>, List<Map<String, dynamic>>>((ref, notifications) {
  final filter = ref.watch(notificationTypeFilterProvider);
  if (filter == null) return notifications;
  
  return notifications.where((notification) {
    final type = notification['type'] as String?;
    return type == filter.name;
  }).toList();
});

// Recent notifications provider (last 10)
final recentNotificationsProvider = Provider.family<List<Map<String, dynamic>>, List<Map<String, dynamic>>>((ref, notifications) {
  return notifications.take(10).toList();
});

// Today's notifications provider
final todayNotificationsProvider = Provider.family<List<Map<String, dynamic>>, List<Map<String, dynamic>>>((ref, notifications) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  
  return notifications.where((notification) {
    final receivedAt = notification['receivedAt'];
    if (receivedAt == null) return false;
    
    DateTime notificationDate;
    if (receivedAt is DateTime) {
      notificationDate = receivedAt;
    } else {
      // Handle Firestore Timestamp
      try {
        notificationDate = receivedAt.toDate();
      } catch (e) {
        return false;
      }
    }
    
    return notificationDate.isAfter(startOfDay);
  }).toList();
});

// Notification stats provider
final notificationStatsProvider = Provider.family<Map<String, int>, List<Map<String, dynamic>>>((ref, notifications) {
  final stats = <String, int>{
    'total': notifications.length,
    'unread': 0,
    'today': 0,
    'consultation': 0,
    'general': 0,
  };

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  for (final notification in notifications) {
    // Count unread
    if (!(notification['isRead'] ?? false)) {
      stats['unread'] = (stats['unread'] ?? 0) + 1;
    }

    // Count today's notifications
    final receivedAt = notification['receivedAt'];
    if (receivedAt != null) {
      try {
        final notificationDate = receivedAt is DateTime 
            ? receivedAt 
            : receivedAt.toDate();
        if (notificationDate.isAfter(startOfDay)) {
          stats['today'] = (stats['today'] ?? 0) + 1;
        }
      } catch (e) {
        // Handle parsing error
      }
    }

    // Count by type
    final type = notification['type'] as String? ?? 'general';
    if (type == 'consultation') {
      stats['consultation'] = (stats['consultation'] ?? 0) + 1;
    } else {
      stats['general'] = (stats['general'] ?? 0) + 1;
    }
  }

  return stats;
});