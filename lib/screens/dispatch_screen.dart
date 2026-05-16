import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import 'home_screen.dart';

/// Sits at '/' and routes the user to the right home based on their role.
///
/// - Super admin  → /super-admin
/// - Court manager / staff / coach → HomeScreen (court view)
///
/// Uses ref.listen so the navigation fires outside of build, avoiding the
/// "called during build" pitfall that causes go_router to get stuck.
class DispatchScreen extends ConsumerWidget {
  const DispatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(isSuperAdminProvider, (_, next) {
      next.whenData((isAdmin) {
        if (isAdmin && context.mounted) {
          context.go('/super-admin');
        }
      });
    });

    final isSuper = ref.watch(isSuperAdminProvider);

    return isSuper.when(
      // Still checking — show a neutral loading screen.
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      // On error fall through to the court home; HomeScreen handles its own
      // error state via currentCourtProvider.
      error: (_, __) => const HomeScreen(),
      data: (isAdmin) => isAdmin
          // Brief spinner while ref.listen fires the go('/super-admin').
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const HomeScreen(),
    );
  }
}
