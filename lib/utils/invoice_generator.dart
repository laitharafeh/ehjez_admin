import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/utils/invoice_pdf_save_stub.dart'
    if (dart.library.html) 'package:ehjez_admin/utils/invoice_pdf_save_web.dart'
    if (dart.library.io) 'package:ehjez_admin/utils/invoice_pdf_save_io.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceGenerator {
  static final _green = PdfColor.fromHex('#068631');
  static final _greenLight = PdfColor.fromHex('#E8F5EC');
  static final _grey100 = PdfColor.fromHex('#F7F7F7');
  static final _grey300 = PdfColor.fromHex('#CCCCCC');
  static final _grey600 = PdfColor.fromHex('#666666');
  static final _red = PdfColor.fromHex('#C0392B');
  static final _blue = PdfColor.fromHex('#2471A3');
  static final _orange = PdfColor.fromHex('#D35400');
  static final _teal = PdfColor.fromHex('#148F77');

  static Future<void> generateAndDownload({
    required MonthlyAccountingData data,
    required int year,
    required int month,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
    final fmt = NumberFormat('#,##0.00');
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // ── Derived metrics ────────────────────────────────────────────────────────
    final netRevenue = data.revenue - data.commission;
    final avgBookingValue =
        data.bookingCount > 0 ? data.revenue / data.bookingCount : 0.0;
    final avgDailyRevenue =
        data.dailyRevenue.isEmpty ? 0.0 : data.revenue / daysInMonth;
    final activeDays =
        data.dailyRevenue.where((d) => d.revenue > 0).length;

    // Best day
    DayRevenue? bestDay;
    for (final d in data.dailyRevenue) {
      if (bestDay == null || d.revenue > bestDay.revenue) bestDay = d;
    }

    // Top 5 customers
    final customerMap = <String, ({String name, double spend, int count})>{};
    for (final b in data.bookings) {
      final key = b.phone.isNotEmpty ? b.phone : b.name;
      final existing = customerMap[key];
      if (existing == null) {
        customerMap[key] = (
          name: b.name.isNotEmpty ? b.name : b.phone,
          spend: b.price,
          count: 1
        );
      } else {
        customerMap[key] = (
          name: existing.name,
          spend: existing.spend + b.price,
          count: existing.count + 1
        );
      }
    }
    final topCustomers = customerMap.values.toList()
      ..sort((a, b) => b.spend.compareTo(a.spend));
    final top5 = topCustomers.take(5).toList();

    // Revenue by duration (1h vs 2h) — grouped from bookings
    // We don't have duration in BookingRow, so we group by price tiers instead
    // Use bySize for the breakdown

    // MoM change
    final revChange = data.prevMonthRevenue > 0
        ? ((data.revenue - data.prevMonthRevenue) / data.prevMonthRevenue * 100)
        : null;
    final bookingChange = data.prevMonthBookings > 0
        ? ((data.bookingCount - data.prevMonthBookings) /
            data.prevMonthBookings *
            100)
        : null;

    // Report reference
    final reportRef =
        'RPT-${data.courtName.replaceAll(' ', '').toUpperCase().substring(0, data.courtName.length.clamp(0, 4))}-$year${month.toString().padLeft(2, '0')}';
    final generatedOn = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    // ── PAGE 1: Executive Summary ──────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        header: (ctx) => _pageHeader(data.courtName, monthName, reportRef),
        footer: (ctx) => _pageFooter(ctx, generatedOn),
        build: (ctx) => [
          pw.SizedBox(height: 12),

          // ── KPI Row ──
          _sectionTitle('Financial Summary'),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _kpiBox('Gross Revenue', '${fmt.format(data.revenue)} JOD',
                _green, change: revChange),
            pw.SizedBox(width: 8),
            _kpiBox('Net Revenue', '${fmt.format(netRevenue)} JOD', _teal),
            pw.SizedBox(width: 8),
            _kpiBox('Commission', '${fmt.format(data.commission)} JOD',
                _orange, subtitle: 'Platform fee'),
            pw.SizedBox(width: 8),
            _kpiBox('Bookings', '${data.bookingCount}', _blue,
                change: bookingChange),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _kpiBox('Avg. Booking Value',
                '${fmt.format(avgBookingValue)} JOD', _grey600),
            pw.SizedBox(width: 8),
            _kpiBox('Avg. Daily Revenue',
                '${fmt.format(avgDailyRevenue)} JOD', _grey600),
            pw.SizedBox(width: 8),
            _kpiBox('Active Days', '$activeDays / $daysInMonth', _grey600),
            pw.SizedBox(width: 8),
            if (bestDay != null)
              _kpiBox(
                'Best Day',
                'Day ${bestDay.day} — ${fmt.format(bestDay.revenue)} JOD',
                _grey600,
                subtitle: '${bestDay.bookings} bookings',
              )
            else
              pw.Expanded(child: pw.SizedBox()),
          ]),

          pw.SizedBox(height: 18),

          // ── MoM Comparison ──
          if (data.prevMonthRevenue > 0) ...[
            _sectionTitle('Month-over-Month Comparison'),
            pw.SizedBox(height: 8),
            _momTable(data, fmt, revChange, bookingChange),
            pw.SizedBox(height: 18),
          ],

          // ── Revenue by field size ──
          if (data.bySize.isNotEmpty) ...[
            _sectionTitle('Revenue by Field Size'),
            pw.SizedBox(height: 8),
            _sizeTable(data, fmt),
            pw.SizedBox(height: 18),
          ],

          // ── Top customers ──
          if (top5.isNotEmpty) ...[
            _sectionTitle('Top Customers'),
            pw.SizedBox(height: 8),
            _topCustomersTable(top5, fmt),
            pw.SizedBox(height: 18),
          ],

          // ── Daily revenue table ──
          if (data.dailyRevenue.isNotEmpty) ...[
            _sectionTitle('Daily Revenue'),
            pw.SizedBox(height: 8),
            _dailyTable(data.dailyRevenue, year, month, fmt),
          ],
        ],
      ),
    );

    // ── PAGE 2+: Transaction Ledger ────────────────────────────────────────────
    if (data.bookings.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          header: (ctx) =>
              _pageHeader(data.courtName, monthName, reportRef),
          footer: (ctx) => _pageFooter(ctx, generatedOn),
          build: (ctx) => [
            pw.SizedBox(height: 12),
            _sectionTitle(
                'Transaction Ledger (${data.bookings.length} transactions)'),
            pw.SizedBox(height: 8),
            _bookingsTable(data.bookings, fmt),
            pw.SizedBox(height: 12),
            _ledgerTotals(data, fmt, netRevenue),
          ],
        ),
      );
    }

    final bytes = await pdf.save();
    await saveSummaryPdf(
      bytes,
      'report_${data.courtName.replaceAll(' ', '_')}_${year}_${month.toString().padLeft(2, '0')}.pdf',
    );
  }

  // ── Page chrome ────────────────────────────────────────────────────────────

  static pw.Widget _pageHeader(
      String courtName, String monthName, String reportRef) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(
              'ehjez',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#068631'),
              ),
            ),
            pw.Text(
              'Monthly Financial Report',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(
              courtName,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              monthName,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'Ref: $reportRef',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _pageFooter(pw.Context ctx, String generatedOn) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated $generatedOn · Ehjez Platform',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // ── KPI boxes ──────────────────────────────────────────────────────────────

  static pw.Widget _kpiBox(
    String label,
    String value,
    PdfColor color, {
    double? change,
    String? subtitle,
  }) {
    String? changeStr;
    PdfColor changeColor = PdfColors.grey600;
    if (change != null) {
      final sign = change >= 0 ? '+' : '';
      changeStr = '$sign${change.toStringAsFixed(1)}% vs last month';
      changeColor = change >= 0
          ? PdfColor.fromHex('#1A7A32')
          : PdfColor.fromHex('#C0392B');
    }

    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _grey300, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 6,
              height: 6,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, color: _grey600),
            ),
            if (changeStr != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(changeStr,
                  style:
                      pw.TextStyle(fontSize: 7, color: changeColor)),
            ],
            if (subtitle != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(subtitle,
                  style: pw.TextStyle(
                      fontSize: 7, color: _grey600)),
            ],
          ],
        ),
      ),
    );
  }

  // ── MoM comparison table ───────────────────────────────────────────────────

  static pw.Widget _momTable(
    MonthlyAccountingData data,
    NumberFormat fmt,
    double? revChange,
    double? bookingChange,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _green),
          children: [
            _th('Metric'),
            _th('This Month'),
            _th('Last Month'),
            _th('Change'),
          ],
        ),
        _momRow(
          'Gross Revenue',
          '${fmt.format(data.revenue)} JOD',
          '${fmt.format(data.prevMonthRevenue)} JOD',
          revChange,
        ),
        _momRow(
          'Total Bookings',
          '${data.bookingCount}',
          '${data.prevMonthBookings}',
          bookingChange,
        ),
        _momRow(
          'Net Revenue',
          '${fmt.format(data.revenue - data.commission)} JOD',
          '—',
          null,
        ),
      ],
    );
  }

  static pw.TableRow _momRow(
      String label, String current, String prev, double? pct) {
    String changeText = '—';
    PdfColor changeColor = _grey600;
    if (pct != null) {
      final sign = pct >= 0 ? '▲' : '▼';
      changeText = '$sign ${pct.abs().toStringAsFixed(1)}%';
      changeColor = pct >= 0 ? _green : _red;
    }
    return pw.TableRow(children: [
      _td(label),
      _td(current, bold: true),
      _td(prev),
      _td(changeText, color: changeColor, bold: true),
    ]);
  }

  // ── Revenue by size table ──────────────────────────────────────────────────

  static pw.Widget _sizeTable(MonthlyAccountingData data, NumberFormat fmt) {
    final totalRev = data.revenue > 0 ? data.revenue : 1.0;
    final rows = data.bySize.asMap().entries.map((e) {
      final s = e.value;
      final pct = (s.revenue / totalRev * 100).toStringAsFixed(1);
      final avgVal = s.bookings > 0 ? s.revenue / s.bookings : 0.0;
      return pw.TableRow(
        decoration: pw.BoxDecoration(
            color: e.key.isEven ? PdfColors.white : _grey100),
        children: [
          _td(s.size, bold: true),
          _td('${s.bookings}', align: pw.TextAlign.center),
          _td('${fmt.format(s.revenue)} JOD',
              align: pw.TextAlign.right),
          _td('$pct%', align: pw.TextAlign.center),
          _td('${fmt.format(avgVal)} JOD',
              align: pw.TextAlign.right),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: _grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _green),
          children: [
            _th('Field Size'),
            _th('Bookings'),
            _th('Revenue'),
            _th('Share'),
            _th('Avg. per Booking'),
          ],
        ),
        ...rows,
        // Totals row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _greenLight),
          children: [
            _td('TOTAL', bold: true),
            _td('${data.bookingCount}',
                bold: true, align: pw.TextAlign.center),
            _td('${fmt.format(data.revenue)} JOD',
                bold: true, align: pw.TextAlign.right),
            _td('100%',
                bold: true, align: pw.TextAlign.center),
            _td('', align: pw.TextAlign.right),
          ],
        ),
      ],
    );
  }

  // ── Top customers table ────────────────────────────────────────────────────

  static pw.Widget _topCustomersTable(
      List<({String name, double spend, int count})> customers,
      NumberFormat fmt) {
    return pw.Table(
      border: pw.TableBorder.all(color: _grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.4),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.8),
        4: const pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _green),
          children: [
            _th('#'),
            _th('Customer'),
            _th('Bookings'),
            _th('Total Spend'),
            _th('Avg per Visit'),
          ],
        ),
        ...customers.asMap().entries.map((e) {
          final rank = e.key + 1;
          final c = e.value;
          final avg = c.count > 0 ? c.spend / c.count : 0.0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: e.key.isEven ? PdfColors.white : _grey100),
            children: [
              _td('$rank',
                  align: pw.TextAlign.center,
                  color: rank == 1 ? _orange : null),
              _td(c.name, bold: rank == 1),
              _td('${c.count}', align: pw.TextAlign.center),
              _td('${fmt.format(c.spend)} JOD',
                  align: pw.TextAlign.right, bold: rank == 1),
              _td('${fmt.format(avg)} JOD',
                  align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  // ── Daily revenue table ────────────────────────────────────────────────────

  static pw.Widget _dailyTable(
    List<DayRevenue> days,
    int year,
    int month,
    NumberFormat fmt,
  ) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final byDay = {for (final d in days) d.day: d};
    final allDays = List.generate(daysInMonth, (i) {
      final d = i + 1;
      return byDay[d] ?? (day: d, revenue: 0.0, bookings: 0);
    });

    // Split into 3 columns of ~10 rows each for compact display
    final col1 = allDays.sublist(0, (daysInMonth / 3).ceil());
    final col2 = allDays.sublist(
        (daysInMonth / 3).ceil(),
        (daysInMonth * 2 / 3).ceil().clamp(0, daysInMonth));
    final col3 = allDays.sublist(
        (daysInMonth * 2 / 3).ceil().clamp(0, daysInMonth));

    pw.Widget _col(List<({int day, double revenue, int bookings})> col) {
      return pw.Expanded(
        child: pw.Table(
          border: pw.TableBorder.all(color: _grey300, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(28),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FixedColumnWidth(22),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _green),
              children: [_th('Day'), _th('Revenue'), _th('Bk.')],
            ),
            ...col.map((d) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: d.revenue > 0 ? PdfColors.white : _grey100),
                  children: [
                    _td('${d.day}',
                        align: pw.TextAlign.center,
                        color: d.revenue > 0 ? null : _grey600),
                    _td(
                      d.revenue > 0
                          ? '${fmt.format(d.revenue)} JOD'
                          : '—',
                      align: pw.TextAlign.right,
                      color: d.revenue > 0 ? null : _grey600,
                    ),
                    _td(d.bookings > 0 ? '${d.bookings}' : '—',
                        align: pw.TextAlign.center,
                        color: d.revenue > 0 ? null : _grey600),
                  ],
                )),
          ],
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _col(col1),
        pw.SizedBox(width: 6),
        _col(col2),
        pw.SizedBox(width: 6),
        _col(col3),
      ],
    );
  }

  // ── Transaction ledger ─────────────────────────────────────────────────────

  static pw.Widget _bookingsTable(List<BookingRow> rows, NumberFormat fmt) {
    return pw.Table(
      border: pw.TableBorder.all(color: _grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(18),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(22),
        4: const pw.FixedColumnWidth(36),
        5: const pw.FlexColumnWidth(2.2),
        6: const pw.FlexColumnWidth(1.8),
        7: const pw.FixedColumnWidth(46),
        8: const pw.FixedColumnWidth(46),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _green),
          children: [
            _th('#'),
            _th('Date'),
            _th('Time'),
            _th('Fld'),
            _th('Size'),
            _th('Customer'),
            _th('Phone'),
            _th('Price', align: pw.TextAlign.right),
            _th('Commission', align: pw.TextAlign.right),
          ],
        ),
        ...rows.asMap().entries.map((entry) {
          final i = entry.key;
          final b = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isEven ? PdfColors.white : _grey100),
            children: [
              _td('${i + 1}',
                  align: pw.TextAlign.center, color: _grey600),
              _td(b.date),
              _td(_fmt12(b.startTime)),
              _td('F${b.fieldNumber}', align: pw.TextAlign.center),
              _td(b.size),
              _td(b.name.isNotEmpty ? b.name : '—'),
              _td(b.phone.isNotEmpty ? b.phone : '—'),
              _td('${fmt.format(b.price)} JOD',
                  align: pw.TextAlign.right),
              _td('${fmt.format(b.commission)} JOD',
                  align: pw.TextAlign.right, color: _orange),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _ledgerTotals(
      MonthlyAccountingData data, NumberFormat fmt, double netRevenue) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _greenLight,
        borderRadius:
            const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _green, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          _totalPair('Total Transactions', '${data.bookingCount}'),
          pw.SizedBox(width: 24),
          _totalPair(
              'Gross Revenue', '${fmt.format(data.revenue)} JOD'),
          pw.SizedBox(width: 24),
          _totalPair(
              'Commission', '${fmt.format(data.commission)} JOD',
              valueColor: _orange),
          pw.SizedBox(width: 24),
          _totalPair(
              'Net Revenue', '${fmt.format(netRevenue)} JOD',
              valueColor: _green),
        ],
      ),
    );
  }

  static pw.Widget _totalPair(String label, String value,
      {PdfColor? valueColor}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(label,
            style:
                pw.TextStyle(fontSize: 8, color: _grey600)),
        pw.Text(value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            )),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 0),
        child: pw.Row(children: [
          pw.Container(
              width: 3,
              height: 13,
              color: PdfColor.fromHex('#068631')),
          pw.SizedBox(width: 6),
          pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ]),
      );

  static pw.Widget _th(String text,
          {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );

  static pw.Widget _td(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight:
                bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      );

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

