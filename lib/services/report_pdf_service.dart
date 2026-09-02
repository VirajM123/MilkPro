import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_model.dart';

abstract final class ReportPdfService {
  static Future<Uint8List> buildReport(
    ReportData report, {
    required DateTime from,
    required DateTime to,
    String? filterSummary,
  }) async {
    final document = pw.Document(
      title: report.title,
      author: 'KK ENTERPRISES',
      subject: 'Business report',
    );
    final navy = PdfColor.fromHex('#0B2D69');
    final primary = PdfColor.fromHex('#1665E8');
    final paleBlue = PdfColor.fromHex('#EDF5FF');
    final border = PdfColor.fromHex('#DCE4EF');
    final muted = PdfColor.fromHex('#64748B');

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(),
        ),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 7,
                  height: 38,
                  decoration: pw.BoxDecoration(
                    color: primary,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                ),
                pw.SizedBox(width: 11),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KK ENTERPRISES',
                        style: pw.TextStyle(
                          color: navy,
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        report.title,
                        style: pw.TextStyle(color: muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  '${_date(from)} - ${_date(to)}',
                  style: pw.TextStyle(
                    color: navy,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (filterSummary != null) ...[
              pw.SizedBox(height: 7),
              pw.Text(
                filterSummary,
                style: pw.TextStyle(color: muted, fontSize: 8),
              ),
            ],
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: border)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${report.rows.length} record${report.rows.length == 1 ? '' : 's'}',
                style: pw.TextStyle(color: muted, fontSize: 8),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(color: muted, fontSize: 8),
              ),
            ],
          ),
        ),
        build: (_) => [
          if (report.metrics.isNotEmpty)
            pw.Row(
              children: report.metrics
                  .map(
                    (metric) => pw.Expanded(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.only(right: 8),
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: paleBlue,
                          border: pw.Border.all(color: border),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              metric.label.toUpperCase(),
                              style: pw.TextStyle(color: muted, fontSize: 7),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              metric.value,
                              style: pw.TextStyle(
                                color: navy,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: report.columns,
            data: report.rows
                .map(
                  (row) => List.generate(
                    report.columns.length,
                    (index) => _display(row[index], report.columns[index]),
                  ),
                )
                .toList(growable: false),
            headerDecoration: pw.BoxDecoration(color: navy),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: pw.TextStyle(color: navy, fontSize: 7),
            oddRowDecoration: pw.BoxDecoration(color: paleBlue),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: border, width: .5),
              bottom: pw.BorderSide(color: border, width: .7),
              left: pw.BorderSide(color: border, width: .7),
              right: pw.BorderSide(color: border, width: .7),
              top: pw.BorderSide(color: border, width: .7),
            ),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 7,
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  static String _display(Object value, String column) {
    if (value is num && _isCurrencyColumn(column)) {
      return 'Rs. ${value.toStringAsFixed(2)}';
    }
    return value.toString();
  }

  static bool _isCurrencyColumn(String header) {
    final value = header.toLowerCase();
    return value.contains('amount') ||
        value.contains('value') ||
        value == 'sales' ||
        value == 'purchase' ||
        value == 'collected' ||
        value == 'paid' ||
        value == 'due' ||
        value == 'outstanding' ||
        value.contains('difference') ||
        value.contains('average bill');
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
