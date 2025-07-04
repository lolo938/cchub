import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import 'notification_service.dart';
import 'wallet_service.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final User? user;
  final UserRole? role;

  AuthResult.success({required this.user, this.role})
      : isSuccess = true,
        errorMessage = null;

  AuthResult.error(this.errorMessage)
      : isSuccess = false,
        user = null,
        role = null;
}

class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state stream
  static Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user
  static User? get currentUser => _firebaseAuth.currentUser;

  // Sign in with email and password
  static Future<AuthResult> signInWithEmailPassword(
      String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final role = await getUserRole(credential.user!.uid) ?? UserRole.parent;
        await NotificationService.updateUserFCMToken(credential.user!.uid);
        return AuthResult.success(user: credential.user!, role: role);
      }
      return AuthResult.error('Authentication failed.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in with Google
  static Future<AuthResult> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign-In process...');

      final googleUser = await GoogleSignIn().signIn();
      print(
          '🔵 Google Sign-In dialog result: ${googleUser != null ? "User selected" : "User cancelled"}');

      if (googleUser == null) {
        print('🔴 Google Sign-In was cancelled by user');
        return AuthResult.error('Google sign-in was canceled.');
      }

      print('🔵 Getting authentication tokens from Google...');
      print('🔵 Google User Email: ${googleUser.email}');
      print('🔵 Google User Name: ${googleUser.displayName}');

      final googleAuth = await googleUser.authentication;
      print('🔵 Got Google Auth tokens');
      print('🔵 Access Token exists: ${googleAuth.accessToken != null}');
      print('🔵 ID Token exists: ${googleAuth.idToken != null}');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('🔵 Created Firebase credential');

      print('🔵 Signing in to Firebase with Google credential...');
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      print(
          '🔵 Firebase sign-in result: ${user != null ? "Success" : "Failed"}');

      if (user != null) {
        print('🔵 User signed in successfully. UID: ${user.uid}');
        print('🔵 Checking if user exists in Firestore...');

        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        print('🔵 User exists in Firestore: ${userDoc.exists}');

        if (!userDoc.exists) {
          print('🔵 Creating new user document in Firestore...');
          await _createUserDocument(user, UserRole.parent, {
            'name': user.displayName,
          });
          print('🔵 Creating wallet for new user...');
          await WalletService.createWallet(user.uid);
          print('🔵 New user setup complete');
        }

        print('🔵 Updating FCM token...');
        await NotificationService.updateUserFCMToken(user.uid);

        print('🔵 Getting user role...');
        final role = await getUserRole(user.uid) ?? UserRole.parent;
        print('🔵 User role: $role');

        print('✅ Google Sign-In completed successfully!');
        return AuthResult.success(user: user, role: role);
      }

      print('🔴 Google sign-in failed - user is null');
      return AuthResult.error('Google sign-in failed.');
    } on FirebaseAuthException catch (e) {
      print('🔴 FirebaseAuthException during Google Sign-In:');
      print('🔴 Error code: ${e.code}');
      print('🔴 Error message: ${e.message}');
      print('🔴 Error details: ${e.toString()}');
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e, stackTrace) {
      print('🔴 Unexpected error during Google Sign-In:');
      print('🔴 Error type: ${e.runtimeType}');
      print('🔴 Error message: ${e.toString()}');
      print('🔴 Stack trace: $stackTrace');
      return AuthResult.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Create account
  static Future<AuthResult> createAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await _createUserDocument(credential.user!, UserRole.parent, {
          'name': name,
          'phone': phone,
        });
        await WalletService.createWallet(credential.user!.uid);
        await NotificationService.updateUserFCMToken(credential.user!.uid);
        return AuthResult.success(
            user: credential.user!, role: UserRole.parent);
      }
      return AuthResult.error('Account creation failed.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
  }

  // Reset password
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult.success(user: null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Get user data
  static Future<AppUser?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get user role
  static Future<UserRole?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return UserRole.values.firstWhere(
          (role) =>
              role.toString().split('.').last == data['role']?.toLowerCase(),
          orElse: () => UserRole.parent,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Private helper to create user document
  static Future<void> _createUserDocument(
    User user,
    UserRole role, [
    Map<String, dynamic>? additionalData,
  ]) async {
    await _firestore.collection('users').doc(user.uid).set({
      'name': additionalData?['name'] ?? user.displayName ?? 'User',
      'email': user.email ?? '',
      'phone': additionalData?['phone'],
      'role': role.toString().split('.').last.toUpperCase(),
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'address': '',
      'emergencyContact': '',
      'children': [],
      'walletBalance': 0.0,
    });
  }

  // Private helper for auth error messages
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      default:
        return 'An unknown authentication error occurred.';
    }
  }

  // Update user profile - overloaded to accept AppUser object
  static Future<bool> updateUserProfile(AppUser user) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null && firebaseUser.uid == user.id) {
        // Update Firebase Auth profile
        if (user.name != firebaseUser.displayName) {
          await firebaseUser.updateDisplayName(user.name);
        }
        if (user.photoUrl != null && user.photoUrl != firebaseUser.photoURL) {
          await firebaseUser.updatePhotoURL(user.photoUrl);
        }

        // Update Firestore document with all user data
        await _firestore.collection('users').doc(user.id).update({
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'photoUrl': user.photoUrl,
          'address': user.address,
          'emergencyContact': user.emergencyContact,
          'children': user.children.map((c) => c.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Delete account
  static Future<AuthResult> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
        return AuthResult.success(user: null);
      }
      return AuthResult.error('No user logged in');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Email verification
  static Future<bool> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static bool get isEmailVerified {
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  static Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }
}
