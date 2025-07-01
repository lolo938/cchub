import 'package:cloud_firestore/cloud_firestore.dart';
import 'child_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

enum UserRole {
  parent,
  doctor,
  admin,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? address;
  final String? emergencyContact;
  final List<Child> children;
  final double walletBalance;
  final String? phone;
  final UserRole role;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.address,
    this.emergencyContact,
    this.children = const [],
    this.walletBalance = 0.0,
    this.phone,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    this.isActive = true,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      address: map['address'],
      emergencyContact: map['emergencyContact'],
      children: (map['children'] as List<dynamic>? ?? [])
          .map((e) => Child.fromMap(e as Map<String, dynamic>, e['id'] ?? ''))
          .toList(),
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      phone: map['phone'],
      role: UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == map['role']?.toLowerCase(),
        orElse: () => UserRole.parent,
      ),
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'address': address,
      'emergencyContact': emergencyContact,
      'children': children.map((e) => e.toJson()).toList(),
      'walletBalance': walletBalance,
      'phone': phone,
      'role': role.toString().split('.').last.toUpperCase(),
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? emergencyContact,
    List<Child>? children,
    double? walletBalance,
    UserRole? role,
    String? photoUrl,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      children: children ?? this.children,
      walletBalance: walletBalance ?? this.walletBalance,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, name: $name, email: $email, role: $role, children: ${children.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // JSON convenience
  factory AppUser.fromJson(Map<String, dynamic> json) =>
      AppUser.fromMap(json, json['id'] ?? '');
  Map<String, dynamic> toJson() => toMap();
}

// Legacy type alias for backward compatibility
typedef UserModel = AppUser;

// Legacy getters for compatibility with older UI code
extension AppUserLegacyFields on AppUser {
  // additional legacy getters could go here
}

// Legacy extension on FirebaseAuth User to avoid compile errors where `.children` is accessed directly.
extension FirebaseUserLegacy on fb.User {
  List<Child> get children => [];
  String? get address => null;
  String? get emergencyContact => null;
  String get id => uid;
  String get name => displayName ?? email ?? 'User';
}
