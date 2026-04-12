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
        centerTitle: true,
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
          if (courtAsync.valueOrNull?.isOwner == true)
            IconButton(
              tooltip: s.courtSettings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () =>
                  context.push('/settings/${courtAsync.value!.id}'),
            ),
          IconButton(
            tooltip: s.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              // go_router's auth listener automatically redirects to /login
            },
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

// ── Button grid (responsive: max 6 per row, fewer on smaller screens) ─────────

class _ButtonGrid extends StatelessWidget {
  final List<Widget> buttons;
  const _ButtonGrid({required this.buttons});

  // Each button is 100px + 15px padding on each side = 130px
  static const double _buttonWidth = 130;
  static const int _maxPerRow = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = (constraints.maxWidth / _buttonWidth)
            .floor()
            .clamp(1, _maxPerRow);

        final rows = <List<Widget>>[];
        for (var i = 0; i < buttons.length; i += perRow) {
          final end = (i + perRow).clamp(0, buttons.length);
          rows.add(buttons.sublist(i, end));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: rows
              .map(
                (row) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row,
                ),
              )
              .toList(),
        );
      },
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
    final isOwner = court.isOwner;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                court.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              if (!isOwner) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    court.role[0].toUpperCase() + court.role.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _ButtonGrid(buttons: [
            // ── Always visible ──────────────────────────────────────────────
            CustomSquareButton(
              onTap: () => context.push('/reservations'),
              text: s.reservations,
              icon: Icons.calendar_month_outlined,
            ),
            CustomSquareButton(
              onTap: () => context.push('/tournaments/${court.id}'),
              text: s.tournaments,
              icon: Icons.emoji_events_outlined,
            ),
            CustomSquareButton(
              onTap: () => context.push('/customers/${court.id}'),
              text: s.customers,
              icon: Icons.people_outline,
            ),
            // ── Owner-only ──────────────────────────────────────────────────
            if (isOwner) ...[
              CustomSquareButton(
                onTap: () => context.push('/accounting/${court.id}'),
                text: s.finances,
                icon: Icons.account_balance_wallet_outlined,
              ),
              CustomSquareButton(
                onTap: () => context.push('/analytics/${court.id}'),
                text: s.analytics,
                icon: Icons.bar_chart_outlined,
              ),
              CustomSquareButton(
                onTap: () => context.push('/pricing/${court.id}'),
                text: s.pricing,
                icon: Icons.sell_outlined,
              ),
              CustomSquareButton(
                onTap: () => context.push('/recurring/${court.id}'),
                text: s.recurringReservations,
                icon: Icons.repeat,
              ),
              CustomSquareButton(
                onTap: () => context.push('/promo/${court.id}'),
                text: s.promoCodes,
                icon: Icons.local_offer_outlined,
              ),
            ],
          ]),
        ],
      ),
    );
  }
}
