// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:math' as math;

import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/reservation_service.dart';
import 'package:ehjez_admin/utils/excel_generator.dart';
import 'package:ehjez_admin/utils/invoice_generator.dart';
import 'package:ehjez_admin/widgets/shimmer_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  final String courtId;
  const AnalyticsScreen({super.key, required this.courtId});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  AccountingArgs get _args =>
      (courtId: widget.courtId, year: _month.year, month: _month.month);

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1, 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1, 1);
    if (!next.isAfter(DateTime.now())) setState(() => _month = next);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _exportExcel(MonthlyAccountingData data) {
    try {
      ExcelGenerator.generateAndDownload(
          data: data, year: _month.year, month: _month.month);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).excelDownloaded),
        backgroundColor: ehjezGreen,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Excel export failed: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _generatePdf(MonthlyAccountingData data) async {
    try {
      await InvoiceGenerator.generateAndDownload(
          data: data, year: _month.year, month: _month.month);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).invoiceDownloaded)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).pdfError('$e')),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsProvider(widget.courtId));
    final monthlyAsync = ref.watch(monthlyAccountingProvider(_args));

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).analytics)),
      body: analyticsAsync.when(
        loading: () => const _AnalyticsSkeleton(),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (analyticsData) => _AnalyticsBody(
          analyticsData: analyticsData,
          monthlyAsync: monthlyAsync,
          month: _month,
          isCurrentMonth: _isCurrentMonth,
          onPrev: _prevMonth,
          onNext: _isCurrentMonth ? null : _nextMonth,
          onCsv: monthlyAsync.valueOrNull != null
              ? () => _exportExcel(monthlyAsync.value!)
              : null,
          onPdf: monthlyAsync.valueOrNull != null
              ? () => _generatePdf(monthlyAsync.value!)
              : null,
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  final AnalyticsData analyticsData;
  final AsyncValue<MonthlyAccountingData> monthlyAsync;
  final DateTime month;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onCsv;
  final VoidCallback? onPdf;

  const _AnalyticsBody({
    required this.analyticsData,
    required this.monthlyAsync,
    required this.month,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
    required this.onCsv,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final s = analyticsData.summary;
    final str = S.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── All-time summary cards ─────────────────────────────────────────
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

          // ── Monthly revenue (all-time bar) ─────────────────────────────────
          if (analyticsData.monthlyRevenue.isNotEmpty) ...[
            _sectionTitle(str.monthlyRevenueJod),
            const SizedBox(height: 16),
            _BarChart(
              bars: analyticsData.monthlyRevenue
                  .map((m) => _Bar(
                        label: m.month.substring(5),
                        value: m.revenue,
                        tooltip:
                            '${m.bookings} bookings\n${m.revenue.toStringAsFixed(0)} JOD',
                      ))
                  .toList(),
              color: ehjezGreen,
              barHeight: 160,
            ),
            const SizedBox(height: 32),
          ],

          // ── Peak hours ─────────────────────────────────────────────────────
          if (analyticsData.peakHours.isNotEmpty) ...[
            _sectionTitle(str.peakHours),
            const SizedBox(height: 4),
            Text(str.bookingsPerHour,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            _BarChart(
              bars: analyticsData.peakHours
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
          if (analyticsData.byWeekday.isNotEmpty) ...[
            _sectionTitle(str.busiestDays),
            const SizedBox(height: 4),
            Text(str.bookingsPerWeekday,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            _BarChart(
              bars: analyticsData.byWeekday
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

          // ── By size (all-time) ─────────────────────────────────────────────
          if (analyticsData.bySize.isNotEmpty) ...[
            _sectionTitle(str.bookingsBySize),
            const SizedBox(height: 16),
            _SizeBreakdown(sizes: analyticsData.bySize),
            const SizedBox(height: 32),
          ],

          // ── Divider ────────────────────────────────────────────────────────
          const Divider(thickness: 1, color: Color(0xFFE8EBE8)),
          const SizedBox(height: 24),

          // ── Monthly report ─────────────────────────────────────────────────
          _sectionTitle(str.finances),
          const SizedBox(height: 16),
          _MonthHeader(
            month: month,
            onPrev: onPrev,
            onNext: onNext,
            onCsv: onCsv,
            onPdf: onPdf,
          ),
          const SizedBox(height: 20),
          monthlyAsync.when(
            loading: () => const _MonthlyReportSkeleton(),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.red))),
            data: (monthly) =>
                _MonthlyReportContent(data: monthly, month: month),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _sectionTitle(String text) => Text(
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

// ─── Monthly report content ───────────────────────────────────────────────────

class _MonthlyReportContent extends StatelessWidget {
  final MonthlyAccountingData data;
  final DateTime month;
  const _MonthlyReportContent({required this.data, required this.month});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthlySummaryCards(data: data),
        if (data.dailyRevenue.isNotEmpty) ...[
          const SizedBox(height: 24),
          _monthSectionTitle(s.dailyRevenue),
          const SizedBox(height: 12),
          _DailyChart(days: data.dailyRevenue, month: month),
        ],
        if (data.bySize.isNotEmpty) ...[
          const SizedBox(height: 24),
          _monthSectionTitle(s.revenueBySize),
          const SizedBox(height: 12),
          _MonthlyRevenueBreakdown(data: data),
        ],
        if (data.bookings.isNotEmpty) ...[
          const SizedBox(height: 24),
          _monthSectionTitle(s.bookingsSection(data.bookings.length)),
          const SizedBox(height: 12),
          _BookingsTable(bookings: data.bookings),
        ] else ...[
          const SizedBox(height: 32),
          Center(
            child: Text(s.noBookingsThisMonth,
                style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ],
    );
  }

  static Widget _monthSectionTitle(String text) => Text(
        text,
        style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );
}

// ─── Stat card (all-time) ─────────────────────────────────────────────────────

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
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ─── Bar chart (all-time) ─────────────────────────────────────────────────────

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
    required this.barHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final maxVal = bars.map((b) => b.value).fold(0.0, math.max);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final frac = maxVal > 0 ? bar.value / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: bar.tooltip,
                    child: Container(
                      height: barHeight * frac + (bar.value > 0 ? 4 : 1),
                      decoration: BoxDecoration(
                        color: color.withValues(
                            alpha: frac > 0.8
                                ? 1.0
                                : frac > 0.5
                                    ? 0.75
                                    : 0.5),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(bar.label,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── All-time size breakdown ──────────────────────────────────────────────────

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
                    Text(s.size,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      '${s.count} bookings  (${(pct * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
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

// ─── Month header ─────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onCsv;
  final VoidCallback? onPdf;

  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onCsv,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
          tooltip: s.previousMonth,
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right,
              color: onNext == null ? Colors.grey.shade300 : null),
          onPressed: onNext,
          tooltip: s.nextMonth,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onCsv,
          icon: const Icon(Icons.table_chart_outlined, size: 16),
          label: const Text('CSV / Excel'),
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade800),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: onPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ehjezGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─── Monthly summary cards ────────────────────────────────────────────────────

class _MonthlySummaryCards extends StatelessWidget {
  final MonthlyAccountingData data;
  const _MonthlySummaryCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fmt = NumberFormat('#,##0.00');
    final netProfit = data.revenue - data.commission;

    return Row(
      children: [
        Expanded(
          child: _MonthlySummaryCard(
            label: s.revenue,
            value: '${fmt.format(data.revenue)} JOD',
            icon: Icons.payments_outlined,
            color: ehjezGreen,
            prev: data.prevMonthRevenue,
            current: data.revenue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MonthlySummaryCard(
            label: s.bookingsCount,
            value: '${data.bookingCount}',
            icon: Icons.event_available_outlined,
            color: Colors.blue.shade600,
            prev: data.prevMonthBookings.toDouble(),
            current: data.bookingCount.toDouble(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MonthlySummaryCard(
            label: s.commission,
            value: '${fmt.format(data.commission)} JOD',
            icon: Icons.percent_outlined,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MonthlySummaryCard(
            label: s.netProfit,
            value: '${fmt.format(netProfit)} JOD',
            icon: Icons.trending_up,
            color: Colors.teal.shade600,
          ),
        ),
      ],
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? prev;
  final double? current;

  const _MonthlySummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.prev,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    Widget? badge;
    if (prev != null && current != null && prev! > 0) {
      final pct = ((current! - prev!) / prev!) * 100;
      final isUp = pct >= 0;
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 11,
                color:
                    isUp ? Colors.green.shade700 : Colors.red.shade700),
            const SizedBox(width: 2),
            Text(
              '${pct.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isUp
                      ? Colors.green.shade700
                      : Colors.red.shade700),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (badge != null) badge,
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
            if (badge != null && prev != null && prev! > 0) ...[
              const SizedBox(height: 4),
              Text(
                S.of(context).vsLastMonth(
                    NumberFormat('#,##0.##').format(prev!)),
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Daily revenue chart ──────────────────────────────────────────────────────

class _DailyChart extends StatelessWidget {
  final List<DayRevenue> days;
  final DateTime month;
  const _DailyChart({required this.days, required this.month});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final byDay = {for (final d in days) d.day: d};
    final allDays = List.generate(daysInMonth, (i) {
      final d = i + 1;
      return byDay[d] ?? (day: d, revenue: 0.0, bookings: 0);
    });
    final maxRev =
        allDays.fold(0.0, (m, d) => d.revenue > m ? d.revenue : m);

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 160,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barW =
                  ((constraints.maxWidth - 8) / daysInMonth - 2)
                      .clamp(3.0, 20.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: allDays.map((d) {
                  final frac = maxRev > 0 ? d.revenue / maxRev : 0.0;
                  final isMax = maxRev > 0 && d.revenue == maxRev;
                  return Tooltip(
                    message: d.revenue > 0
                        ? 'Day ${d.day}: ${NumberFormat('#,##0.00').format(d.revenue)} JOD (${d.bookings} bookings)'
                        : 'Day ${d.day}: no bookings',
                    child: Container(
                      width: barW,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height:
                          140 * frac + (d.revenue > 0 ? 4 : 1),
                      decoration: BoxDecoration(
                        color: isMax
                            ? ehjezGreen
                            : ehjezGreen.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Monthly revenue breakdown by size ────────────────────────────────────────

class _MonthlyRevenueBreakdown extends StatelessWidget {
  final MonthlyAccountingData data;
  const _MonthlyRevenueBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final totalRev = data.revenue > 0 ? data.revenue : 1.0;

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: data.bySize.map((s) {
            final pct = s.revenue / totalRev;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(s.size,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${fmt.format(s.revenue)} JOD',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text('(${(pct * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600)),
                      const SizedBox(width: 8),
                      Text('${s.bookings} bookings',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor:
                          ehjezGreen.withValues(alpha: 0.1),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(ehjezGreen),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Bookings table ───────────────────────────────────────────────────────────

class _BookingsTable extends StatelessWidget {
  final List<BookingRow> bookings;
  const _BookingsTable({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    const headStyle = TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white);
    const cellStyle = TextStyle(fontSize: 12);

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(ehjezGreen),
          headingTextStyle: headStyle,
          dataTextStyle: cellStyle,
          columnSpacing: 20,
          columns: [
            DataColumn(label: Text(S.of(context).dateCol)),
            DataColumn(label: Text(S.of(context).timeCol)),
            DataColumn(label: Text(S.of(context).fieldCol)),
            DataColumn(label: Text(S.of(context).sizeCol)),
            DataColumn(label: Text(S.of(context).customerCol)),
            DataColumn(label: Text(S.of(context).phoneCol)),
            DataColumn(
                label: Text(S.of(context).priceCol), numeric: true),
            DataColumn(
                label: Text(S.of(context).commission), numeric: true),
          ],
          rows: bookings.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            return DataRow(
              color: WidgetStatePropertyAll(
                  i.isEven ? Colors.white : Colors.grey.shade50),
              cells: [
                DataCell(Text(b.date)),
                DataCell(Text(_fmt12(b.startTime))),
                DataCell(Text('F${b.fieldNumber}')),
                DataCell(Text(b.size)),
                DataCell(Text(b.name.isNotEmpty ? b.name : '—')),
                DataCell(Text(b.phone.isNotEmpty ? b.phone : '—')),
                DataCell(Text('${fmt.format(b.price)} JOD')),
                DataCell(Text('${fmt.format(b.commission)} JOD')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _fmt12(String hhmm) {
    try {
      final parts = hhmm.split(':');
      var h = int.parse(parts[0]);
      final m = parts[1].padLeft(2, '0');
      final suffix = h < 12 ? 'AM' : 'PM';
      if (h == 0) h = 12;
      if (h > 12) h -= 12;
      return '$h:$m $suffix';
    } catch (_) {
      return hhmm;
    }
  }
}

// ─── Skeleton (initial full-page load) ────────────────────────────────────────

class _AnalyticsSkeleton extends StatelessWidget {
  const _AnalyticsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 16, width: 80, borderRadius: 4),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              4,
              (_) => SizedBox(
                width: 160,
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(height: 11, width: 80, borderRadius: 4),
                        const SizedBox(height: 10),
                        ShimmerBox(height: 22, width: 100, borderRadius: 4),
                        const SizedBox(height: 6),
                        ShimmerBox(height: 10, width: 90, borderRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(3, (i) {
            const heights = [160.0, 120.0, 120.0];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 16, width: 140, borderRadius: 4),
                const SizedBox(height: 16),
                _SkeletonBarChart(barHeight: heights[i]),
                const SizedBox(height: 32),
              ],
            );
          }),
          ShimmerBox(height: 16, width: 120, borderRadius: 4),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: List.generate(3, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(height: 13, width: 60, borderRadius: 4),
                        ShimmerBox(height: 11, width: 100, borderRadius: 4),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(height: 8, borderRadius: 4),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBarChart extends StatelessWidget {
  final double barHeight;
  const _SkeletonBarChart({required this.barHeight});

  @override
  Widget build(BuildContext context) {
    const ratios = [0.6, 1.0, 0.75, 0.85, 0.5, 0.9];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ratios.map((r) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerBox(height: barHeight * r, borderRadius: 4),
                  const SizedBox(height: 6),
                  ShimmerBox(height: 10, width: 28, borderRadius: 4),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Monthly report skeleton (shown while switching months) ───────────────────

class _MonthlyReportSkeleton extends StatelessWidget {
  const _MonthlyReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4 summary cards
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          ShimmerBox(
                              width: 36, height: 36, borderRadius: 8),
                          const Spacer(),
                        ]),
                        const SizedBox(height: 12),
                        ShimmerBox(height: 20, borderRadius: 4),
                        const SizedBox(height: 6),
                        ShimmerBox(
                            height: 12, width: 80, borderRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ShimmerBox(height: 192, borderRadius: 12),
        const SizedBox(height: 24),
        ShimmerBox(height: 120, borderRadius: 12),
        const SizedBox(height: 24),
        ShimmerBox(height: 220, borderRadius: 12),
      ],
    );
  }
}

// ─── Dart extension for indexed map ──────────────────────────────────────────

extension _IndexedMap<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) f) =>
      List.generate(length, (i) => f(i, this[i]));
}
