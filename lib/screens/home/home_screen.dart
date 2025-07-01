import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    
    // Redirect based on user role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.isAuthenticated && authState.role != null) {
        switch (authState.role!) {
          case UserRole.parent:
            context.go('/home/parent');
            break;
          case UserRole.doctor:
            context.go('/home/doctor');
            break;
          case UserRole.admin:
            context.go('/home/admin');
            break;
        }
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}