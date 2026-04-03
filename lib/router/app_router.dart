import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/home_screen.dart';
import '../screens/reservations_screen.dart';
import '../screens/accounting_screen.dart';
import '../screens/vacation_days_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/blacklist_screen.dart';
import '../screens/court_settings_screen.dart';

// Bridges Supabase's auth stream into go_router's refreshListenable so that
// login / logout automatically triggers a route re-evaluation.
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthChangeNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authNotifier = _AuthChangeNotifier();

final appRouter = GoRouter(
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final isLoggedIn =
        Supabase.instance.client.auth.currentSession != null;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/login' || loc == '/otp';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && loc == '/login') return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => OtpScreen(
        phoneNumber: state.extra as String,
      ),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/reservations',
      builder: (context, state) => const ReservationsScreen(),
    ),
    GoRoute(
      path: '/accounting/:courtId',
      builder: (context, state) => AccountingScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
    GoRoute(
      path: '/vacation-days/:courtId',
      builder: (context, state) => VacationDaysScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
    GoRoute(
      path: '/analytics/:courtId',
      builder: (context, state) => AnalyticsScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
    GoRoute(
      path: '/blacklist',
      builder: (context, state) => const BlacklistScreen(),
    ),
    GoRoute(
      path: '/settings/:courtId',
      builder: (context, state) => CourtSettingsScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
  ],
);
