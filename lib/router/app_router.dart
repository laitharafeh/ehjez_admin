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
import '../screens/court_settings_screen.dart';
import '../screens/tournaments_screen.dart';
import '../screens/tournament_registrants_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/customer_detail_screen.dart';
import '../screens/pricing_rules_screen.dart';
import '../screens/recurring_reservations_screen.dart';
import '../screens/promo_codes_screen.dart';

// Bridges Supabase's auth stream into go_router's refreshListenable so that
// login / logout automatically triggers a route re-evaluation.
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthChangeNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // Only trigger a route re-evaluation on actual login/logout transitions.
      // TOKEN_REFRESHED, INITIAL_SESSION, USER_UPDATED, etc. must NOT cause a
      // notifyListeners() call: go_router would try to redirect while already
      // mid-navigation and end up stuck between routes.
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut) {
        notifyListeners();
      }
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
    if (isLoggedIn && isAuthRoute) return '/';
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
      path: '/settings/:courtId',
      builder: (context, state) => CourtSettingsScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
    GoRoute(
      path: '/pricing/:courtId',
      builder: (context, state) => PricingRulesScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
    GoRoute(
      path: '/recurring/:courtId',
      builder: (context, state) => RecurringReservationsScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
    GoRoute(
      path: '/customers/:courtId',
      builder: (context, state) => CustomersScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
    GoRoute(
      path: '/customers/:courtId/detail',
      builder: (context, state) => CustomerDetailScreen(
        courtId: state.pathParameters['courtId']!,
        customer: state.extra as Map<String, dynamic>,
      ),
    ),
    GoRoute(
      path: '/tournaments/:courtId',
      builder: (context, state) => TournamentsScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
    GoRoute(
      path: '/tournaments/:courtId/:tournamentId',
      builder: (context, state) => TournamentRegistrantsScreen(
        tournamentId: state.pathParameters['tournamentId']!,
        tournamentTitle: state.extra as String? ?? '',
      ),
    ),
    GoRoute(
      path: '/promo/:courtId',
      builder: (context, state) => PromoCodesScreen(
        courtId: state.pathParameters['courtId']!,
      ),
    ),
  ],
);
