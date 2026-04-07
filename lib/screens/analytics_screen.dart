import 'dart:math' as math;

import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerWidget {
  final String courtId;
  const AnalyticsScreen({super.key, required this.courtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(analyticsProvider(courtId));

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).analytics)),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (data) => _AnalyticsBody(data: data),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  final AnalyticsData data;
  const _AnalyticsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = data.summary;
    final str = S.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary cards ──────────────────────────────────────────────────
          _sectionTitle(str.summary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                label: str.thisMonth,
                value: '${s.monthRevenue.toStringAsFixed(0)} JOD',
                sub: '${s.monthBookings} ${str.bookingsLabel}',
                color: ehjezGreen,
              ),
              _StatCard(
                label: str.allTimeRevenue,
                value: '${s.totalRevenue.toStringAsFixed(0)} JOD',
                sub: '${s.totalBookings} ${str.totalBookings}',
                color: const Color(0xFF1565C0),
              ),
              _StatCard(
                label: str.avgBookingValue,
                value: '${s.avgBookingValue.toStringAsFixed(2)} JOD',
                sub: str.perReservation,
                color: const Color(0xFFF57F17),
              ),
              _StatCard(
                label: str.totalCommission,
                value: '${s.totalCommission.toStringAsFixed(2)} JOD',
                sub: str.allTime,
                color: const Color(0xFF880E4F),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Monthly revenue ────────────────────────────────────────────────
          if (data.monthlyRevenue.isNotEmpty) ...[
            _sectionTitle(str.monthlyRevenueJod),
            const SizedBox(height: 16),
            _BarChart(
              bars: data.monthlyRevenue
                  .map((m) => _Bar(
                        label: m.month.substring(5), // "03" from "2026-03"
                        value: m.revenue,
                        tooltip: '${m.bookings} bookings\n${m.revenue.toStringAsFixed(0)} JOD',
                      ))
                  .toList(),
              color: ehjezGreen,
              barHeight: 160,
            ),
            const SizedBox(height: 32),
          ],

          // ── Peak hours ─────────────────────────────────────────────────────
          if (data.peakHours.isNotEmpty) ...[
            _sectionTitle(str.peakHours),
            const SizedBox(height: 4),
            Text(
              str.bookingsPerHour,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            _BarChart(
              bars: data.peakHours
                  .map((h) => _Bar(
                        label: _formatHour(h.hour),
                        value: h.count.toDouble(),
                        tooltip: '${h.count} bookings at ${_formatHour(h.hour)}',
                      ))
                  .toList(),
              color: const Color(0xFF1565C0),
              barHeight: 120,
            ),
            const SizedBox(height: 32),
          ],

          // ── By weekday ─────────────────────────────────────────────────────
          if (data.byWeekday.isNotEmpty) ...[
            _sectionTitle(str.busiestDays),
            const SizedBox(height: 4),
            Text(
              str.bookingsPerWeekday,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            _BarChart(
              bars: data.byWeekday
                  .map((d) => _Bar(
                        label: d.dayLabel,
                        value: d.bookings.toDouble(),
                        tooltip:
                            '${d.bookings} bookings\n${d.revenue.toStringAsFixed(0)} JOD',
                      ))
                  .toList(),
              color: const Color(0xFFF57F17),
              barHeight: 120,
            ),
            const SizedBox(height: 32),
          ],

          // ── By size ────────────────────────────────────────────────────────
          if (data.bySize.isNotEmpty) ...[
            _sectionTitle(str.bookingsBySize),
            const SizedBox(height: 16),
            _SizeBreakdown(sizes: data.bySize),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );

  static String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ─── Bar chart ────────────────────────────────────────────────────────────────

class _Bar {
  final String label;
  final double value;
  final String tooltip;
  const _Bar({required this.label, required this.value, required this.tooltip});
}

class _BarChart extends StatelessWidget {
  final List<_Bar> bars;
  final Color color;
  final double barHeight;

  const _BarChart({
    required this.bars,
    required this.color,
    this.barHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = bars.map((b) => b.value).fold(0.0, math.max);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final h = maxVal > 0 ? (bar.value / maxVal) * barHeight : 0.0;
          final labelVal = bar.value >= 1000
              ? '${(bar.value / 1000).toStringAsFixed(1)}k'
              : bar.value.toStringAsFixed(bar.value == bar.value.roundToDouble() ? 0 : 1);

          return Expanded(
            child: Tooltip(
              message: bar.tooltip,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (bar.value > 0)
                      Text(
                        labelVal,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: h,
                      decoration: BoxDecoration(
                        color: bar.value == maxVal
                            ? color
                            : color.withValues(alpha: 0.55),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bar.label,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Size breakdown ───────────────────────────────────────────────────────────

class _SizeBreakdown extends StatelessWidget {
  final List<SizeStats> sizes;
  const _SizeBreakdown({required this.sizes});

  @override
  Widget build(BuildContext context) {
    final total = sizes.fold(0, (sum, s) => sum + s.count);
    final colors = [
      ehjezGreen,
      const Color(0xFF1565C0),
      const Color(0xFFF57F17),
      const Color(0xFF880E4F),
      const Color(0xFF4527A0),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: sizes.mapIndexed((i, s) {
          final pct = total > 0 ? s.count / total : 0.0;
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.size,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${s.count} bookings  (${(pct * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Dart 3.3+ extension for indexed map on List
extension _IndexedMap<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) f) {
    return List.generate(length, (i) => f(i, this[i]));
  }
}
