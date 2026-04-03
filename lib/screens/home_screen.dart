import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/models/admin_court.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/auth_service.dart';
import 'package:ehjez_admin/widgets/custom_square_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courtAsync = ref.watch(currentCourtProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 40,
        title: Text(
          'ehjez',
          style: GoogleFonts.grandstander(
            textStyle: Theme.of(context).textTheme.displayLarge,
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: ehjezGreen,
          ),
        ),
        actions: [
          // Only show the settings gear when the court is loaded
          if (courtAsync.valueOrNull != null)
            IconButton(
              tooltip: 'Court Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () =>
                  context.push('/settings/${courtAsync.value!.id}'),
            ),
        ],
      ),
      body: courtAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone_disabled_outlined,
                        color: Colors.redAccent,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This account is not linked to any court.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in again with a court phone number to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await AuthService.signOut();
                          // go_router's refreshListenable redirects to /login automatically
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ehjezGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Back To Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        data: (court) => _HomeBody(court: court),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final AdminCourt court;
  const _HomeBody({required this.court});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Court name subtitle so admin knows which court they manage
          Text(
            court.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomSquareButton(
                onTap: () => context.push('/reservations'),
                text: 'Reservations',
                assetPath: 'assets/reservation_icon.png',
              ),
              CustomSquareButton(
                onTap: () => context.push('/accounting/${court.id}'),
                text: 'Finances',
                assetPath: 'assets/accounting_icon.png',
              ),
              CustomSquareButton(
                onTap: () => context.push('/analytics/${court.id}'),
                text: 'Analytics',
                assetPath: 'assets/marketing_icon.png',
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomSquareButton(
                onTap: () => context.push('/blacklist'),
                text: 'Blacklist',
                assetPath: 'assets/reservation_icon.png',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
