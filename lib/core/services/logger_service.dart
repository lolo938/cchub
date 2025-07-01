import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../config/env_config.dart';

/// Centralized logging service with different log levels and crash reporting
class LoggerService {
  static late Logger _logger;
  static bool _isInitialized = false;

  /// Initialize the logger service
  static void initialize() {
    if (_isInitialized) return;

    _logger = Logger(
      level: EnvConfig.enableDebugLogging ? Level.debug : Level.info,
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: _LogOutput(),
    );

    _isInitialized = true;
    info('LoggerService initialized successfully');
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info messages
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.w(message, error: error, stackTrace: stackTrace);
    
    // Report non-fatal errors to Crashlytics
    if (EnvConfig.enableCrashReporting && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: false,
        information: [message],
      );
    }
  }

  /// Log error messages
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.e(message, error: error, stackTrace: stackTrace);
    
    // Report errors to Crashlytics
    if (EnvConfig.enableCrashReporting && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: false,
        information: [message],
      );
    }
  }

  /// Log fatal errors
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.f(message, error: error, stackTrace: stackTrace);
    
    // Report fatal errors to Crashlytics
    if (EnvConfig.enableCrashReporting && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: true,
        information: [message],
      );
    }
  }

  /// Log API requests
  static void apiRequest(String method, String url, {Map<String, dynamic>? data}) {
    if (!_isInitialized) initialize();
    debug('API Request: $method $url', data);
  }

  /// Log API responses
  static void apiResponse(String method, String url, int statusCode, {dynamic data}) {
    if (!_isInitialized) initialize();
    if (statusCode >= 200 && statusCode < 300) {
      debug('API Response: $method $url [$statusCode]', data);
    } else {
      warning('API Error Response: $method $url [$statusCode]', data);
    }
  }

  /// Log user actions for analytics
  static void userAction(String action, {Map<String, dynamic>? parameters}) {
    if (!_isInitialized) initialize();
    info('User Action: $action', parameters);
  }

  /// Log navigation events
  static void navigation(String from, String to) {
    if (!_isInitialized) initialize();
    debug('Navigation: $from -> $to');
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    if (!_isInitialized) initialize();
    info('Performance: $operation took ${duration.inMilliseconds}ms', metadata);
  }

  /// Set user information for crash reporting
  static void setUserInfo(String userId, {String? email, String? name}) {
    if (EnvConfig.enableCrashReporting) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
      if (email != null) {
        FirebaseCrashlytics.instance.setCustomKey('user_email', email);
      }
      if (name != null) {
        FirebaseCrashlytics.instance.setCustomKey('user_name', name);
      }
    }
  }

  /// Add custom key-value pairs for crash reporting
  static void setCustomKey(String key, dynamic value) {
    if (EnvConfig.enableCrashReporting) {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }

  /// Add breadcrumb for tracking user journey
  static void addBreadcrumb(String message, {String? category}) {
    if (EnvConfig.enableCrashReporting) {
      FirebaseCrashlytics.instance.log('${category ?? 'INFO'}: $message');
    }
  }
}

/// Custom log output that handles different environments
class _LogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // In production, only output errors and warnings to reduce log spam
    if (EnvConfig.isProduction) {
      if (event.level.index >= Level.warning.index) {
        for (var line in event.lines) {
          print(line);
        }
      }
    } else {
      // In development/staging, output all logs
      for (var line in event.lines) {
        print(line);
      }
    }
  }
}