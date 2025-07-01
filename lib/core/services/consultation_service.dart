import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/consultation_model.dart';
import '../../models/doctor_model.dart';
import '../../models/child_model.dart';
import 'wallet_service.dart';
import 'notification_service.dart';

class ConsultationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // Create instant consultation request
  static Future<String?> createInstantConsultation({
    required String parentId,
    required String childId,
    String? preferredDoctorId,
  }) async {
    try {
      // Get child information
      final childDoc = await _firestore
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();

      if (!childDoc.exists) {
        throw Exception('Child not found');
      }

      final child = Child.fromMap(childDoc.data()!, childDoc.id);
      
      // Get fee from app config
      final configDoc = await _firestore
          .collection('appConfig')
          .doc('consultationTypes')
          .get();
      
      final baseFee = configDoc.data()?['instant']?['baseFee'] ?? 600.0;
      final timeoutMinutes = configDoc.data()?['instant']?['timeoutMinutes'] ?? 10;

      // Check wallet balance
      final canAfford = await WalletService.canAfford(parentId, baseFee);
      if (!canAfford) {
        throw Exception('Insufficient wallet balance');
      }

      final consultationId = _uuid.v4();
      final expiresAt = DateTime.now().add(Duration(minutes: timeoutMinutes));

      final consultation = ConsultationRequest(
        id: consultationId,
        type: ConsultationType.instant,
        parentId: parentId,
        childId: childId,
        doctorId: preferredDoctorId,
        childName: child.name,
        childAge: child.ageInYears,
        status: preferredDoctorId != null 
            ? ConsultationStatus.waitingForDoctor 
            : ConsultationStatus.pending,
        fee: baseFee,
        requestedAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      // Save consultation request
      await _firestore
          .collection('consultations')
          .doc(consultationId)
          .set(consultation.toMap());

      // If specific doctor preferred, notify them
      if (preferredDoctorId != null) {
        await _notifyDoctor(preferredDoctorId, consultationId);
        // Send push notification
        await NotificationService.sendConsultationNotification(
          doctorId: preferredDoctorId,
          parentId: parentId,
          consultationId: consultationId,
          notificationType: ConsultationNotificationType.newRequest,
        );
      } else {
        // Find available doctors and notify them
        await _notifyAvailableDoctors(consultationId);
      }

      return consultationId;
    } catch (e) {
      print('Error creating instant consultation: $e');
      return null;
    }
  }

  // Create scheduled consultation request
  static Future<String?> createScheduledConsultation({
    required String parentId,
    required String childId,
    required String doctorId,
    required DateTime scheduledTime,
  }) async {
    try {
      // Get child information
      final childDoc = await _firestore
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();

      if (!childDoc.exists) {
        throw Exception('Child not found');
      }

      final child = Child.fromMap(childDoc.data()!, childDoc.id);

      // Get doctor information
      final doctorDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        throw Exception('Doctor not found');
      }

      final doctor = Doctor.fromMap(doctorDoc.data()!, doctorDoc.id);
      
      // Verify doctor availability for the requested time
      final isAvailable = await _checkDoctorAvailability(doctorId, scheduledTime);
      if (!isAvailable) {
        throw Exception('Doctor is not available at the requested time');
      }

      // Check wallet balance
      final canAfford = await WalletService.canAfford(parentId, doctor.consultationFee);
      if (!canAfford) {
        throw Exception('Insufficient wallet balance');
      }

      final consultationId = _uuid.v4();

      final consultation = ConsultationRequest(
        id: consultationId,
        type: ConsultationType.scheduled,
        parentId: parentId,
        childId: childId,
        doctorId: doctorId,
        childName: child.name,
        childAge: child.ageInYears,
        status: ConsultationStatus.scheduled,
        fee: doctor.consultationFee,
        requestedAt: DateTime.now(),
        scheduledTime: scheduledTime,
      );

      // Save consultation request
      await _firestore
          .collection('consultations')
          .doc(consultationId)
          .set(consultation.toMap());

      // Reserve doctor's time slot
      await _reserveTimeSlot(doctorId, scheduledTime, consultationId);

      // Deduct fee from wallet
      await WalletService.deductFromWallet(
        parentId,
        doctor.consultationFee,
        'Scheduled consultation with ${doctor.name}',
        referenceId: consultationId,
      );

      // Notify doctor
      await _notifyDoctor(doctorId, consultationId);
      
      // Send push notification
      await NotificationService.sendConsultationNotification(
        doctorId: doctorId,
        parentId: parentId,
        consultationId: consultationId,
        notificationType: ConsultationNotificationType.newRequest,
      );

      return consultationId;
    } catch (e) {
      print('Error creating scheduled consultation: $e');
      return null;
    }
  }

  // Doctor accepts consultation
  static Future<bool> acceptConsultation(String consultationId, String doctorId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final consultationRef = _firestore.collection('consultations').doc(consultationId);
        final consultationDoc = await transaction.get(consultationRef);

        if (!consultationDoc.exists) {
          throw Exception('Consultation not found');
        }

        final consultation = ConsultationRequest.fromMap(
          consultationDoc.data()!,
          consultationDoc.id,
        );

        if (consultation.status != ConsultationStatus.pending &&
            consultation.status != ConsultationStatus.waitingForDoctor) {
          throw Exception('Consultation cannot be accepted in current status');
        }

        if (consultation.isExpired) {
          throw Exception('Consultation request has expired');
        }

        // Generate ZegoCloud call ID
        final zegoCallId = 'call_${DateTime.now().millisecondsSinceEpoch}';

        // Update consultation
        transaction.update(consultationRef, {
          'doctorId': doctorId,
          'status': ConsultationStatus.accepted.toString().split('.').last.toUpperCase(),
          'acceptedAt': FieldValue.serverTimestamp(),
          'zegoCallId': zegoCallId,
        });

        // For instant consultations, deduct fee from wallet
        if (consultation.type == ConsultationType.instant) {
          // This will be handled separately to avoid transaction conflicts
          _deductInstantConsultationFee(consultation.parentId, consultation.fee, consultationId);
        }

        // Send push notification to parent
        await NotificationService.sendConsultationNotification(
          doctorId: doctorId,
          parentId: consultation.parentId,
          consultationId: consultationId,
          notificationType: ConsultationNotificationType.accepted,
        );

        return true;
      });
    } catch (e) {
      print('Error accepting consultation: $e');
      return false;
    }
  }

  // Doctor rejects consultation
  static Future<bool> rejectConsultation(
    String consultationId, 
    String doctorId, 
    String reason,
  ) async {
    try {
      await _firestore.collection('consultations').doc(consultationId).update({
        'status': ConsultationStatus.rejected.toString().split('.').last.toUpperCase(),
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // For scheduled consultations, refund the fee
      final consultationDoc = await _firestore
          .collection('consultations')
          .doc(consultationId)
          .get();

      String? parentIdForNotification;
      if (consultationDoc.exists) {
        final consultation = ConsultationRequest.fromMap(
          consultationDoc.data()!,
          consultationDoc.id,
        );
        
        parentIdForNotification = consultation.parentId;

        if (consultation.type == ConsultationType.scheduled) {
          await WalletService.addRefund(
            consultation.parentId,
            consultation.fee,
            'Refund for rejected consultation',
            referenceId: consultationId,
          );
        }
      }

      // Send push notification to parent
      if (parentIdForNotification != null) {
        await NotificationService.sendConsultationNotification(
          doctorId: doctorId,
          parentId: parentIdForNotification,
          consultationId: consultationId,
          notificationType: ConsultationNotificationType.rejected,
        );
      }

      return true;
    } catch (e) {
      print('Error rejecting consultation: $e');
      return false;
    }
  }

  // Start consultation call
  static Future<bool> startConsultation(String consultationId) async {
    try {
      await _firestore.collection('consultations').doc(consultationId).update({
        'status': ConsultationStatus.inProgress.toString().split('.').last.toUpperCase(),
        'startedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error starting consultation: $e');
      return false;
    }
  }

  // Complete consultation
  static Future<bool> completeConsultation(String consultationId) async {
    try {
      await _firestore.collection('consultations').doc(consultationId).update({
        'status': ConsultationStatus.completed.toString().split('.').last.toUpperCase(),
        'completedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error completing consultation: $e');
      return false;
    }
  }

  // Cancel consultation
  static Future<bool> cancelConsultation(String consultationId, String reason) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final consultationRef = _firestore.collection('consultations').doc(consultationId);
        final consultationDoc = await transaction.get(consultationRef);

        if (!consultationDoc.exists) {
          throw Exception('Consultation not found');
        }

        final consultation = ConsultationRequest.fromMap(
          consultationDoc.data()!,
          consultationDoc.id,
        );

        // Update status
        transaction.update(consultationRef, {
          'status': ConsultationStatus.cancelled.toString().split('.').last.toUpperCase(),
          'cancellationReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        // Process refund if applicable
        if (consultation.status == ConsultationStatus.scheduled ||
            consultation.status == ConsultationStatus.accepted) {
          // Calculate refund amount (could be partial based on cancellation policy)
          final refundAmount = consultation.fee * 0.8; // 80% refund
          
          await WalletService.addRefund(
            consultation.parentId,
            refundAmount,
            'Refund for cancelled consultation',
            referenceId: consultationId,
          );
        }

        return true;
      });
    } catch (e) {
      print('Error cancelling consultation: $e');
      return false;
    }
  }

  // Get consultation by ID
  static Future<ConsultationRequest?> getConsultation(String consultationId) async {
    try {
      final doc = await _firestore
          .collection('consultations')
          .doc(consultationId)
          .get();

      if (doc.exists) {
        return ConsultationRequest.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting consultation: $e');
      return null;
    }
  }

  // Get user's consultations
  static Stream<List<ConsultationRequest>> getUserConsultations(String userId) {
    return _firestore
        .collection('consultations')
        .where('parentId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConsultationRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get doctor's consultations
  static Stream<List<ConsultationRequest>> getDoctorConsultations(String doctorId) {
    return _firestore
        .collection('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('requestedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConsultationRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get pending consultations for doctor
  static Stream<List<ConsultationRequest>> getPendingConsultationsForDoctor(String doctorId) {
    return _firestore
        .collection('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', whereIn: [
          ConsultationStatus.pending.toString().split('.').last.toUpperCase(),
          ConsultationStatus.waitingForDoctor.toString().split('.').last.toUpperCase(),
        ])
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConsultationRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Private helper methods
  static Future<void> _notifyDoctor(String doctorId, String consultationId) async {
    // Create notification for doctor
    await _firestore
        .collection('notifications')
        .doc('${doctorId}_${DateTime.now().millisecondsSinceEpoch}')
        .set({
      'userId': doctorId,
      'type': 'consultation_request',
      'title': 'New Consultation Request',
      'body': 'You have a new consultation request',
      'consultationId': consultationId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _notifyAvailableDoctors(String consultationId) async {
    // Get all active online doctors
    final doctorsSnapshot = await _firestore
        .collection('doctors')
        .where('isActive', isEqualTo: true)
        .where('isOnline', isEqualTo: true)
        .get();

    // Notify all available doctors
    for (final doc in doctorsSnapshot.docs) {
      await _notifyDoctor(doc.id, consultationId);
    }
  }

  static Future<bool> _checkDoctorAvailability(String doctorId, DateTime scheduledTime) async {
    // Check if doctor has any existing appointments at this time
    final existingConsultations = await _firestore
        .collection('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .where('scheduledTime', isGreaterThanOrEqualTo: 
            Timestamp.fromDate(scheduledTime.subtract(const Duration(minutes: 30))))
        .where('scheduledTime', isLessThanOrEqualTo: 
            Timestamp.fromDate(scheduledTime.add(const Duration(minutes: 30))))
        .where('status', whereIn: [
          ConsultationStatus.scheduled.toString().split('.').last.toUpperCase(),
          ConsultationStatus.accepted.toString().split('.').last.toUpperCase(),
        ])
        .get();

    return existingConsultations.docs.isEmpty;
  }

  static Future<void> _reserveTimeSlot(String doctorId, DateTime scheduledTime, String consultationId) async {
    // Create a time slot reservation
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('reservedSlots')
        .doc(consultationId)
        .set({
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'consultationId': consultationId,
      'reservedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _deductInstantConsultationFee(String parentId, double fee, String consultationId) async {
    await WalletService.deductFromWallet(
      parentId,
      fee,
      'Instant consultation fee',
      referenceId: consultationId,
    );
  }

  // Get available time slots for a doctor
  static Future<List<DateTime>> getAvailableTimeSlots(
    String doctorId, 
    DateTime date,
  ) async {
    try {
      // Get doctor's availability
      final doctorDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) return [];

      final doctor = Doctor.fromMap(doctorDoc.data()!, doctorDoc.id);
      final dayName = _getDayName(date.weekday);
      final availableSlots = doctor.availability[dayName] ?? [];

      // Get existing bookings for this date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingBookings = await _firestore
          .collection('consultations')
          .where('doctorId', isEqualTo: doctorId)
          .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: [
            ConsultationStatus.scheduled.toString().split('.').last.toUpperCase(),
            ConsultationStatus.accepted.toString().split('.').last.toUpperCase(),
          ])
          .get();

      final bookedTimes = existingBookings.docs
          .map((doc) => (doc.data()['scheduledTime'] as Timestamp).toDate())
          .toList();

      // Convert available slots to DateTime and filter out booked ones
      final availableTimes = <DateTime>[];
      for (final slot in availableSlots) {
        final timeParts = slot.split(':');
        final slotTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        // Check if this slot is not booked and is in the future
        if (slotTime.isAfter(DateTime.now()) &&
            !bookedTimes.any((booked) => 
                booked.difference(slotTime).abs().inMinutes < 30)) {
          availableTimes.add(slotTime);
        }
      }

      return availableTimes;
    } catch (e) {
      print('Error getting available time slots: $e');
      return [];
    }
  }

  static String _getDayName(int weekday) {
    const days = [
      'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday'
    ];
    return days[weekday - 1];
  }

  // Clean up expired consultations
  static Future<void> cleanupExpiredConsultations() async {
    try {
      final expiredConsultations = await _firestore
          .collection('consultations')
          .where('expiresAt', isLessThan: Timestamp.fromDate(DateTime.now()))
          .where('status', isEqualTo: 
              ConsultationStatus.pending.toString().split('.').last.toUpperCase())
          .get();

      for (final doc in expiredConsultations.docs) {
        await doc.reference.update({
          'status': ConsultationStatus.cancelled.toString().split('.').last.toUpperCase(),
          'cancellationReason': 'Expired - no doctor response',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error cleaning up expired consultations: $e');
    }
  }
}