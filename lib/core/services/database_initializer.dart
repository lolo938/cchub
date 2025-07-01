import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<void> initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool('db_initialized') ?? false;
    
    if (!isInitialized) {
      print('🔥 Initializing Firestore database structure...');
      
      try {
        await _createDummyDoctors();
        await _createAppConfig();
        await _createFeeStructures();
        await _createSampleUser();
        
        await prefs.setBool('db_initialized', true);
        print('✅ Database initialization complete!');
      } catch (e) {
        print('❌ Error initializing database: $e');
      }
    } else {
      print('ℹ️ Database already initialized');
    }
  }
  
  static Future<void> _createDummyDoctors() async {
    final doctors = [
      {
        'id': 'doc_001',
        'name': 'Dr. Priya Sharma',
        'photoUrl': 'https://ui-avatars.com/api/?name=Priya+Sharma&background=4F46E5&color=fff&size=200',
        'designation': 'MBBS, MD Pediatrics',
        'registrationNumber': 'MH/2019/12345',
        'state': 'Maharashtra',
        'languagesSpoken': ['English', 'Hindi', 'Marathi'],
        'specialization': 'General Pediatrics',
        'yearsOfExperience': 12,
        'about': 'Specialized in child healthcare with over 12 years of experience in treating various pediatric conditions.',
        'consultationFee': 500.0,
        'rating': 4.8,
        'totalConsultations': 245,
        'isActive': true,
        'isOnline': true,
        'availability': {
          'monday': ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
          'tuesday': ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
          'wednesday': ['09:00', '10:00', '11:00'],
          'thursday': ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
          'friday': ['09:00', '10:00', '11:00', '14:00', '15:00'],
          'saturday': ['09:00', '10:00', '11:00', '12:00'],
        },
      },
      {
        'id': 'doc_002',
        'name': 'Dr. Rajesh Kumar',
        'photoUrl': 'https://ui-avatars.com/api/?name=Rajesh+Kumar&background=10B981&color=fff&size=200',
        'designation': 'MBBS, DCH',
        'registrationNumber': 'DL/2018/23456',
        'state': 'Delhi',
        'languagesSpoken': ['English', 'Hindi', 'Punjabi'],
        'specialization': 'Neonatology',
        'yearsOfExperience': 8,
        'about': 'Expert in newborn care and neonatal intensive care with focus on premature babies.',
        'consultationFee': 700.0,
        'rating': 4.9,
        'totalConsultations': 189,
        'isActive': true,
        'isOnline': false,
        'availability': {
          'monday': ['10:00', '11:00', '15:00', '16:00', '17:00'],
          'tuesday': ['10:00', '11:00', '15:00', '16:00', '17:00'],
          'wednesday': ['10:00', '11:00'],
          'thursday': ['10:00', '11:00', '15:00', '16:00', '17:00'],
          'friday': ['10:00', '11:00'],
          'sunday': ['10:00', '11:00', '12:00'],
        },
      },
      {
        'id': 'doc_003',
        'name': 'Dr. Fatima Sheikh',
        'photoUrl': 'https://ui-avatars.com/api/?name=Fatima+Sheikh&background=F59E0B&color=fff&size=200',
        'designation': 'MBBS, MD Pediatrics, Fellowship in Pediatric Cardiology',
        'registrationNumber': 'KA/2020/34567',
        'state': 'Karnataka',
        'languagesSpoken': ['English', 'Hindi', 'Urdu', 'Kannada'],
        'specialization': 'Pediatric Cardiology',
        'yearsOfExperience': 15,
        'about': 'Specialized in pediatric heart conditions and cardiac care for children.',
        'consultationFee': 1000.0,
        'rating': 4.7,
        'totalConsultations': 412,
        'isActive': true,
        'isOnline': true,
        'availability': {
          'tuesday': ['11:00', '14:00', '16:00', '17:00'],
          'wednesday': ['11:00', '14:00'],
          'thursday': ['11:00', '14:00', '16:00', '17:00'],
          'friday': ['11:00', '14:00'],
          'saturday': ['10:00', '11:00', '12:00', '13:00'],
        },
      },
      {
        'id': 'doc_004',
        'name': 'Dr. Anita Patel',
        'photoUrl': 'https://ui-avatars.com/api/?name=Anita+Patel&background=EC4899&color=fff&size=200',
        'designation': 'MBBS, DNB Pediatrics',
        'registrationNumber': 'GJ/2021/45678',
        'state': 'Gujarat',
        'languagesSpoken': ['English', 'Hindi', 'Gujarati'],
        'specialization': 'Developmental Pediatrics',
        'yearsOfExperience': 6,
        'about': 'Focus on child development, behavioral issues and autism spectrum disorders.',
        'consultationFee': 600.0,
        'rating': 4.6,
        'totalConsultations': 156,
        'isActive': true,
        'isOnline': true,
        'availability': {
          'monday': ['09:00', '10:00', '14:00', '15:00', '16:00'],
          'tuesday': ['09:00', '10:00'],
          'wednesday': ['09:00', '10:00', '14:00', '15:00', '16:00'],
          'thursday': ['09:00', '10:00', '14:00', '15:00', '16:00'],
          'friday': ['09:00', '10:00'],
          'saturday': ['09:00', '10:00', '11:00'],
        },
      },
      {
        'id': 'doc_005',
        'name': 'Dr. Suresh Menon',
        'photoUrl': 'https://ui-avatars.com/api/?name=Suresh+Menon&background=6366F1&color=fff&size=200',
        'designation': 'MBBS, MD Pediatrics, DM Pediatric Neurology',
        'registrationNumber': 'TN/2017/56789',
        'state': 'Tamil Nadu',
        'languagesSpoken': ['English', 'Hindi', 'Tamil', 'Malayalam'],
        'specialization': 'Pediatric Neurology',
        'yearsOfExperience': 18,
        'about': 'Expert in childhood neurological disorders, epilepsy and developmental delays.',
        'consultationFee': 1200.0,
        'rating': 4.9,
        'totalConsultations': 534,
        'isActive': true,
        'isOnline': false,
        'availability': {
          'monday': ['10:00', '11:00', '12:00'],
          'wednesday': ['10:00', '11:00', '15:00', '16:00', '17:00'],
          'thursday': ['10:00', '11:00', '12:00'],
          'friday': ['10:00', '11:00', '15:00', '16:00', '17:00'],
          'saturday': ['10:00', '11:00', '12:00', '13:00'],
        },
      }
    ];

    for (final doctor in doctors) {
      await _firestore
          .collection('doctors')
          .doc(doctor['id'] as String)
          .set({
        ...doctor,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system_initializer',
        '_isDummyData': true,
      });
      print('✅ Created dummy doctor: ${doctor['name']}');
    }
  }

  static Future<void> _createAppConfig() async {
    await _firestore
        .collection('appConfig')
        .doc('settings')
        .set({
      'appName': 'ChildcareHub',
      'tagline': 'Pediatric Care Made Simple',
      'supportPhone': '+91-9876543210',
      'supportEmail': 'support@childcarehub.com',
      'instantConsultationEnabled': true,
      'scheduledConsultationEnabled': true,
      'emergencyConsultationEnabled': true,
      'walletEnabled': true,
      'videoCallEnabled': true,
      'chatEnabled': true,
      'marqueeEnabled': true,
      'marqueeSpeed': 50.0,
      'primaryColor': '#2196F3',
      'secondaryColor': '#FF5722',
      'welcomeMessage': 'Welcome to ChildcareHub - Your trusted pediatric care partner',
      'version': '1.0.0',
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('appConfig')
        .doc('consultationTypes')
        .set({
      'instant': {
        'enabled': true,
        'title': 'Instant Consultation',
        'subtitle': 'Connect with available doctor now',
        'baseFee': 600.0,
        'color': '#FF5722',
        'icon': 'emergency',
        'description': 'Get immediate medical consultation for urgent pediatric concerns',
        'timeoutMinutes': 10,
      },
      'scheduled': {
        'enabled': true,
        'title': 'Book Appointment',
        'subtitle': 'Schedule with specific doctor',
        'baseFee': 500.0,
        'color': '#2196F3',
        'icon': 'calendar_today',
        'description': 'Book scheduled consultation with your preferred pediatrician',
        'advanceBookingDays': 30,
      },
      'emergency': {
        'enabled': false,
        'title': 'Emergency Consultation',
        'subtitle': 'Urgent medical attention',
        'baseFee': 1500.0,
        'color': '#F44336',
        'icon': 'local_hospital',
        'description': 'Immediate emergency consultation for critical situations',
        'timeoutMinutes': 5,
      },
    });

    print('✅ Created app configuration');
  }

  static Future<void> _createFeeStructures() async {
    await _firestore
        .collection('appConfig')
        .doc('feeStructures')
        .set({
      'platformSettings': {
        'platformFeePercentage': 10.0,
        'taxPercentage': 18.0,
        'emergencyFeeMultiplier': 2.0,
        'minWalletTopup': 100.0,
        'maxWalletTopup': 10000.0,
        'consultationDurationMinutes': 30,
        'refundPolicyDays': 7,
      },
      'specializationFees': {
        'General Pediatrics': 500.0,
        'Neonatology': 700.0,
        'Pediatric Cardiology': 1000.0,
        'Pediatric Neurology': 1200.0,
        'Developmental Pediatrics': 600.0,
        'Pediatric Surgery': 1500.0,
        'Pediatric Oncology': 1800.0,
      },
      'timeBasedMultipliers': {
        'normalHours': 1.0,
        'eveningHours': 1.2,
        'nightHours': 1.5,
        'weekendMultiplier': 1.3,
        'holidayMultiplier': 1.5,
      },
      'paymentMethods': {
        'wallet': {
          'enabled': true,
          'processingFee': 0.0,
        },
        'upi': {
          'enabled': true,
          'processingFee': 2.0,
        },
        'netBanking': {
          'enabled': true,
          'processingFee': 5.0,
        },
        'card': {
          'enabled': true,
          'processingFee': 3.0,
        },
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    print('✅ Created fee structures');
  }

  static Future<void> _createSampleUser() async {
    // Create a sample parent user for testing
    const sampleUserId = 'sample_parent_123';
    
    await _firestore
        .collection('users')
        .doc(sampleUserId)
        .set({
      'name': 'Sample Parent',
      'email': 'parent@example.com',
      'phone': '+919876543210',
      'role': 'PARENT',
      'photoUrl': 'https://ui-avatars.com/api/?name=Sample+Parent&background=2196F3&color=fff&size=200',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      '_isSampleData': true,
    });

    // Create wallet for sample user
    await _firestore
        .collection('users')
        .doc(sampleUserId)
        .collection('wallet')
        .doc('info')
        .set({
      'balance': 1500.0,
      'currency': 'INR',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Create sample child
    await _firestore
        .collection('users')
        .doc(sampleUserId)
        .collection('children')
        .doc('sample_child_123')
        .set({
      'parentId': sampleUserId,
      'name': 'Sample Child',
      'dateOfBirth': Timestamp.fromDate(DateTime(2020, 5, 15)),
      'gender': 'MALE',
      'bloodGroup': 'O+',
      'height': 110.5,
      'weight': 18.5,
      'allergies': ['Peanuts'],
      'chronicConditions': [],
      'photoUrl': 'https://ui-avatars.com/api/?name=Sample+Child&background=4CAF50&color=fff&size=200',
      'createdAt': FieldValue.serverTimestamp(),
      '_isSampleData': true,
    });

    print('✅ Created sample user and child data');
  }

  static Future<void> _createSystemNotifications() async {
    await _firestore
        .collection('systemNotifications')
        .doc('welcome')
        .set({
      'title': 'Welcome to ChildcareHub!',
      'body': 'Your trusted partner for pediatric healthcare. Start by adding your child\'s profile.',
      'type': 'welcome',
      'isActive': true,
      'priority': 'high',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('systemNotifications')
        .doc('first_consultation')
        .set({
      'title': 'Book Your First Consultation',
      'body': 'Connect with expert pediatricians instantly or schedule an appointment.',
      'type': 'promotion',
      'isActive': true,
      'priority': 'medium',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ Created system notifications');
  }

  static Future<void> resetDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('db_initialized', false);
    print('🔄 Database reset flag cleared. Will reinitialize on next app start.');
  }
}