// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/utils/invoice_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AccountingScreen extends ConsumerStatefulWidget {
  final String courtId;
  const AccountingScreen({super.key, required this.courtId});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> {
  late DateTime _month; // always day=1

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
    if (!next.isAfter(DateTime.now())) {
      setState(() => _month = next);
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  // ── CSV export ───────────────────────────────────────────────────────────────

  void _exportCsv(MonthlyAccountingData data) {
    final lines = [
      'Date,Time,Field,Size,Customer,Phone,Price (JOD),Commission (JOD)',
      ...data.bookings.map((b) {
        String escape(String s) =>
            s.contains(',') ? '"$s"' : s;
        return [
          b.date,
          b.startTime,
          'F${b.fieldNumber}',
          b.size,
          escape(b.name.isNotEmpty ? b.name : '—'),
          b.phone,
          b.price.toStringAsFixed(2),
          b.commission.toStringAsFixed(2),
        ].join(',');
      }),
    ];
    final bytes = utf8.encode(lines.join('\n'));
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'bookings_${_month.year}_${_month.month.toString().padLeft(2, '0')}.csv',
      )
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ── PDF invoice ──────────────────────────────────────────────────────────────

  Future<void> _generatePdf(MonthlyAccountingData data) async {
    try {
      await InvoiceGenerator.generateAndDownload(
        data: data,
        year: _month.year,
        month: _month.month,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice downloaded.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(monthlyAccountingProvider(_args));

    return Scaffold(
      appBar: AppBar(title: const Text('Finances')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (data) => _Body(
          data: data,
          month: _month,
          isCurrentMonth: _isCurrentMonth,
          onPrev: _prevMonth,
          onNext: _isCurrentMonth ? null : _nextMonth,
          onCsv: () => _exportCsv(data),
          onPdf: () => _generatePdf(data),
        ),
      ),
    );
  }
}

// ─── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final MonthlyAccountingData data;
  final DateTime month;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onCsv;
  final VoidCallback onPdf;

  const _Body({
    required this.data,
    required this.month,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
    required this.onCsv,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthHeader(
                month: month,
                onPrev: onPrev,
                onNext: onNext,
                onCsv: onCsv,
                onPdf: onPdf,
              ),
              const SizedBox(height: 20),
              _SummaryCards(data: data),
              const SizedBox(height: 24),
              if (data.dailyRevenue.isNotEmpty) ...[
                _SectionTitle('Daily Revenue'),
                const SizedBox(height: 12),
                _DailyChart(
                  days: data.dailyRevenue,
                  month: month,
                ),
                const SizedBox(height: 24),
              ],
              if (data.bySize.isNotEmpty) ...[
                _SectionTitle('Revenue by Field Size'),
                const SizedBox(height: 12),
                _SizeBreakdown(data: data),
                const SizedBox(height: 24),
              ],
              if (data.bookings.isNotEmpty) ...[
                _SectionTitle('Bookings (${data.bookings.length})'),
                const SizedBox(height: 12),
                _BookingsTable(bookings: data.bookings),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No bookings this month.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Month header ─────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onCsv;
  final VoidCallback onPdf;

  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onCsv,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          tooltip: 'Next month',
          color: onNext == null ? Colors.grey.shade300 : null,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onCsv,
          icon: const Icon(Icons.table_chart_outlined, size: 16),
          label: const Text('CSV'),
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

// ─── Summary cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final MonthlyAccountingData data;
  const _SummaryCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final netProfit = data.revenue - data.commission;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Revenue',
            value: '${fmt.format(data.revenue)} JOD',
            icon: Icons.payments_outlined,
            color: ehjezGreen,
            prev: data.prevMonthRevenue,
            current: data.revenue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Bookings',
            value: '${data.bookingCount}',
            icon: Icons.event_available_outlined,
            color: Colors.blue.shade600,
            prev: data.prevMonthBookings.toDouble(),
            current: data.bookingCount.toDouble(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Commission',
            value: '${fmt.format(data.commission)} JOD',
            icon: Icons.percent_outlined,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Net Profit',
            value: '${fmt.format(netProfit)} JOD',
            icon: Icons.trending_up,
            color: Colors.teal.shade600,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? prev;
  final double? current;

  const _SummaryCard({
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
            Icon(
              isUp ? Icons.arrow_upward : Icons.arrow_downward,
              size: 11,
              color: isUp ? Colors.green.shade700 : Colors.red.shade700,
            ),
            const SizedBox(width: 2),
            Text(
              '${pct.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUp ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            if (badge != null && prev != null && prev! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'vs ${NumberFormat('#,##0.##').format(prev!)} last month',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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

    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    // Build a full list with 0 for missing days
    final byDay = {for (final d in days) d.day: d};
    final allDays = List.generate(daysInMonth, (i) {
      final d = i + 1;
      return byDay[d] ?? (day: d, revenue: 0.0, bookings: 0);
    });

    final maxRev = allDays.fold(0.0, (m, d) => d.revenue > m ? d.revenue : m);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 160,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barW =
                  ((constraints.maxWidth - 8) / daysInMonth - 2).clamp(3.0, 20.0);
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
                      height: 140 * frac + (d.revenue > 0 ? 4 : 1),
                      decoration: BoxDecoration(
                        color: isMax
                            ? ehjezGreen
                            : ehjezGreen.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
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

// ─── Size breakdown ───────────────────────────────────────────────────────────

class _SizeBreakdown extends StatelessWidget {
  final MonthlyAccountingData data;
  const _SizeBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final totalRev = data.revenue > 0 ? data.revenue : 1.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      Text(
                        s.size,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${fmt.format(s.revenue)} JOD',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${(pct * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.bookings} bookings',
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
                      backgroundColor: ehjezGreen.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(ehjezGreen),
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
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
    const cellStyle = TextStyle(fontSize: 12);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(ehjezGreen),
          headingTextStyle: headStyle,
          dataTextStyle: cellStyle,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Field')),
            DataColumn(label: Text('Size')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Price'), numeric: true),
            DataColumn(label: Text('Commission'), numeric: true),
          ],
          rows: bookings.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            return DataRow(
              color: WidgetStatePropertyAll(
                i.isEven ? Colors.white : Colors.grey.shade50,
              ),
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

// ─── Shared ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      );
}
