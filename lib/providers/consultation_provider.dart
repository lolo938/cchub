import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/consultation_service.dart';
import '../models/consultation_model.dart';
// import '../models/doctor_model.dart';
import 'auth_provider.dart';

// User consultations provider
final userConsultationsProvider =
    StreamProvider.family<List<ConsultationRequest>, String>((ref, userId) {
  return ConsultationService.getUserConsultations(userId);
});

// Current user consultations provider
final currentUserConsultationsProvider =
    StreamProvider<List<ConsultationRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ConsultationService.getUserConsultations(user.uid);
});

// Doctor consultations provider
final doctorConsultationsProvider =
    StreamProvider.family<List<ConsultationRequest>, String>((ref, doctorId) {
  return ConsultationService.getDoctorConsultations(doctorId);
});

// Pending consultations for doctor provider
final pendingConsultationsForDoctorProvider =
    StreamProvider.family<List<ConsultationRequest>, String>((ref, doctorId) {
  return ConsultationService.getPendingConsultationsForDoctor(doctorId);
});

// Current doctor consultations provider
final currentDoctorConsultationsProvider =
    StreamProvider<List<ConsultationRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ConsultationService.getDoctorConsultations(user.uid);
});

// Current doctor pending consultations provider
final currentDoctorPendingConsultationsProvider =
    StreamProvider<List<ConsultationRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ConsultationService.getPendingConsultationsForDoctor(user.uid);
});

// Consultation by ID provider
final consultationProvider =
    FutureProvider.family<ConsultationRequest?, String>((ref, consultationId) {
  return ConsultationService.getConsultation(consultationId);
});

// Available time slots provider
final availableTimeSlotsProvider =
    FutureProvider.family<List<DateTime>, Map<String, dynamic>>((ref, params) {
  final doctorId = params['doctorId'] as String;
  final date = params['date'] as DateTime;
  return ConsultationService.getAvailableTimeSlots(doctorId, date);
});

// Consultation controller provider
final consultationControllerProvider =
    StateNotifierProvider<ConsultationController, ConsultationState>((ref) {
  return ConsultationController(ref);
});

// Consultation state class
class ConsultationState {
  final bool isLoading;
  final String? error;
  final String? currentConsultationId;
  final bool isInCall;

  const ConsultationState({
    this.isLoading = false,
    this.error,
    this.currentConsultationId,
    this.isInCall = false,
  });

  ConsultationState copyWith({
    bool? isLoading,
    String? error,
    String? currentConsultationId,
    bool? isInCall,
  }) {
    return ConsultationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentConsultationId:
          currentConsultationId ?? this.currentConsultationId,
      isInCall: isInCall ?? this.isInCall,
    );
  }
}

// Consultation controller class
class ConsultationController extends StateNotifier<ConsultationState> {
  final Ref ref;

  ConsultationController(this.ref) : super(const ConsultationState());

  // Create instant consultation
  Future<String?> createInstantConsultation({
    required String parentId,
    required String childId,
    String? preferredDoctorId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final consultationId =
          await ConsultationService.createInstantConsultation(
        parentId: parentId,
        childId: childId,
        preferredDoctorId: preferredDoctorId,
      );

      if (consultationId != null) {
        state = state.copyWith(
          isLoading: false,
          currentConsultationId: consultationId,
        );
        return consultationId;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create consultation request',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  // Create scheduled consultation
  Future<String?> createScheduledConsultation({
    required String parentId,
    required String childId,
    required String doctorId,
    required DateTime scheduledTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final consultationId =
          await ConsultationService.createScheduledConsultation(
        parentId: parentId,
        childId: childId,
        doctorId: doctorId,
        scheduledTime: scheduledTime,
      );

      if (consultationId != null) {
        state = state.copyWith(
          isLoading: false,
          currentConsultationId: consultationId,
        );
        return consultationId;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create scheduled consultation',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  // Accept consultation (doctor)
  Future<bool> acceptConsultation(
      String consultationId, String doctorId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await ConsultationService.acceptConsultation(
          consultationId, doctorId);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          currentConsultationId: consultationId,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to accept consultation',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Reject consultation (doctor)
  Future<bool> rejectConsultation(
      String consultationId, String doctorId, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await ConsultationService.rejectConsultation(
          consultationId, doctorId, reason);

      state = state.copyWith(
        isLoading: false,
        error: success ? null : 'Failed to reject consultation',
      );

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Start consultation
  Future<bool> startConsultation(String consultationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success =
          await ConsultationService.startConsultation(consultationId);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          isInCall: true,
          currentConsultationId: consultationId,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to start consultation',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Complete consultation
  Future<bool> completeConsultation(String consultationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success =
          await ConsultationService.completeConsultation(consultationId);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          isInCall: false,
          currentConsultationId: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to complete consultation',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Cancel consultation
  Future<bool> cancelConsultation(String consultationId, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success =
          await ConsultationService.cancelConsultation(consultationId, reason);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          isInCall: false,
          currentConsultationId: state.currentConsultationId == consultationId
              ? null
              : state.currentConsultationId,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to cancel consultation',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // End call
  void endCall() {
    state = state.copyWith(isInCall: false);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Set current consultation
  void setCurrentConsultation(String? consultationId) {
    state = state.copyWith(currentConsultationId: consultationId);
  }
}

// Active consultations provider - filters for active consultations
final activeConsultationsProvider =
    Provider.family<AsyncValue<List<ConsultationRequest>>, String>(
        (ref, userId) {
  final consultationsAsync = ref.watch(userConsultationsProvider(userId));

  return consultationsAsync.when(
    data: (consultations) {
      final activeConsultations =
          consultations.where((c) => c.isActive).toList();
      return AsyncValue.data(activeConsultations);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Current user active consultations provider
final currentUserActiveConsultationsProvider =
    Provider<AsyncValue<List<ConsultationRequest>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);
  return ref.watch(activeConsultationsProvider(user.uid));
});

// Consultation stats provider
final consultationStatsProvider =
    Provider.family<Map<String, int>, List<ConsultationRequest>>(
        (ref, consultations) {
  final stats = <String, int>{
    'total': consultations.length,
    'pending': 0,
    'accepted': 0,
    'completed': 0,
    'cancelled': 0,
  };

  for (final consultation in consultations) {
    switch (consultation.status) {
      case ConsultationStatus.pending:
      case ConsultationStatus.waitingForDoctor:
        stats['pending'] = (stats['pending'] ?? 0) + 1;
        break;
      case ConsultationStatus.accepted:
      case ConsultationStatus.scheduled:
      case ConsultationStatus.inProgress:
        stats['accepted'] = (stats['accepted'] ?? 0) + 1;
        break;
      case ConsultationStatus.completed:
        stats['completed'] = (stats['completed'] ?? 0) + 1;
        break;
      case ConsultationStatus.cancelled:
      case ConsultationStatus.rejected:
        stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
        break;
    }
  }

  return stats;
});

// Doctor earnings provider (for completed consultations)
final doctorEarningsProvider =
    Provider.family<double, List<ConsultationRequest>>((ref, consultations) {
  return consultations
      .where((c) => c.status == ConsultationStatus.completed)
      .fold<double>(
          0, (total, c) => total + (c.fee * 0.9)); // 90% after platform fee
});

// Consultation filter provider
final consultationFilterProvider =
    StateProvider<ConsultationStatus?>((ref) => null);

// Filtered consultations provider
final filteredConsultationsProvider =
    Provider.family<List<ConsultationRequest>, List<ConsultationRequest>>(
        (ref, consultations) {
  final filter = ref.watch(consultationFilterProvider);
  if (filter == null) return consultations;
  return consultations.where((c) => c.status == filter).toList();
});

// Legacy notifier adapter for backward compatibility
class _ConsultationNoopNotifier {
  Future<void> loadConsultations() async {}
  Future<void> updateConsultationStatus(dynamic id, dynamic status) async {}
}

extension ConsultationFutureProviderLegacy
    on FutureProviderFamily<ConsultationRequest?, String> {
  _ConsultationNoopNotifier get notifier => _ConsultationNoopNotifier();
}
