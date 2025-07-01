import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:childcarehub_flutter/core/services/zego_service.dart';

void main() {
  group('ZegoService Tests', () {
    test('should initialize without throwing', () async {
      expect(() => ZegoService.initialize(), returnsNormally);
    });

    test('should generate unique call IDs', () {
      final callId1 = ZegoService.generateCallId('consultation_1');
      final callId2 = ZegoService.generateCallId('consultation_2');
      
      expect(callId1, isNotEmpty);
      expect(callId2, isNotEmpty);
      expect(callId1, isNot(equals(callId2)));
      expect(callId1, contains('consultation_1'));
      expect(callId2, contains('consultation_2'));
    });

    test('should provide configuration status', () {
      expect(ZegoService.isConfigured, isA<bool>());
      expect(ZegoService.configurationMessage, isNotEmpty);
    });

    test('should validate configuration', () {
      expect(ZegoService.validateConfiguration(), isA<bool>());
    });

    test('should send call invitations', () async {
      final result = await ZegoService.sendCallInvitation(
        callID: 'test_call',
        invitees: ['user1', 'user2'],
        callerName: 'Test User',
      );
      
      expect(result, isA<bool>());
    });

    test('should start consultation calls', () async {
      expect(() => ZegoService.startConsultationCall(
        consultationId: 'test_consultation',
        doctorId: 'doctor_1',
        parentId: 'parent_1',
        doctorName: 'Dr. Test',
        parentName: 'Parent Test',
      ), returnsNormally);
    });

    test('should provide service status', () {
      final status = ZegoService.getServiceStatus();
      
      expect(status, isA<Map<String, dynamic>>());
      expect(status['isInitialized'], isA<bool>());
      expect(status['isConfigured'], isA<bool>());
      expect(status['appId'], isA<String>());
      expect(status['configurationMessage'], isA<String>());
    });

    test('should update user info', () async {
      expect(() => ZegoService.updateUserInfo('test_user', 'Test User'), returnsNormally);
    });

    test('should uninitialize properly', () async {
      expect(() => ZegoService.uninitialize(), returnsNormally);
    });

    test('should dispose resources', () async {
      expect(() => ZegoService.dispose(), returnsNormally);
    });

    testWidgets('should build consultation call page', (WidgetTester tester) async {
      final widget = ZegoService.buildConsultationCallPage(
        callID: 'test_call',
        userId: 'test_user',
        userName: 'Test User',
        isDoctorRole: true,
        consultationId: 'test_consultation',
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Video Consultation'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Role: Doctor'), findsOneWidget);
      expect(find.byIcon(Icons.video_call), findsOneWidget);
    });
  });
}