import 'package:flutter_test/flutter_test.dart';
import 'package:childcarehub_flutter/core/services/logger_service.dart';

void main() {
  group('LoggerService Tests', () {
    setUpAll(() {
      LoggerService.initialize();
    });

    test('should initialize without throwing', () {
      expect(() => LoggerService.initialize(), returnsNormally);
    });

    test('should log debug messages', () {
      expect(() => LoggerService.debug('Test debug message'), returnsNormally);
    });

    test('should log info messages', () {
      expect(() => LoggerService.info('Test info message'), returnsNormally);
    });

    test('should log warning messages', () {
      expect(() => LoggerService.warning('Test warning message'), returnsNormally);
    });

    test('should log error messages', () {
      expect(() => LoggerService.error('Test error message'), returnsNormally);
    });

    test('should log fatal messages', () {
      expect(() => LoggerService.fatal('Test fatal message'), returnsNormally);
    });

    test('should log API requests', () {
      expect(() => LoggerService.apiRequest('GET', 'https://api.test.com'), returnsNormally);
    });

    test('should log API responses', () {
      expect(() => LoggerService.apiResponse('GET', 'https://api.test.com', 200), returnsNormally);
    });

    test('should log user actions', () {
      expect(() => LoggerService.userAction('button_click', parameters: {'button': 'login'}), returnsNormally);
    });

    test('should log navigation events', () {
      expect(() => LoggerService.navigation('/home', '/profile'), returnsNormally);
    });

    test('should log performance metrics', () {
      final duration = Duration(milliseconds: 100);
      expect(() => LoggerService.performance('api_call', duration), returnsNormally);
    });

    test('should set user info', () {
      expect(() => LoggerService.setUserInfo('test_user', email: 'test@example.com'), returnsNormally);
    });

    test('should set custom keys', () {
      expect(() => LoggerService.setCustomKey('test_key', 'test_value'), returnsNormally);
    });

    test('should add breadcrumbs', () {
      expect(() => LoggerService.addBreadcrumb('User visited profile'), returnsNormally);
    });
  });
}