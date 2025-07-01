import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../models/child_model.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/parent_home_screen.dart';
import '../../screens/home/doctor_home_screen.dart';
import '../../screens/home/admin_home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/consultation/consultation_screen.dart';
import '../../screens/consultation/book_consultation_screen.dart';
import '../../screens/consultation/consultation_history_screen.dart';
import '../../screens/consultation/video_call_screen.dart';
import '../../screens/doctors/doctors_list_screen.dart';
import '../../screens/doctors/doctor_detail_screen.dart';
import '../../screens/wallet/wallet_screen.dart';
import '../../screens/wallet/recharge_screen.dart';
import '../../screens/children/children_list_screen.dart';
import '../../screens/children/add_child_screen.dart';
import '../../screens/children/edit_child_screen.dart';
import '../../screens/doctor_dashboard/doctor_dashboard_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/settings/settings_screen.dart';

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.role;
      final isLoading = authState.isLoading;
      
      // Show splash while loading
      if (isLoading) {
        return '/splash';
      }
      
      // Routes that don't require authentication
      final publicRoutes = ['/splash', '/login', '/register', '/forgot-password'];
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);
      
      // If not authenticated and trying to access private route
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }
      
      // If authenticated and on public route, redirect to appropriate home
      if (isAuthenticated && isPublicRoute && state.matchedLocation != '/splash') {
        return _getHomeRouteForRole(userRole);
      }
      
      return null; // No redirect needed
    },
    routes: [
      // Splash route
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Main app routes with role-based shell
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          // Home routes (role-based)
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: '/parent',
                name: 'parent-home',
                builder: (context, state) => const ParentHomeScreen(),
              ),
              GoRoute(
                path: '/doctor',
                name: 'doctor-home',
                builder: (context, state) => const DoctorHomeScreen(),
              ),
              GoRoute(
                path: '/admin',
                name: 'admin-home',
                builder: (context, state) => const AdminHomeScreen(),
              ),
            ],
          ),
          
          // Profile routes
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          
          // Consultation routes
          GoRoute(
            path: '/consultation',
            name: 'consultation',
            builder: (context, state) => const ConsultationScreen(),
            routes: [
              GoRoute(
                path: '/book',
                name: 'book-consultation',
                builder: (context, state) {
                  return BookConsultationScreen(
                    extraData: state.extra as Map<String, dynamic>?,
                  );
                },
              ),
              GoRoute(
                path: '/history',
                name: 'consultation-history',
                builder: (context, state) => const ConsultationHistoryScreen(),
              ),
              GoRoute(
                path: '/call/:consultationId',
                name: 'video-call',
                builder: (context, state) {
                  final consultationId = state.pathParameters['consultationId']!;
                  return VideoCallScreen(consultationId: consultationId);
                },
              ),
            ],
          ),
          
          // Doctors routes
          GoRoute(
            path: '/doctors',
            name: 'doctors',
            builder: (context, state) => const DoctorsListScreen(),
            routes: [
              GoRoute(
                path: '/:doctorId',
                name: 'doctor-detail',
                builder: (context, state) {
                  final doctorId = state.pathParameters['doctorId']!;
                  return DoctorDetailScreen(doctorId: doctorId);
                },
              ),
            ],
          ),
          
          // Wallet routes
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const WalletScreen(),
            routes: [
              GoRoute(
                path: '/recharge',
                name: 'recharge',
                builder: (context, state) => const RechargeScreen(),
              ),
            ],
          ),
          
          // Children routes
          GoRoute(
            path: '/children',
            name: 'children',
            builder: (context, state) => const ChildrenListScreen(),
            routes: [
              GoRoute(
                path: '/add',
                name: 'add-child',
                builder: (context, state) => const AddChildScreen(),
              ),
              GoRoute(
                path: '/:childId/edit',
                name: 'edit-child',
                builder: (context, state) {
                  final childId = state.pathParameters['childId']!;
                  return EditChildScreen(childId: childId);
                },
              ),
            ],
          ),
          
          // Doctor dashboard routes
          GoRoute(
            path: '/doctor-dashboard',
            name: 'doctor-dashboard',
            builder: (context, state) => const DoctorDashboardScreen(),
          ),
          
          // Admin dashboard routes
          GoRoute(
            path: '/admin-dashboard',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          
          // Notifications routes
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          
          // Settings routes
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Helper function to get home route based on user role
String _getHomeRouteForRole(UserRole? role) {
  switch (role) {
    case UserRole.parent:
      return '/home/parent';
    case UserRole.doctor:
      return '/home/doctor';
    case UserRole.admin:
      return '/home/admin';
    default:
      return '/home';
  }
}

// Main shell widget for authenticated app
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavBar(context, authState.role),
    );
  }

  Widget? _buildBottomNavBar(BuildContext context, UserRole? role) {
    if (role == null) return null;

    final currentRoute = GoRouterState.of(context).matchedLocation;
    
    switch (role) {
      case UserRole.parent:
        return _buildParentBottomNavBar(context, currentRoute);
      case UserRole.doctor:
        return _buildDoctorBottomNavBar(context, currentRoute);
      case UserRole.admin:
        return _buildAdminBottomNavBar(context, currentRoute);
    }
  }

  Widget _buildParentBottomNavBar(BuildContext context, String currentRoute) {
    int currentIndex = 0;
    
    if (currentRoute.startsWith('/home')) {
      currentIndex = 0;
    } else if (currentRoute.startsWith('/doctors')) {
      currentIndex = 1;
    } else if (currentRoute.startsWith('/consultation')) {
      currentIndex = 2;
    } else if (currentRoute.startsWith('/wallet')) {
      currentIndex = 3;
    } else if (currentRoute.startsWith('/profile')) {
      currentIndex = 4;
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home/parent');
            break;
          case 1:
            context.go('/doctors');
            break;
          case 2:
            context.go('/consultation');
            break;
          case 3:
            context.go('/wallet');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Doctors'),
        BottomNavigationBarItem(icon: Icon(Icons.video_call), label: 'Consult'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  Widget _buildDoctorBottomNavBar(BuildContext context, String currentRoute) {
    int currentIndex = 0;
    
    if (currentRoute.startsWith('/home')) {
      currentIndex = 0;
    } else if (currentRoute.startsWith('/doctor-dashboard')) {
      currentIndex = 1;
    } else if (currentRoute.startsWith('/consultation')) {
      currentIndex = 2;
    } else if (currentRoute.startsWith('/notifications')) {
      currentIndex = 3;
    } else if (currentRoute.startsWith('/profile')) {
      currentIndex = 4;
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home/doctor');
            break;
          case 1:
            context.go('/doctor-dashboard');
            break;
          case 2:
            context.go('/consultation');
            break;
          case 3:
            context.go('/notifications');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.video_call), label: 'Consult'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  Widget _buildAdminBottomNavBar(BuildContext context, String currentRoute) {
    int currentIndex = 0;
    
    if (currentRoute.startsWith('/home')) {
      currentIndex = 0;
    } else if (currentRoute.startsWith('/admin-dashboard')) {
      currentIndex = 1;
    } else if (currentRoute.startsWith('/doctors')) {
      currentIndex = 2;
    } else if (currentRoute.startsWith('/settings')) {
      currentIndex = 3;
    } else if (currentRoute.startsWith('/profile')) {
      currentIndex = 4;
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home/admin');
            break;
          case 1:
            context.go('/admin-dashboard');
            break;
          case 2:
            context.go('/doctors');
            break;
          case 3:
            context.go('/settings');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Doctors'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

// Navigation helpers
extension AppRouterExtension on GoRouter {
  void goToHome(UserRole? role) {
    go(_getHomeRouteForRole(role));
  }
  
  void goToLogin() {
    go('/login');
  }
  
  void goToConsultation() {
    go('/consultation');
  }
  
  void goToWallet() {
    go('/wallet');
  }
  
  void goToDoctors() {
    go('/doctors');
  }
  
  void goToProfile() {
    go('/profile');
  }
}