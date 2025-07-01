import 'package:flutter_test/flutter_test.dart';
import 'package:childcarehub_flutter/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('should create user with required fields', () {
      final user = UserModel(
        id: 'test_id',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.parent,
        createdAt: DateTime.now(),
      );

      expect(user.id, 'test_id');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.parent);
      expect(user.createdAt, isA<DateTime>());
    });

    test('should serialize to JSON correctly', () {
      final user = UserModel(
        id: 'test_id',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.parent,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      final json = user.toJson();

      expect(json['id'], 'test_id');
      expect(json['name'], 'Test User');
      expect(json['email'], 'test@example.com');
      expect(json['role'], 'parent');
      expect(json['createdAt'], isA<String>());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test_id',
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'parent',
        'createdAt': '2023-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'test_id');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.parent);
      expect(user.createdAt.year, 2023);
    });

    test('should handle different user roles', () {
      final parent = UserModel(
        id: '1',
        name: 'Parent',
        email: 'parent@example.com',
        role: UserRole.parent,
        createdAt: DateTime.now(),
      );

      final doctor = UserModel(
        id: '2',
        name: 'Doctor',
        email: 'doctor@example.com',
        role: UserRole.doctor,
        createdAt: DateTime.now(),
      );

      final admin = UserModel(
        id: '3',
        name: 'Admin',
        email: 'admin@example.com',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      expect(parent.role, UserRole.parent);
      expect(doctor.role, UserRole.doctor);
      expect(admin.role, UserRole.admin);
    });

    test('should support copyWith functionality', () {
      final user = UserModel(
        id: 'test_id',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.parent,
        createdAt: DateTime.now(),
      );

      final updatedUser = user.copyWith(name: 'Updated Name');

      expect(updatedUser.id, user.id);
      expect(updatedUser.name, 'Updated Name');
      expect(updatedUser.email, user.email);
      expect(updatedUser.role, user.role);
    });

    test('should implement equality correctly', () {
      final date = DateTime.now();
      final user1 = UserModel(
        id: 'test_id',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.parent,
        createdAt: date,
      );

      final user2 = UserModel(
        id: 'test_id',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.parent,
        createdAt: date,
      );

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });
  });
}