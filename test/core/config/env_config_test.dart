import 'package:flutter_test/flutter_test.dart';
import 'package:childcarehub_flutter/core/config/env_config.dart';

void main() {
  group('EnvConfig Tests', () {
    test('should have default fallback values', () {
      expect(EnvConfig.appName, isNotEmpty);
      expect(EnvConfig.appVersion, isNotEmpty);
      expect(EnvConfig.environment, isNotEmpty);
    });

    test('should validate configuration properly', () {
      // The configuration validation should check for required fields
      expect(EnvConfig.isValidConfiguration, isA<bool>());
    });

    test('should detect environment correctly', () {
      expect(EnvConfig.isDevelopment || EnvConfig.isStaging || EnvConfig.isProduction, isTrue);
    });

    test('should provide configuration summary', () {
      final summary = EnvConfig.getConfigSummary();
      
      expect(summary, isA<Map<String, dynamic>>());
      expect(summary['appName'], isNotNull);
      expect(summary['appVersion'], isNotNull);
      expect(summary['environment'], isNotNull);
      expect(summary['isValidConfiguration'], isA<bool>());
    });

    test('should have proper API configuration', () {
      expect(EnvConfig.apiBaseUrl, isNotEmpty);
      expect(EnvConfig.apiTimeout, greaterThan(0));
    });

    test('should have feature flags configured', () {
      expect(EnvConfig.enableAnalytics, isA<bool>());
      expect(EnvConfig.enableCrashReporting, isA<bool>());
      expect(EnvConfig.enablePerformanceMonitoring, isA<bool>());
      expect(EnvConfig.enableDebugLogging, isA<bool>());
    });
  });
}