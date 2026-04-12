import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String courtId;
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({
    super.key,
    required this.courtId,
    required this.customer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final phone = customer['phone'] as String? ?? '';
    final name = customer['name'] as String? ?? '—';
    final bookingCount = (customer['booking_count'] as num?)?.toInt() ?? 0;
    final totalSpend = (customer['total_spend'] as num?)?.toDouble() ?? 0.0;
    final firstBooking = customer['first_booking'] as String? ?? '';
    final lastBooking = customer['last_booking'] as String? ?? '';

    final historyAsync = ref.watch(
      customerHistoryProvider((courtId: courtId, phone: phone)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              phone,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy phone',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$phone copied'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats header ─────────────────────────────────────────────────
          Container(
            color: ehjezGreen.withOpacity(0.08),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _InfoTile(
                  icon: Icons.payments_outlined,
                  label: s.totalSpend,
                  value: s.totalSpendAmount(totalSpend),
                  valueColor: ehjezGreen,
                ),
                const SizedBox(width: 10),
                _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: s.bookingHistory,
                  value: s.bookingCountLabel(bookingCount),
                ),
                const SizedBox(width: 10),
                _InfoTile(
                  icon: Icons.history_outlined,
                  label: s.firstVisit,
                  value: firstBooking,
                ),
                const SizedBox(width: 10),
                _InfoTile(
                  icon: Icons.update_outlined,
                  label: s.lastVisit,
                  value: lastBooking,
                ),
              ],
            ),
          ),
          // ── Booking history ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                s.bookingHistory,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Center(
                    child: Text(
                      s.noBookingHistory,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder:
                      (context, i) => _BookingRow(booking: bookings[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info tile ──────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ehjezGreen.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: ehjezGreen),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: valueColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Booking row ────────────────────────────────────────────────────────────────

class _BookingRow extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final date = booking['date'] as String? ?? '';
    final startTime = booking['start_time'] as String? ?? '';
    final duration = (booking['duration'] as num?)?.toInt() ?? 1;
    final size = booking['size'] as String? ?? '';
    final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
    final fieldNumber = (booking['field_number'] as num?)?.toInt() ?? 1;

    // Format start time (HH:MM:SS → HH:MM)
    final timeParts = startTime.split(':');
    final formattedTime =
        timeParts.length >= 2 ? '${timeParts[0]}:${timeParts[1]}' : startTime;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Date block
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: ehjezGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  date.length >= 10 ? date.substring(5, 7) : '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ehjezGreen,
                  ),
                ),
                Text(
                  date.length >= 10 ? date.substring(0, 4) : '',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$formattedTime · $size · ${s.fieldN(fieldNumber)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  s.durationHours(duration),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          // Price
          Text(
            s.totalSpendAmount(price),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ehjezGreen,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
