import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String photoUrl;
  final String designation;
  final String registrationNumber;
  final String state;
  final List<String> languagesSpoken;
  final String specialization;
  final int yearsOfExperience;
  final String? about;
  final double consultationFee;
  final double rating;
  final int totalConsultations;
  final bool isActive;
  final bool isOnline;
  final Map<String, List<String>> availability;
  final DateTime createdAt;
  final String? createdBy;

  Doctor({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.designation,
    required this.registrationNumber,
    required this.state,
    required this.languagesSpoken,
    required this.specialization,
    required this.yearsOfExperience,
    this.about,
    required this.consultationFee,
    this.rating = 0.0,
    this.totalConsultations = 0,
    this.isActive = true,
    this.isOnline = false,
    required this.availability,
    required this.createdAt,
    this.createdBy,
  });

  factory Doctor.fromMap(Map<String, dynamic> map, String id) {
    return Doctor(
      id: id,
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      designation: map['designation'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      state: map['state'] ?? '',
      languagesSpoken: List<String>.from(map['languagesSpoken'] ?? []),
      specialization: map['specialization'] ?? '',
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      about: map['about'],
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalConsultations: map['totalConsultations'] ?? 0,
      isActive: map['isActive'] ?? true,
      isOnline: map['isOnline'] ?? false,
      availability: Map<String, List<String>>.from(
        map['availability']?.map(
                (key, value) => MapEntry(key, List<String>.from(value))) ??
            {},
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'designation': designation,
      'registrationNumber': registrationNumber,
      'state': state,
      'languagesSpoken': languagesSpoken,
      'specialization': specialization,
      'yearsOfExperience': yearsOfExperience,
      'about': about,
      'consultationFee': consultationFee,
      'rating': rating,
      'totalConsultations': totalConsultations,
      'isActive': isActive,
      'isOnline': isOnline,
      'availability': availability,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  bool get isAvailableNow {
    if (!isActive || !isOnline) return false;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final todaySlots = availability[dayName] ?? [];

    for (final slot in todaySlots) {
      if (_isTimeInSlot(currentTime, slot)) {
        return true;
      }
    }

    return false;
  }

  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[weekday - 1];
  }

  bool _isTimeInSlot(String currentTime, String slot) {
    // Slot format: "09:00-12:00"
    final parts = slot.split('-');
    if (parts.length != 2) return false;

    final startTime = parts[0];
    final endTime = parts[1];

    return currentTime.compareTo(startTime) >= 0 &&
        currentTime.compareTo(endTime) <= 0;
  }

  List<String> get todayAvailableSlots {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    return availability[dayName] ?? [];
  }

  bool isAvailableAt(DateTime dateTime) {
    if (!isActive || !isOnline) return false;

    final dayName = _getDayName(dateTime.weekday);
    final timeString =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    final daySlots = availability[dayName] ?? [];

    for (final slot in daySlots) {
      if (_isTimeInSlot(timeString, slot)) {
        return true;
      }
    }

    return false;
  }

  Doctor copyWith({
    String? name,
    String? photoUrl,
    String? designation,
    String? registrationNumber,
    String? state,
    List<String>? languagesSpoken,
    String? specialization,
    int? yearsOfExperience,
    String? about,
    double? consultationFee,
    double? rating,
    int? totalConsultations,
    bool? isActive,
    bool? isOnline,
    Map<String, List<String>>? availability,
  }) {
    return Doctor(
      id: id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      designation: designation ?? this.designation,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      state: state ?? this.state,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      specialization: specialization ?? this.specialization,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      about: about ?? this.about,
      consultationFee: consultationFee ?? this.consultationFee,
      rating: rating ?? this.rating,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      availability: availability ?? this.availability,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  @override
  String toString() {
    return 'Doctor(id: $id, name: $name, specialization: $specialization, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Doctor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Legacy type alias for backward compatibility
typedef DoctorModel = Doctor;

// Legacy getters and fields for compatibility with older UI code
extension DoctorLegacyFields on Doctor {
  // Map deprecated getters to new ones or placeholders
  String get specialty => specialization;
  int get experienceYears => yearsOfExperience;
  int get totalPatients => totalConsultations;
  bool get isAvailable => isAvailableNow;
  String get hospitalName => '';
  String get hospitalAddress => '';
  bool get isFavorite => false;
  String get biography => about ?? '';
  List<String> get qualifications => [];
  List<String> get specializations => [specialization];
  List<String> get languages => languagesSpoken;
  String get nextAvailableSlot =>
      todayAvailableSlots.isNotEmpty ? todayAvailableSlots.first : '';
}
