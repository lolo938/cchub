import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// User data provider
final userDataProvider = FutureProvider.family<AppUser?, String>((ref, userId) {
  return AuthService.getUserData(userId);
});

// Current user data provider
final currentUserDataProvider = FutureProvider<AppUser?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(null);
  return AuthService.getUserData(user.uid);
});

// User role provider
final userRoleProvider =
    FutureProvider.family<UserRole?, String>((ref, userId) {
  return AuthService.getUserRole(userId);
});

// Current user role provider
final currentUserRoleProvider = FutureProvider<UserRole?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(null);
  return AuthService.getUserRole(user.uid);
});

// Auth loading state provider
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Auth error provider
final authErrorProvider = StateProvider<String?>((ref) => null);

// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

// Auth state class
class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;
  final AppUser? userData;
  final UserRole? role;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.userData,
    this.role,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    User? user,
    AppUser? userData,
    UserRole? role,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      userData: userData ?? this.userData,
      role: role ?? this.role,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isParent => role == UserRole.parent;
  bool get isDoctor => role == UserRole.doctor;
  bool get isAdmin => role == UserRole.admin;
}

// Auth controller class
class AuthController extends StateNotifier<AuthState> {
  final Ref ref;

  AuthController(this.ref) : super(const AuthState()) {
    // Listen to auth state changes
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      next.when(
        data: (user) => _onAuthStateChanged(user),
        loading: () => state = state.copyWith(isLoading: true),
        error: (error, _) => state = state.copyWith(
          isLoading: false,
          error: error.toString(),
        ),
      );
    });
  }

  void _onAuthStateChanged(User? user) {
    if (user == null) {
      state = const AuthState();
    } else {
      state = state.copyWith(user: user, isLoading: false);
      _loadUserData(user.uid);
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final userData = await AuthService.getUserData(userId);
      final role = await AuthService.getUserRole(userId);

      state = state.copyWith(
        userData: userData,
        role: role,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AuthService.signInWithEmailPassword(email, password);

      if (!result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage,
        );
      }
      // Success will be handled by auth state change listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create account
  Future<void> createAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AuthService.createAccount(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (!result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage,
        );
      }
      // Success will be handled by auth state change listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AuthService.resetPassword(email);

      state = state.copyWith(
        isLoading: false,
        error: result.isSuccess ? null : result.errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await AuthService.signOut();
      // State will be updated by auth state change listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Update profile
  Future<void> updateUserProfile(AppUser user) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await AuthService.updateUserProfile(user);

      if (success) {
        // Reload user data
        if (state.user != null) {
          await _loadUserData(state.user!.uid);
        }
        // No need to set isLoading false here, _loadUserData will update state
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update profile',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await AuthService.sendEmailVerification();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Reload user
  Future<void> reloadUser() async {
    try {
      await AuthService.reloadUser();
      if (state.user != null) {
        await _loadUserData(state.user!.uid);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Delete account
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.deleteAccount();
      if (!result.isSuccess) {
        state = state.copyWith(isLoading: false, error: result.errorMessage);
      }
      // Success will be handled by auth state change listener (user becomes null)
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.signInWithGoogle();
      if (!result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage,
        );
      }
      // Success will be handled by auth state change listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> registerWithEmailPassword(
      String email, String password, String name, String phone) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AuthService.createAccount(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (!result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage,
        );
      }
      // Success will be handled by auth state change listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> removeChild(dynamic childId) async {}
  Future<void> logout() async {
    await signOut();
  }
}

// Convenience providers for specific checks
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isAuthenticated;
});

final isParentProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isParent;
});

final isDoctorProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isDoctor;
});

final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isAdmin;
});

// Email verification status provider
final emailVerificationProvider = Provider<bool>((ref) {
  return AuthService.isEmailVerified;
});

// Legacy alias for backward compatibility with old widgets
final authProvider = authControllerProvider;

// Legacy methods extension for backward compatibility
extension AuthControllerLegacy on AuthController {
  Future<void> addChild(dynamic child) async {
    // No-op: implement if needed
  }
  Future<void> updateChild(dynamic child) async {}
  Future<void> removeChild(dynamic childId) async {}
  Future<void> logout() async {
    await signOut();
  }
}
