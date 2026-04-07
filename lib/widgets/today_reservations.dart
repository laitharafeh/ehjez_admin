import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/strike_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TodayReservations extends ConsumerWidget {
  final String courtId;
  const TodayReservations({super.key, required this.courtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final reservationsAsync = ref.watch(todaysReservationsProvider(courtId));

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              s.todayReservations,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            reservationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(s.errorMsg(e.toString()))),
              data: (list) {
                if (list.isEmpty) {
                  return Center(child: Text(s.noReservationsToday));
                }

                // Fetch strike counts for all phones in one query
                final phones = list
                    .map((r) => r['phone'] as String? ?? '')
                    .where((p) => p.isNotEmpty)
                    .toSet()
                    .toList();
                final strikeCountsAsync =
                    ref.watch(strikeCountsProvider(phones));

                final strikeCounts = strikeCountsAsync.valueOrNull ?? {};

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final r = list[i];
                    final reservationId = r['id'] as int;
                    final start = r['start_time'] as String;
                    final duration = r['duration'] as int;
                    final size = r['size'] as String? ?? '—';
                    final phone = r['phone'] as String? ?? '—';
                    final name = r['name'] as String? ?? '—';
                    final fieldNum = r['field_number'] as int? ?? 1;
                    final strikes = strikeCounts[phone] ?? 0;

                    final startTime12 = DateFormat.jm().format(
                      DateFormat.Hm().parse(start),
                    );
                    final endTime12 = DateFormat.jm().format(
                      DateFormat.Hm()
                          .parse(start)
                          .add(Duration(hours: duration)),
                    );
                    final timeRange = '$startTime12 – $endTime12';

                    return ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.schedule, size: 20),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF068631),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'F$fieldNum',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (strikes > 0) ...[
                            _StrikeBadge(count: strikes),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            timeRange,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        s.reservationSubtitle(phone, size, name),
                        textAlign: s.isAr ? TextAlign.right : TextAlign.left,
                      ),
                      trailing: _NoShowButton(
                        phone: phone,
                        courtId: courtId,
                        reservationId: reservationId,
                        onStrikeAdded: () {
                          ref.invalidate(strikeCountsProvider(phones));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Strike badge ─────────────────────────────────────────────────────────────

class _StrikeBadge extends StatelessWidget {
  final int count;
  const _StrikeBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final color = count >= 4 ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No-show button ───────────────────────────────────────────────────────────

class _NoShowButton extends StatefulWidget {
  final String phone;
  final String courtId;
  final int reservationId;
  final VoidCallback onStrikeAdded;

  const _NoShowButton({
    required this.phone,
    required this.courtId,
    required this.reservationId,
    required this.onStrikeAdded,
  });

  @override
  State<_NoShowButton> createState() => _NoShowButtonState();
}

class _NoShowButtonState extends State<_NoShowButton> {
  bool _loading = false;

  Future<void> _handleNoShow() async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.markAsNoShow),
        content: Text(s.noShowWarning(widget.phone)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(s.addStrike),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final newCount = await StrikeService.addStrike(
        phone: widget.phone,
        courtId: widget.courtId,
        reservationId: widget.reservationId,
      );
      widget.onStrikeAdded();

      if (!mounted) return;
      final s2 = S.of(context);
      final wasBlacklisted = newCount >= 5;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasBlacklisted
                ? s2.blacklistedAfterStrikes(widget.phone, newCount)
                : s2.strikeAdded(widget.phone, newCount),
          ),
          backgroundColor: wasBlacklisted ? Colors.red : Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Tooltip(
      message: S.of(context).markAsNoShowTooltip,
      child: IconButton(
        icon: const Icon(Icons.person_off_outlined, color: Colors.red),
        onPressed: widget.phone == '—' ? null : _handleNoShow,
      ),
    );
  }
}
