import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/utils/invoice_pdf_save_stub.dart'
    if (dart.library.html) 'package:ehjez_admin/utils/invoice_pdf_save_web.dart'
    if (dart.library.io) 'package:ehjez_admin/utils/invoice_pdf_save_io.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceGenerator {
  static final _green = PdfColor.fromHex('#068631');
  static final _grey = PdfColors.grey700;
  static final _headerStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
  );
  static final _cellStyle = const pw.TextStyle(fontSize: 9);

  static Future<void> generateAndDownload({
    required MonthlyAccountingData data,
    required int year,
    required int month,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
    final netProfit = data.revenue - data.commission;
    final fmt = NumberFormat('#,##0.00');

    // ── Page 1: Summary ────────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(data.courtName, monthName),
            pw.SizedBox(height: 24),
            _summaryTable(data, fmt, netProfit),
            pw.SizedBox(height: 24),
            if (data.bySize.isNotEmpty) ...[
              _sectionTitle('Revenue by Field Size'),
              pw.SizedBox(height: 8),
              _sizeTable(data, fmt),
              pw.SizedBox(height: 24),
            ],
            _footer(),
          ],
        ),
      ),
    );

    // ── Page 2: Detailed bookings (only if there are any) ─────────────────────
    if (data.bookings.isNotEmpty) {
      const rowsPerPage = 30;
      final chunks = <List<BookingRow>>[];
      for (var i = 0; i < data.bookings.length; i += rowsPerPage) {
        chunks.add(data.bookings.sublist(
          i,
          (i + rowsPerPage).clamp(0, data.bookings.length),
        ));
      }
      for (final chunk in chunks) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionTitle('Detailed Bookings — $monthName'),
                pw.SizedBox(height: 8),
                _bookingsTable(chunk, fmt),
              ],
            ),
          ),
        );
      }
    }

    final bytes = await pdf.save();
    await saveSummaryPdf(
      bytes,
      'invoice_${data.courtName.replaceAll(' ', '_')}_${year}_$month.pdf',
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

  static pw.Widget _header(String courtName, String monthName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#068631'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Monthly Financial Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                courtName,
                style: pw.TextStyle(fontSize: 13, color: PdfColors.white),
              ),
              pw.Text(
                monthName,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
          pw.Text(
            'ehjez',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryTable(
    MonthlyAccountingData data,
    NumberFormat fmt,
    double netProfit,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(
          inside: const pw.BorderSide(color: PdfColors.grey300),
        ),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _green),
            children: [
              _th('Metric'),
              _th('Value'),
            ],
          ),
          _summaryRow('Total Revenue', '${fmt.format(data.revenue)} JOD'),
          _summaryRow('Total Bookings', '${data.bookingCount}'),
          _summaryRow('Commission (Ehjez)', '${fmt.format(data.commission)} JOD', red: true),
          _summaryRow('Net Profit', '${fmt.format(netProfit)} JOD', bold: true, green: true),
        ],
      ),
    );
  }

  static pw.Widget _sizeTable(MonthlyAccountingData data, NumberFormat fmt) {
    final totalRev = data.revenue > 0 ? data.revenue : 1.0;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _green),
          children: [
            _th('Size'),
            _th('Bookings'),
            _th('Revenue'),
            _th('Share'),
          ],
        ),
        ...data.bySize.map((s) => pw.TableRow(
              children: [
                _td(s.size),
                _td('${s.bookings}'),
                _td('${fmt.format(s.revenue)} JOD'),
                _td('${(s.revenue / totalRev * 100).toStringAsFixed(1)}%'),
              ],
            )),
      ],
    );
  }

  static pw.Widget _bookingsTable(List<BookingRow> rows, NumberFormat fmt) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2.5),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _green),
          children: [
            _th('Date'),
            _th('Time'),
            _th('Field'),
            _th('Size'),
            _th('Customer'),
            _th('Price'),
            _th('Commission'),
          ],
        ),
        ...rows.asMap().entries.map((entry) {
          final i = entry.key;
          final b = entry.value;
          final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('#F9F9F9');
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _td(b.date),
              _td(_fmt12(b.startTime)),
              _td('F${b.fieldNumber}'),
              _td(b.size),
              _td(b.name.isNotEmpty ? b.name : b.phone),
              _td('${fmt.format(b.price)} JOD'),
              _td('${fmt.format(b.commission)} JOD'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Generated on ${DateFormat('dd MMM yyyy').format(DateTime.now())} · Ehjez Platform',
        style: pw.TextStyle(fontSize: 9, color: _grey),
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _green,
        ),
      );

  static pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(text, style: _headerStyle),
      );

  static pw.Widget _td(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Text(text, style: _cellStyle),
      );

  static pw.TableRow _summaryRow(
    String label,
    String value, {
    bool bold = false,
    bool green = false,
    bool red = false,
  }) {
    final color = green
        ? PdfColor.fromHex('#068631')
        : red
            ? PdfColors.red700
            : PdfColors.black;
    final style = pw.TextStyle(
      fontSize: 11,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Text(label, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Text(value, style: style),
        ),
      ],
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
