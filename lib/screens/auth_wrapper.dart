import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'tailor_dashboard.dart';
import 'customer_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is not logged in, show auth screen
        if (snapshot.data == null) {
          return const AuthScreen();
        }

        // If user is logged in, check role and show appropriate dashboard
        return _RoleBasedDashboard(userId: snapshot.data!.uid);
      },
    );
  }
}

class _RoleBasedDashboard extends StatefulWidget {
  final String userId;

  const _RoleBasedDashboard({required this.userId});

  @override
  State<_RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends State<_RoleBasedDashboard> {
  final AuthService _authService = AuthService();
  bool _roleSet = false;

  @override
  void initState() {
    super.initState();
    _checkAndSetRole();
  }

  Future<void> _checkAndSetRole() async {
    final userEmail = _authService.currentUser?.email;
    final role = await _authService.getUserRole(widget.userId);

    // If admin email but role not set, set it immediately
    if (_authService.isAdmin(userEmail) && role != 'tailor') {
      await _authService.updateUserRole(widget.userId, 'tailor');
      if (mounted) {
        setState(() => _roleSet = true);
      }
    } else if (role == null && !_authService.isAdmin(userEmail)) {
      // If no role and not admin, set to customer
      await _authService.updateUserRole(widget.userId, 'customer');
      if (mounted) {
        setState(() => _roleSet = true);
      }
    } else {
      if (mounted) {
        setState(() => _roleSet = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _authService.currentUser?.email;

    return FutureBuilder<String?>(
      future: _authService.getUserRole(widget.userId),
      builder: (context, snapshot) {
        // Handle error state to prevent blank screen
        if (snapshot.hasError) {
          debugPrint('Auth Role Error: ${snapshot.error}');
          // Default to customer dashboard on error to keep app functional
          return const CustomerDashboard();
        }

        // Show loading while fetching role
        if (snapshot.connectionState == ConnectionState.waiting && !_roleSet) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final role = snapshot.data;

        // First check if user is admin by email (highest priority)
        if (_authService.isAdmin(userEmail)) {
          return const TailorDashboard();
        }

        // Route based on role from Firestore
        if (role == 'tailor') {
          return const TailorDashboard();
        } else if (role == 'customer') {
          return const CustomerDashboard();
        } else {
          // Default to customer while role is being set
          return const CustomerDashboard();
        }
      },
    );
  }
}

