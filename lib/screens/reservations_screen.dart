import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/auth_service.dart';
import 'package:ehjez_admin/widgets/court_assignment_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  void _signOut(BuildContext context) async {
    await AuthService.signOut();
    // go_router's refreshListenable redirects to /login automatically
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courtAsync = ref.watch(currentCourtProvider);

    return Scaffold(
      appBar: AppBar(
        title: courtAsync.whenData((c) => c.name).value != null
            ? Text(courtAsync.value!.name)
            : const Text('Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: courtAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading court: $e',
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        data: (court) => Padding(
          padding: const EdgeInsets.all(24),
          child: CourtAssignmentBoard(
            courtId: court.id,
            courtName: court.name,
            courtStartTime: court.startTime ?? '08:00:00',
            courtEndTime: court.endTime ?? '23:00:00',
          ),
        ),
      ),
    );
  }
}
