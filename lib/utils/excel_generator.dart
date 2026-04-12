// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

import 'package:ehjez_admin/providers/providers.dart';
import 'package:intl/intl.dart';

/// Generates a multi-section CSV that opens cleanly in Excel / Google Sheets.
/// Each logical "sheet" is separated by blank lines and a bold section header.
class ExcelGenerator {
  static void generateAndDownload({
    required MonthlyAccountingData data,
    required int year,
    required int month,
  }) {
    final fmt = NumberFormat('#,##0.00');
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final netRevenue = data.revenue - data.commission;
    final avgBooking =
        data.bookingCount > 0 ? data.revenue / data.bookingCount : 0.0;
    final activeDays = data.dailyRevenue.where((d) => d.revenue > 0).length;

    DayRevenue? bestDay;
    for (final d in data.dailyRevenue) {
      if (bestDay == null || d.revenue > bestDay.revenue) bestDay = d;
    }

    final revChange = data.prevMonthRevenue > 0
        ? ((data.revenue - data.prevMonthRevenue) /
            data.prevMonthRevenue *
            100)
        : null;
    final bookingChange = data.prevMonthBookings > 0
        ? ((data.bookingCount - data.prevMonthBookings) /
            data.prevMonthBookings *
            100)
        : null;

    // Aggregate customers
    final customerMap = <String, ({String name, double spend, int count})>{};
    for (final b in data.bookings) {
      final key = b.phone.isNotEmpty ? b.phone : b.name;
      final existing = customerMap[key];
      customerMap[key] = existing == null
          ? (name: b.name.isNotEmpty ? b.name : b.phone, spend: b.price, count: 1)
          : (name: existing.name, spend: existing.spend + b.price, count: existing.count + 1);
    }
    final topCustomers = customerMap.entries.toList()
      ..sort((a, b) => b.value.spend.compareTo(a.value.spend));

    final lines = <String>[];

    String esc(String s) {
      if (s.contains(',') || s.contains('"') || s.contains('\n')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return s;
    }

    void row(List<String> cells) => lines.add(cells.map(esc).join(','));
    void blank() => lines.add('');
    void header(String title) {
      blank();
      row([title]);
      blank();
    }

    // ── Report title ──────────────────────────────────────────────────────────
    row(['MONTHLY FINANCIAL REPORT — $monthName']);
    row(['Court', data.courtName]);
    row(['Generated', DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())]);
    row(['Report Ref',
        'RPT-${data.courtName.replaceAll(' ', '').toUpperCase().substring(0, data.courtName.length.clamp(0, 4))}-$year${month.toString().padLeft(2, '0')}']);

    // ── Section 1: Key Metrics ────────────────────────────────────────────────
    header('SECTION 1 — KEY PERFORMANCE INDICATORS');
    row(['Metric', 'Value']);
    row(['Gross Revenue', '${fmt.format(data.revenue)} JOD']);
    row(['Net Revenue', '${fmt.format(netRevenue)} JOD']);
    row(['Commission (Platform Fee)', '${fmt.format(data.commission)} JOD']);
    row(['Total Bookings', '${data.bookingCount}']);
    row(['Average Booking Value', '${fmt.format(avgBooking)} JOD']);
    row(['Average Daily Revenue',
        '${fmt.format(data.bookingCount > 0 ? data.revenue / daysInMonth : 0)} JOD']);
    row(['Active Days', '$activeDays of $daysInMonth']);
    if (bestDay != null) {
      row([
        'Best Day',
        'Day ${bestDay.day} — ${fmt.format(bestDay.revenue)} JOD (${bestDay.bookings} bookings)'
      ]);
    }

    // ── Section 2: Month-over-Month ───────────────────────────────────────────
    header('SECTION 2 — MONTH-OVER-MONTH COMPARISON');
    row(['Metric', 'This Month', 'Last Month', 'Change']);
    row([
      'Gross Revenue',
      '${fmt.format(data.revenue)} JOD',
      '${fmt.format(data.prevMonthRevenue)} JOD',
      revChange != null
          ? '${revChange >= 0 ? '+' : ''}${revChange.toStringAsFixed(1)}%'
          : '—',
    ]);
    row([
      'Total Bookings',
      '${data.bookingCount}',
      '${data.prevMonthBookings}',
      bookingChange != null
          ? '${bookingChange >= 0 ? '+' : ''}${bookingChange.toStringAsFixed(1)}%'
          : '—',
    ]);
    row([
      'Net Revenue',
      '${fmt.format(netRevenue)} JOD',
      '—',
      '—',
    ]);

    // ── Section 3: Revenue by Field Size ──────────────────────────────────────
    header('SECTION 3 — REVENUE BY FIELD SIZE');
    row(['Field Size', 'Bookings', 'Revenue (JOD)', 'Share (%)', 'Avg per Booking (JOD)']);
    final totalRev = data.revenue > 0 ? data.revenue : 1.0;
    for (final s in data.bySize) {
      final pct = (s.revenue / totalRev * 100).toStringAsFixed(1);
      final avg = s.bookings > 0 ? s.revenue / s.bookings : 0.0;
      row([s.size, '${s.bookings}', fmt.format(s.revenue), '$pct%', fmt.format(avg)]);
    }
    row(['TOTAL', '${data.bookingCount}', fmt.format(data.revenue), '100%', '']);

    // ── Section 4: Daily Revenue ──────────────────────────────────────────────
    header('SECTION 4 — DAILY REVENUE');
    row(['Day', 'Date', 'Revenue (JOD)', 'Bookings', 'Cumulative Revenue (JOD)']);
    final byDay = {for (final d in data.dailyRevenue) d.day: d};
    double cumulative = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final dayData = byDay[d];
      final rev = dayData?.revenue ?? 0.0;
      cumulative += rev;
      final dateStr = DateFormat('dd MMM yyyy').format(DateTime(year, month, d));
      row([
        '$d',
        dateStr,
        fmt.format(rev),
        '${dayData?.bookings ?? 0}',
        fmt.format(cumulative),
      ]);
    }
    row(['', 'TOTAL', fmt.format(data.revenue), '${data.bookingCount}', fmt.format(data.revenue)]);

    // ── Section 5: Top Customers ──────────────────────────────────────────────
    header('SECTION 5 — CUSTOMERS BY SPEND');
    row(['Rank', 'Name', 'Phone', 'Bookings', 'Total Spend (JOD)', 'Avg per Visit (JOD)']);
    int rank = 1;
    for (final entry in topCustomers) {
      final c = entry.value;
      final avg = c.count > 0 ? c.spend / c.count : 0.0;
      row(['$rank', c.name, entry.key, '${c.count}', fmt.format(c.spend), fmt.format(avg)]);
      rank++;
    }

    // ── Section 6: Transaction Ledger ─────────────────────────────────────────
    header('SECTION 6 — TRANSACTION LEDGER');
    row(['#', 'Date', 'Time', 'Field', 'Size', 'Customer', 'Phone',
        'Price (JOD)', 'Commission (JOD)', 'Net (JOD)']);
    int txNum = 1;
    for (final b in data.bookings) {
      final net = b.price - b.commission;
      final timeParts = b.startTime.split(':');
      String fmtTime = b.startTime;
      if (timeParts.length >= 2) {
        var h = int.tryParse(timeParts[0]) ?? 0;
        final m = timeParts[1].padLeft(2, '0');
        final suf = h < 12 ? 'AM' : 'PM';
        if (h == 0) h = 12;
        if (h > 12) h -= 12;
        fmtTime = '$h:$m $suf';
      }
      row([
        '$txNum',
        b.date,
        fmtTime,
        'F${b.fieldNumber}',
        b.size,
        b.name.isNotEmpty ? b.name : '—',
        b.phone.isNotEmpty ? b.phone : '—',
        fmt.format(b.price),
        fmt.format(b.commission),
        fmt.format(net),
      ]);
      txNum++;
    }
    row(['', '', '', '', '', '', 'TOTAL',
        fmt.format(data.revenue),
        fmt.format(data.commission),
        fmt.format(netRevenue)]);

    // ── Download ──────────────────────────────────────────────────────────────
    // BOM so Excel auto-detects UTF-8
    final bom = '\uFEFF';
    final csv = bom + lines.join('\n');
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'report_${data.courtName.replaceAll(' ', '_')}_${year}_${month.toString().padLeft(2, '0')}.csv',
      )
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
