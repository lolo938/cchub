import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_model.dart';

// All doctors provider
final allDoctorsProvider = StreamProvider<List<Doctor>>((ref) {
  return FirebaseFirestore.instance
      .collection('doctors')
      .where('isActive', isEqualTo: true)
      .orderBy('rating', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data(), doc.id))
          .toList());
});

// Online doctors provider
final onlineDoctorsProvider = StreamProvider<List<Doctor>>((ref) {
  return FirebaseFirestore.instance
      .collection('doctors')
      .where('isActive', isEqualTo: true)
      .where('isOnline', isEqualTo: true)
      .orderBy('rating', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data(), doc.id))
          .toList());
});

// Doctor by ID provider
final doctorProvider =
    FutureProvider.family<Doctor?, String>((ref, doctorId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    if (doc.exists) {
      return Doctor.fromMap(doc.data()!, doc.id);
    }
    return null;
  } catch (e) {
    print('Error fetching doctor: $e');
    return null;
  }
});

// Doctors by specialization provider
final doctorsBySpecializationProvider =
    StreamProvider.family<List<Doctor>, String>((ref, specialization) {
  return FirebaseFirestore.instance
      .collection('doctors')
      .where('isActive', isEqualTo: true)
      .where('specialization', isEqualTo: specialization)
      .orderBy('rating', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data(), doc.id))
          .toList());
});

// Search doctors provider
final searchDoctorsProvider =
    FutureProvider.family<List<Doctor>, String>((ref, query) async {
  if (query.isEmpty) return [];

  try {
    // Search by name (simple text matching - for better search, consider using Algolia)
    final nameResults = await FirebaseFirestore.instance
        .collection('doctors')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .startAt([query]).endAt([query + '\uf8ff']).get();

    // Search by specialization
    final specializationResults = await FirebaseFirestore.instance
        .collection('doctors')
        .where('isActive', isEqualTo: true)
        .where('specialization', isGreaterThanOrEqualTo: query)
        .where('specialization', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    final allResults = <Doctor>[];
    final addedIds = <String>{};

    // Add name search results
    for (final doc in nameResults.docs) {
      if (!addedIds.contains(doc.id)) {
        allResults.add(Doctor.fromMap(doc.data(), doc.id));
        addedIds.add(doc.id);
      }
    }

    // Add specialization search results
    for (final doc in specializationResults.docs) {
      if (!addedIds.contains(doc.id)) {
        allResults.add(Doctor.fromMap(doc.data(), doc.id));
        addedIds.add(doc.id);
      }
    }

    // Sort by rating
    allResults.sort((a, b) => b.rating.compareTo(a.rating));

    return allResults;
  } catch (e) {
    print('Error searching doctors: $e');
    return [];
  }
});

// Available doctors for instant consultation provider
final availableDoctorsForInstantConsultationProvider =
    StreamProvider<List<Doctor>>((ref) {
  return FirebaseFirestore.instance
      .collection('doctors')
      .where('isActive', isEqualTo: true)
      .where('isOnline', isEqualTo: true)
      .orderBy('totalConsultations',
          descending: true) // Prioritize experienced doctors
      .limit(10) // Limit for instant consultation matching
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data(), doc.id))
          .where((doctor) =>
              doctor.isAvailableNow) // Filter by current availability
          .toList());
});

// Top rated doctors provider
final topRatedDoctorsProvider = StreamProvider<List<Doctor>>((ref) {
  return FirebaseFirestore.instance
      .collection('doctors')
      .where('isActive', isEqualTo: true)
      .where('rating', isGreaterThanOrEqualTo: 4.5)
      .orderBy('rating', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data(), doc.id))
          .toList());
});

// Doctor specializations provider
final doctorSpecializationsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('isActive', isEqualTo: true)
        .get();

    final specializations = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final specialization = data['specialization'] as String?;
      if (specialization != null && specialization.isNotEmpty) {
        specializations.add(specialization);
      }
    }

    final list = specializations.toList()..sort();
    return list;
  } catch (e) {
    print('Error fetching specializations: $e');
    return [];
  }
});

// Doctor languages provider
final doctorLanguagesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('isActive', isEqualTo: true)
        .get();

    final languages = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final languagesList = data['languagesSpoken'] as List<dynamic>?;
      if (languagesList != null) {
        for (final lang in languagesList) {
          if (lang is String && lang.isNotEmpty) {
            languages.add(lang);
          }
        }
      }
    }

    final list = languages.toList()..sort();
    return list;
  } catch (e) {
    print('Error fetching languages: $e');
    return [];
  }
});

// Doctor states provider
final doctorStatesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('isActive', isEqualTo: true)
        .get();

    final states = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final state = data['state'] as String?;
      if (state != null && state.isNotEmpty) {
        states.add(state);
      }
    }

    final list = states.toList()..sort();
    return list;
  } catch (e) {
    print('Error fetching states: $e');
    return [];
  }
});

// Doctor filter provider
final doctorFilterProvider =
    StateNotifierProvider<DoctorFilterController, DoctorFilter>((ref) {
  return DoctorFilterController();
});

// Doctor filter class
class DoctorFilter {
  final String? specialization;
  final String? language;
  final String? state;
  final double? minRating;
  final double? maxFee;
  final bool onlineOnly;
  final String? searchQuery;

  const DoctorFilter({
    this.specialization,
    this.language,
    this.state,
    this.minRating,
    this.maxFee,
    this.onlineOnly = false,
    this.searchQuery,
  });

  DoctorFilter copyWith({
    String? specialization,
    String? language,
    String? state,
    double? minRating,
    double? maxFee,
    bool? onlineOnly,
    String? searchQuery,
  }) {
    return DoctorFilter(
      specialization: specialization ?? this.specialization,
      language: language ?? this.language,
      state: state ?? this.state,
      minRating: minRating ?? this.minRating,
      maxFee: maxFee ?? this.maxFee,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters {
    return specialization != null ||
        language != null ||
        state != null ||
        minRating != null ||
        maxFee != null ||
        onlineOnly ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  DoctorFilter clear() {
    return const DoctorFilter();
  }
}

// Doctor filter controller
class DoctorFilterController extends StateNotifier<DoctorFilter> {
  DoctorFilterController() : super(const DoctorFilter());

  void setSpecialization(String? specialization) {
    state = state.copyWith(specialization: specialization);
  }

  void setLanguage(String? language) {
    state = state.copyWith(language: language);
  }

  void setState(String? state) {
    this.state = this.state.copyWith(state: state);
  }

  void setMinRating(double? minRating) {
    state = state.copyWith(minRating: minRating);
  }

  void setMaxFee(double? maxFee) {
    state = state.copyWith(maxFee: maxFee);
  }

  void setOnlineOnly(bool onlineOnly) {
    state = state.copyWith(onlineOnly: onlineOnly);
  }

  void setSearchQuery(String? searchQuery) {
    state = state.copyWith(searchQuery: searchQuery);
  }

  void clearFilters() {
    state = const DoctorFilter();
  }
}

// Filtered doctors provider
final filteredDoctorsProvider = StreamProvider<List<Doctor>>((ref) {
  final filter = ref.watch(doctorFilterProvider);

  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection('doctors')
      .where('isActive', isEqualTo: true);

  // Apply filters
  if (filter.specialization != null) {
    query = query.where('specialization', isEqualTo: filter.specialization);
  }

  if (filter.state != null) {
    query = query.where('state', isEqualTo: filter.state);
  }

  if (filter.onlineOnly) {
    query = query.where('isOnline', isEqualTo: true);
  }

  // Order by rating (descending)
  query = query.orderBy('rating', descending: true);

  return query.snapshots().map((snapshot) {
    var doctors =
        snapshot.docs.map((doc) => Doctor.fromMap(doc.data(), doc.id)).toList();

    // Apply client-side filters
    if (filter.language != null) {
      doctors = doctors
          .where((doctor) => doctor.languagesSpoken.contains(filter.language))
          .toList();
    }

    if (filter.minRating != null) {
      doctors = doctors
          .where((doctor) => doctor.rating >= filter.minRating!)
          .toList();
    }

    if (filter.maxFee != null) {
      doctors = doctors
          .where((doctor) => doctor.consultationFee <= filter.maxFee!)
          .toList();
    }

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      doctors = doctors.where((doctor) {
        return doctor.name.toLowerCase().contains(query) ||
            doctor.specialization.toLowerCase().contains(query) ||
            doctor.designation.toLowerCase().contains(query);
      }).toList();
    }

    return doctors;
  });
});

// Doctor marquee provider - for home screen marquee
final doctorMarqueeProvider = StreamProvider<List<Doctor>>((ref) {
  return FirebaseFirestore.instance
      .collection('doctors')
      .where('isActive', isEqualTo: true)
      .orderBy('rating', descending: true)
      .limit(5) // Top 5 doctors for marquee
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data(), doc.id))
          .toList());
});

// Doctor availability checker provider
final doctorAvailabilityProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final doctorId = params['doctorId'] as String;
  final dateTime = params['dateTime'] as DateTime;

  try {
    final doctor = await ref.watch(doctorProvider(doctorId).future);
    if (doctor == null) return false;

    return doctor.isAvailableAt(dateTime);
  } catch (e) {
    print('Error checking doctor availability: $e');
    return false;
  }
});

// Doctor stats provider
final doctorStatsProvider =
    Provider.family<Map<String, dynamic>, List<Doctor>>((ref, doctors) {
  final stats = <String, dynamic>{
    'totalDoctors': doctors.length,
    'onlineDoctors': doctors.where((d) => d.isOnline).length,
    'specializations': <String>{},
    'averageRating': 0.0,
    'averageFee': 0.0,
    'topRatedDoctors': <Doctor>[],
  };

  if (doctors.isEmpty) return stats;

  // Calculate averages
  double totalRating = 0;
  double totalFee = 0;
  final specializations = <String>{};

  for (final doctor in doctors) {
    totalRating += doctor.rating;
    totalFee += doctor.consultationFee;
    specializations.add(doctor.specialization);
  }

  stats['averageRating'] = totalRating / doctors.length;
  stats['averageFee'] = totalFee / doctors.length;
  stats['specializations'] = specializations.toList();

  // Top rated doctors (rating >= 4.5)
  final topRated = doctors.where((d) => d.rating >= 4.5).toList();
  topRated.sort((a, b) => b.rating.compareTo(a.rating));
  stats['topRatedDoctors'] = topRated.take(5).toList();

  return stats;
});

// Legacy no-op notifier and extension for backward compatibility with `.notifier` on FutureProviderFamily
class _DoctorNoopNotifier {
  Future<void> loadDoctors() async {}
}

extension DoctorFutureProviderLegacy on FutureProviderFamily<Doctor?, String> {
  _DoctorNoopNotifier get notifier => _DoctorNoopNotifier();
  List<Doctor> get doctors => [];
}
