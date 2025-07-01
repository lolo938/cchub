import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration service
/// Manages environment variables and app configuration
class EnvConfig {
  static Future<void> initialize({String? environment}) async {
    String envFile = '.env';
    
    if (environment != null) {
      envFile = '.env.$environment';
    }
    
    try {
      await dotenv.load(fileName: envFile);
    } catch (e) {
      // Fallback to default .env if specific environment file not found
      await dotenv.load(fileName: '.env');
    }
  }
  
  // App Configuration
  static String get appName => dotenv.get('APP_NAME', fallback: 'ChildcareHub');
  static String get appVersion => dotenv.get('APP_VERSION', fallback: '1.0.0');
  static String get environment => dotenv.get('ENVIRONMENT', fallback: 'development');
  
  // Firebase Configuration
  static String get firebaseApiKey => dotenv.get('FIREBASE_API_KEY', fallback: '');
  static String get firebaseAppId => dotenv.get('FIREBASE_APP_ID', fallback: '');
  static String get firebaseMessagingSenderId => dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '');
  static String get firebaseProjectId => dotenv.get('FIREBASE_PROJECT_ID', fallback: '');
  static String get firebaseAuthDomain => dotenv.get('FIREBASE_AUTH_DOMAIN', fallback: '');
  static String get firebaseStorageBucket => dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: '');
  static String get firebaseMeasurementId => dotenv.get('FIREBASE_MEASUREMENT_ID', fallback: '');
  
  // Firebase Platform-specific IDs
  static String get firebaseAndroidAppId => dotenv.get('FIREBASE_ANDROID_APP_ID', fallback: '');
  static String get firebaseIosAppId => dotenv.get('FIREBASE_IOS_APP_ID', fallback: '');
  static String get firebaseIosBundleId => dotenv.get('FIREBASE_IOS_BUNDLE_ID', fallback: '');
  
  // ZegoCloud Configuration
  static String get zegoAppId => dotenv.get('ZEGO_APP_ID', fallback: '');
  static String get zegoAppSign => dotenv.get('ZEGO_APP_SIGN', fallback: '');
  
  // API Configuration
  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: 'https://api.childcarehub.com');
  static int get apiTimeout => int.tryParse(dotenv.get('API_TIMEOUT', fallback: '30000')) ?? 30000;
  
  // Feature Flags
  static bool get enableAnalytics => dotenv.get('ENABLE_ANALYTICS', fallback: 'true').toLowerCase() == 'true';
  static bool get enableCrashReporting => dotenv.get('ENABLE_CRASH_REPORTING', fallback: 'true').toLowerCase() == 'true';
  static bool get enablePerformanceMonitoring => dotenv.get('ENABLE_PERFORMANCE_MONITORING', fallback: 'true').toLowerCase() == 'true';
  static bool get enableDebugLogging => dotenv.get('ENABLE_DEBUG_LOGGING', fallback: 'false').toLowerCase() == 'true';
  
  // Third-party Services
  static String get stripePublishableKey => dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: '');
  static String get googleMapsApiKey => dotenv.get('GOOGLE_MAPS_API_KEY', fallback: '');
  
  // Helper methods
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';
  
  static bool get isValidConfiguration {
    return firebaseApiKey.isNotEmpty &&
           firebaseProjectId.isNotEmpty &&
           zegoAppId.isNotEmpty &&
           zegoAppSign.isNotEmpty;
  }
  
  static Map<String, dynamic> getConfigSummary() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'environment': environment,
      'isDevelopment': isDevelopment,
      'isStaging': isStaging,
      'isProduction': isProduction,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableDebugLogging': enableDebugLogging,
      'isValidConfiguration': isValidConfiguration,
      'apiBaseUrl': apiBaseUrl,
      'firebaseProjectId': firebaseProjectId,
    };
  }
}