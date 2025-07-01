import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender {
  male,
  female,
  other,
}

class Child {
  final String id;
  final String parentId;
  final String name;
  final DateTime dateOfBirth;
  final Gender gender;
  final String? bloodGroup;
  final double? height; // in cm
  final double? weight; // in kg
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? photoUrl;
  final List<String> medicalHistory;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Child({
    required this.id,
    required this.parentId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.bloodGroup,
    this.height,
    this.weight,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.photoUrl,
    this.medicalHistory = const [],
    this.notes = '',
    required this.createdAt,
    this.updatedAt,
  });

  factory Child.fromMap(Map<String, dynamic> map, String id) {
    return Child(
      id: id,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      dateOfBirth:
          (map['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gender: Gender.values.firstWhere(
        (gender) =>
            gender.toString().split('.').last == map['gender']?.toLowerCase(),
        orElse: () => Gender.male,
      ),
      bloodGroup: map['bloodGroup'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      allergies: List<String>.from(map['allergies'] ?? []),
      chronicConditions: List<String>.from(map['chronicConditions'] ?? []),
      medicalHistory: List<String>.from(map['medicalHistory'] ?? []),
      notes: map['notes'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'name': name,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender.toString().split('.').last.toUpperCase(),
      'bloodGroup': bloodGroup,
      'height': height,
      'weight': weight,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'medicalHistory': medicalHistory,
      'notes': notes,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // JSON compatibility
  Map<String, dynamic> toJson() => toMap();

  // JSON convenience
  factory Child.fromJson(Map<String, dynamic> json) =>
      Child.fromMap(json, json['id'] ?? '');

  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  int get ageInMonths {
    final now = DateTime.now();
    int months =
        (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
    if (now.day < dateOfBirth.day) {
      months--;
    }
    return months;
  }

  String get formattedAge {
    final years = ageInYears;
    final months = ageInMonths % 12;

    if (years == 0) {
      return '$months month${months != 1 ? 's' : ''}';
    } else if (months == 0) {
      return '$years year${years != 1 ? 's' : ''}';
    } else {
      return '$years year${years != 1 ? 's' : ''}, $months month${months != 1 ? 's' : ''}';
    }
  }

  String get genderDisplayName {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  bool get hasAllergies => allergies.isNotEmpty;
  bool get hasChronicConditions => chronicConditions.isNotEmpty;
  bool get hasMedicalInfo => hasAllergies || hasChronicConditions;

  Child copyWith({
    String? name,
    DateTime? dateOfBirth,
    Gender? gender,
    String? bloodGroup,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? chronicConditions,
    List<String>? medicalHistory,
    String? notes,
    String? photoUrl,
  }) {
    return Child(
      id: id,
      parentId: parentId,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Child(id: $id, name: $name, age: $formattedAge, gender: $genderDisplayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Child && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Legacy type alias for backward compatibility
typedef ChildModel = Child;

// Legacy getters extension for backward compatibility
extension ChildLegacyFields on Child {
  // Some old code expected an `age` getter; map it to ageInYears
  int get age => ageInYears;
}
