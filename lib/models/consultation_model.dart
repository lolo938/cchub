import 'package:cloud_firestore/cloud_firestore.dart';

enum ConsultationType {
  instant,
  scheduled,
  emergency,
  video,
  chat,
}

enum ConsultationStatus {
  pending,
  waitingForDoctor,
  accepted,
  rejected,
  scheduled,
  inProgress,
  completed,
  cancelled,
}

class ConsultationRequest {
  final String id;
  final ConsultationType type;
  final String parentId;
  final String childId;
  final String? doctorId;
  final String childName;
  final int childAge;
  final ConsultationStatus status;
  final double fee;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? scheduledTime;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;
  final String? zegoCallId;

  ConsultationRequest({
    required this.id,
    required this.type,
    required this.parentId,
    required this.childId,
    this.doctorId,
    required this.childName,
    required this.childAge,
    required this.status,
    required this.fee,
    required this.requestedAt,
    this.acceptedAt,
    this.scheduledTime,
    this.completedAt,
    this.expiresAt,
    this.rejectionReason,
    this.zegoCallId,
  });

  factory ConsultationRequest.fromMap(Map<String, dynamic> map, String id) {
    return ConsultationRequest(
      id: id,
      type: ConsultationType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type']?.toLowerCase(),
        orElse: () => ConsultationType.instant,
      ),
      parentId: map['parentId'] ?? '',
      childId: map['childId'] ?? '',
      doctorId: map['doctorId'],
      childName: map['childName'] ?? '',
      childAge: map['childAge'] ?? 0,
      status: ConsultationStatus.values.firstWhere(
        (status) =>
            status.toString().split('.').last == map['status']?.toLowerCase(),
        orElse: () => ConsultationStatus.pending,
      ),
      fee: (map['fee'] ?? 0).toDouble(),
      requestedAt:
          (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      scheduledTime: (map['scheduledTime'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'],
      zegoCallId: map['zegoCallId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last.toUpperCase(),
      'parentId': parentId,
      'childId': childId,
      'doctorId': doctorId,
      'childName': childName,
      'childAge': childAge,
      'status': status.toString().split('.').last.toUpperCase(),
      'fee': fee,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'scheduledTime':
          scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'rejectionReason': rejectionReason,
      'zegoCallId': zegoCallId,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case ConsultationType.instant:
        return 'Instant';
      case ConsultationType.scheduled:
        return 'Scheduled';
      case ConsultationType.emergency:
        return 'Emergency';
      case ConsultationType.video:
        return 'Video';
      case ConsultationType.chat:
        return 'Chat';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ConsultationStatus.pending:
        return 'Pending';
      case ConsultationStatus.waitingForDoctor:
        return 'Waiting for Doctor';
      case ConsultationStatus.accepted:
        return 'Accepted';
      case ConsultationStatus.rejected:
        return 'Rejected';
      case ConsultationStatus.scheduled:
        return 'Scheduled';
      case ConsultationStatus.inProgress:
        return 'In Progress';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get canJoinCall {
    return status == ConsultationStatus.accepted &&
        zegoCallId != null &&
        !isExpired;
  }

  bool get isActive {
    return [
      ConsultationStatus.pending,
      ConsultationStatus.waitingForDoctor,
      ConsultationStatus.accepted,
      ConsultationStatus.scheduled,
      ConsultationStatus.inProgress,
    ].contains(status);
  }

  ConsultationRequest copyWith({
    ConsultationType? type,
    String? doctorId,
    ConsultationStatus? status,
    DateTime? acceptedAt,
    DateTime? scheduledTime,
    DateTime? completedAt,
    String? rejectionReason,
    String? zegoCallId,
  }) {
    return ConsultationRequest(
      id: id,
      type: type ?? this.type,
      parentId: parentId,
      childId: childId,
      doctorId: doctorId ?? this.doctorId,
      childName: childName,
      childAge: childAge,
      status: status ?? this.status,
      fee: fee,
      requestedAt: requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      zegoCallId: zegoCallId ?? this.zegoCallId,
    );
  }

  @override
  String toString() {
    return 'ConsultationRequest(id: $id, type: $typeDisplayName, status: $statusDisplayName, childName: $childName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsultationRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Legacy type alias for backward compatibility
typedef ConsultationModel = ConsultationRequest;

// Legacy getters for compatibility with older UI code
extension ConsultationLegacyFields on ConsultationRequest {
  DateTime get dateTime => scheduledTime ?? requestedAt;
  double get consultationFee => fee;
  List<String> get chiefComplaints => [];
}
