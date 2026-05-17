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
        loading: () => const _CustomerSkeletonScreen(),
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

// ─── Skeleton loading ──────────────────────────────────────────────────────────

/// Full-screen skeleton that mirrors the stats bar + search bar + list layout.
class _CustomerSkeletonScreen extends StatelessWidget {
  const _CustomerSkeletonScreen();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats bar skeleton
        Container(
          color: const Color(0xFFEEEEEE),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _ShimmerBox(height: 58, borderRadius: 10)),
              const SizedBox(width: 12),
              Expanded(child: _ShimmerBox(height: 58, borderRadius: 10)),
              const SizedBox(width: 12),
              Expanded(child: _ShimmerBox(height: 58, borderRadius: 10)),
            ],
          ),
        ),
        // Search bar skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _ShimmerBox(height: 48, borderRadius: 12),
        ),
        // List skeleton
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, __) => const _CustomerSkeletonCard(),
          ),
        ),
      ],
    );
  }
}

/// Mimics Card + ListTile:
/// circle  |  name bar + phone bar  |  spend bar + count bar
class _CustomerSkeletonCard extends StatelessWidget {
  const _CustomerSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Circle avatar
            _ShimmerBox(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 16),
            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(height: 13, borderRadius: 4),
                  const SizedBox(height: 7),
                  _ShimmerBox(height: 11, width: 120, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Spend + booking count (right-aligned)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ShimmerBox(height: 13, width: 60, borderRadius: 4),
                const SizedBox(height: 7),
                _ShimmerBox(height: 11, width: 44, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Single reusable shimmer block. Animates a sweeping light band over grey.
class _ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const _ShimmerBox({
    required this.height,
    this.width,
    this.borderRadius = 4,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _ctrl.value * 3, 0),
              end: Alignment(-0.8 + _ctrl.value * 3, 0),
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF0F0F0),
                Color(0xFFE0E0E0),
              ],
            ),
          ),
        );
      },
    );
  }
}
