import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
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
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 40,
        leading: const _LangToggle(),
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
          if (courtAsync.valueOrNull != null)
            IconButton(
              tooltip: s.courtSettings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () =>
                  context.push('/settings/${courtAsync.value!.id}'),
            ),
        ],
      ),
      body: courtAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
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
                  Text(
                    s.notLinkedToCourt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.signInWithCourtPhone,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await AuthService.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ehjezGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(s.backToLogin),
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

// ── Language toggle ────────────────────────────────────────────────────────────

class _LangToggle extends ConsumerWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isAr = lang == 'ar';
    return IconButton(
      tooltip: isAr ? 'Switch to English' : 'التبديل إلى العربية',
      icon: Text(
        isAr ? 'EN' : 'ع',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: ehjezGreen,
        ),
      ),
      onPressed: () {
        ref.read(languageProvider.notifier).state = isAr ? 'en' : 'ar';
      },
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  final AdminCourt court;
  const _HomeBody({required this.court});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
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
                text: s.reservations,
                assetPath: 'assets/reservation_icon.png',
              ),
              CustomSquareButton(
                onTap: () => context.push('/accounting/${court.id}'),
                text: s.finances,
                assetPath: 'assets/accounting_icon.png',
              ),
              CustomSquareButton(
                onTap: () => context.push('/analytics/${court.id}'),
                text: s.analytics,
                assetPath: 'assets/marketing_icon.png',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
