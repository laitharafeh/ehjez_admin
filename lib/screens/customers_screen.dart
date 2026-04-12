import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  final String courtId;
  const CustomersScreen({super.key, required this.courtId});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final customersAsync = ref.watch(customersProvider(widget.courtId));

    return Scaffold(
      appBar: AppBar(title: Text(s.customers)),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (customers) {
          final filtered =
              _query.isEmpty
                  ? customers
                  : customers.where((c) {
                    final name = (c['name'] as String? ?? '').toLowerCase();
                    final phone = (c['phone'] as String? ?? '').toLowerCase();
                    final q = _query.toLowerCase();
                    return name.contains(q) || phone.contains(q);
                  }).toList();

          return Column(
            children: [
              _StatsBar(customers: customers),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: s.searchCustomers,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _query.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child:
                    filtered.isEmpty
                        ? Center(
                          child: Text(
                            customers.isEmpty
                                ? s.noCustomers
                                : s.noMatchingCustomers,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            return _CustomerCard(
                              customer: c,
                              courtId: widget.courtId,
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Top stats bar ──────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  const _StatsBar({required this.customers});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final totalCustomers = customers.length;
    final totalBookings = customers.fold<int>(
      0,
      (sum, c) => sum + ((c['booking_count'] as num?)?.toInt() ?? 0),
    );
    final totalRevenue = customers.fold<double>(
      0,
      (sum, c) => sum + ((c['total_spend'] as num?)?.toDouble() ?? 0),
    );

    return Container(
      color: ehjezGreen.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.people_outline,
            label: s.customers,
            value: '$totalCustomers',
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.calendar_today_outlined,
            label: s.bookingHistory,
            value: '$totalBookings',
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.payments_outlined,
            label: s.totalSpend,
            value: s.totalSpendAmount(totalRevenue),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ehjezGreen.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: ehjezGreen),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Customer card ──────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final String courtId;
  const _CustomerCard({required this.customer, required this.courtId});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name = customer['name'] as String? ?? '—';
    final phone = customer['phone'] as String? ?? '—';
    final bookingCount = (customer['booking_count'] as num?)?.toInt() ?? 0;
    final totalSpend = (customer['total_spend'] as num?)?.toDouble() ?? 0.0;
    final lastBooking = customer['last_booking'] as String? ?? '';
    final initials =
        name.trim().isNotEmpty
            ? name
                .trim()
                .split(' ')
                .map((w) => w[0])
                .take(2)
                .join()
                .toUpperCase()
            : '?';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: ehjezGreen.withOpacity(0.15),
          child: Text(
            initials,
            style: TextStyle(color: ehjezGreen, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          phone,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              s.totalSpendAmount(totalSpend),
              style: TextStyle(
                color: ehjezGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.bookingCountLabel(bookingCount),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        onTap:
            () => context.push('/customers/$courtId/detail', extra: customer),
      ),
    );
  }
}
