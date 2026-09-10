import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

import '../models/sale_model.dart';
import '../providers/customer_provider.dart';

abstract final class BillPdfService {
  static Future<Uint8List> buildBill(
    SaleModel sale, {
    Uint8List? logoBytes,
  }) async {
    pw.MemoryImage? logo;
    if (logoBytes != null) {
      logo = pw.MemoryImage(logoBytes);
    } else {
      try {
        final data = await rootBundle.load('assets/img/Logo.png');
        logo = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        logo = null;
      }
    }

    final document = pw.Document(
      title: 'Sales Bill ${sale.id}',
      author: 'KK ENTERPRISES',
      subject: 'Milk distribution sales invoice',
    );
    final blue = PdfColor.fromHex('#0B2D69');
    final primary = PdfColor.fromHex('#1665E8');
    final border = PdfColor.fromHex('#DCE4EF');
    final muted = PdfColor.fromHex('#64748B');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Column(
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Container(
                    height: 64,
                    width: 64,
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: border),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                if (logo != null) pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KK ENTERPRISES',
                        style: pw.TextStyle(
                          color: blue,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Milk Distribution Management',
                        style: pw.TextStyle(color: muted, fontSize: 9),
                      ),
                      pw.Text(
                        'Main Distribution Centre, Maharashtra',
                        style: pw.TextStyle(color: muted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: pw.BoxDecoration(
                    color: primary,
                    borderRadius: pw.BorderRadius.circular(7),
                  ),
                  child: pw.Text(
                    'SALES BILL',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Divider(color: border),
          ],
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: border)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Thank you for your business.',
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
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _detailBlock(
                  'BILL TO',
                  [sale.customerName, sale.route, customerMobileFor(sale)],
                  blue,
                  muted,
                  border,
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Expanded(
                child: _detailBlock(
                  'INVOICE DETAILS',
                  [
                    'Bill No: ${sale.id}',
                    'Date: ${_date(sale.date)}',
                    'Salesman: ${sale.salesman}',
                    'Payment: ${sale.paymentMode}',
                  ],
                  blue,
                  muted,
                  border,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.TableHelper.fromTextArray(
            headers: const ['#', 'Product', 'Quantity', 'Rate', 'Amount'],
            data: sale.products.isNotEmpty
                ? [
                    for (int i = 0; i < sale.products.length; i++)
                      [
                        '${i + 1}',
                        sale.products[i].variant.isNotEmpty &&
                                !sale.products[i].productName.toLowerCase().contains(
                                      sale.products[i].variant.toLowerCase(),
                                    )
                            ? '${sale.products[i].productName} (${sale.products[i].variant})'
                            : sale.products[i].productName,
                        '${sale.products[i].quantity} ${sale.products[i].unit}',
                        'Rs. ${sale.products[i].rate.toStringAsFixed(2)}',
                        'Rs. ${sale.products[i].amount.toStringAsFixed(2)}',
                      ],
                  ]
                : [
                    [
                      '1',
                      sale.product.isNotEmpty ? sale.product : 'Product',
                      '${sale.quantity} Pcs',
                      'Rs. ${sale.rate.toStringAsFixed(2)}',
                      'Rs. ${sale.total.toStringAsFixed(2)}',
                    ],
                  ],
            border: pw.TableBorder.all(color: border, width: .7),
            headerDecoration: pw.BoxDecoration(color: blue),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FlexColumnWidth(2.4),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.3),
            },
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 230,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F3F7FF'),
                border: pw.Border.all(color: border),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', sale.total, muted),
                  pw.SizedBox(height: 6),
                  if (sale.cashAmount > 0) ...[
                    _totalRow('Cash Paid', sale.cashAmount, muted),
                    pw.SizedBox(height: 4),
                  ],
                  if (sale.upiAmount > 0) ...[
                    _totalRow('UPI Paid', sale.upiAmount, muted),
                    pw.SizedBox(height: 4),
                  ],
                  if (sale.bankTransferAmount > 0) ...[
                    _totalRow('Bank Transfer', sale.bankTransferAmount, muted),
                    pw.SizedBox(height: 4),
                  ],
                  if (sale.outstandingAmount > 0) ...[
                    _totalRow('Balance Due', sale.outstandingAmount, PdfColor.fromHex('#DC2626')),
                    pw.SizedBox(height: 4),
                  ],
                  pw.Divider(color: border),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Grand Total',
                        style: pw.TextStyle(
                          color: blue,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Rs. ${sale.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 34),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'This is a computer-generated bill.',
                style: pw.TextStyle(color: muted, fontSize: 8),
              ),
              pw.Column(
                children: [
                  pw.SizedBox(height: 28),
                  pw.Container(width: 150, height: .7, color: border),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Authorised Signatory',
                    style: pw.TextStyle(color: muted, fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<String> downloadBill(SaleModel sale, Uint8List bytes) {
    return FileSaver.instance.saveFile(
      name: billFileName(sale).replaceAll('.pdf', ''),
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<bool> openWhatsApp(SaleModel sale, String mobile) {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    final phone = digits.length == 10 ? '91$digits' : digits;
    final message = Uri.encodeComponent(
      'Hello ${sale.customerName}, your bill ${sale.id} from KK ENTERPRISES '
      'for Rs. ${sale.total.toStringAsFixed(2)} is ready. '
      'Please find the downloaded PDF bill and attach it here.',
    );
    return launchUrl(
      Uri.parse('https://wa.me/$phone?text=$message'),
      mode: LaunchMode.platformDefault,
    );
  }

  static String customerMobileFor(SaleModel sale) {
    if (sale.customerMobile.trim().isNotEmpty) {
      return sale.customerMobile.trim();
    }
    for (final customer in CustomerStore.customers) {
      if (customer.name.toLowerCase() == sale.customerName.toLowerCase()) {
        return customer.mobile;
      }
    }
    const demoMobiles = <String, String>{
      'Rajesh Dairy': '9876500011',
      'Fresh Farms': '9876500012',
      'Green Dairy': '9876500013',
      'Krishna Dairy': '9876500014',
      'Sai Dairy': '9876500015',
      'Om Dairy': '9876500016',
    };
    return demoMobiles[sale.customerName] ?? '';
  }

  static String billFileName(SaleModel sale) =>
      'sales_bill_${sale.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';

  static pw.Widget _detailBlock(
    String title,
    List<String> lines,
    PdfColor blue,
    PdfColor muted,
    PdfColor border,
  ) => pw.Container(
    padding: const pw.EdgeInsets.all(13),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            color: blue,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        for (final line in lines.where((value) => value.isNotEmpty))
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              line,
              style: pw.TextStyle(color: muted, fontSize: 9),
            ),
          ),
      ],
    ),
  );

  static pw.Widget _totalRow(String label, double amount, PdfColor color) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: color, fontSize: 9)),
          pw.Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(color: color, fontSize: 9),
          ),
        ],
      );

  static String salesReportFileName({DateTime? date}) {
    final d = date ?? DateTime.now();
    return 'Sales_Report_${d.year}_${d.month.toString().padLeft(2, '0')}_${d.day.toString().padLeft(2, '0')}.pdf';
  }

  static Future<String> downloadSalesReport(Uint8List bytes, {DateTime? date}) {
    return FileSaver.instance.saveFile(
      name: salesReportFileName(date: date).replaceAll('.pdf', ''),
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<Uint8List> buildSalesReport(
    List<SaleModel> sales, {
    DateTime? selectedDate,
    Uint8List? logoBytes,
  }) async {
    pw.MemoryImage? logo;
    if (logoBytes != null) {
      logo = pw.MemoryImage(logoBytes);
    } else {
      try {
        final data = await rootBundle.load('assets/img/Logo.png');
        logo = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        logo = null;
      }
    }

    final document = pw.Document(
      title: 'Sales Report',
      author: 'KK ENTERPRISES',
      subject: 'Milk distribution sales report',
    );
    final blue = PdfColor.fromHex('#0B2D69');
    final primary = PdfColor.fromHex('#1665E8');
    final border = PdfColor.fromHex('#DCE4EF');
    final muted = PdfColor.fromHex('#64748B');

    int totalQty = 0;
    double grandTotal = 0;
    double totalCash = 0;
    double totalUpi = 0;
    double totalBank = 0;
    double totalDue = 0;
    int cancelledCount = 0;

    for (final s in sales) {
      if (s.isCancelled) {
        cancelledCount++;
      } else {
        totalQty += s.totalQuantity;
        grandTotal += s.total;
        totalCash += s.cashAmount;
        totalUpi += s.upiAmount;
        totalBank += s.bankTransferAmount;
        totalDue += s.outstandingAmount;
      }
    }

    final activeCount = sales.length - cancelledCount;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Container(
                    height: 52,
                    width: 52,
                    padding: const pw.EdgeInsets.all(3),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: border),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                if (logo != null) pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KK ENTERPRISES',
                        style: pw.TextStyle(
                          color: blue,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'SALES SUMMARY REPORT',
                        style: pw.TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        selectedDate != null
                            ? 'Report Date: ${_date(selectedDate)}'
                            : 'Generated on: ${_date(DateTime.now())}',
                        style: pw.TextStyle(color: muted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F3F7FF'),
                    border: pw.Border.all(color: border),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Invoices: ${sales.length}', style: pw.TextStyle(color: blue, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Active: $activeCount | Cancelled: $cancelledCount', style: pw.TextStyle(color: muted, fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: border),
          ],
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: border))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('KK ENTERPRISES - Confidential Sales Summary', style: pw.TextStyle(color: muted, fontSize: 8)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(color: muted, fontSize: 8)),
            ],
          ),
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headers: const ['#', 'Bill No', 'Customer', 'Route', 'Quantity', 'Mode', 'Status', 'Total'],
            data: [
              for (int i = 0; i < sales.length; i++)
                [
                  '${i + 1}',
                  sales[i].id,
                  sales[i].customerName,
                  sales[i].route,
                  '${sales[i].totalQuantity} Pcs',
                  sales[i].paymentMode,
                  sales[i].isCancelled ? 'CANCELLED' : sales[i].paymentStatus,
                  'Rs. ${sales[i].total.toStringAsFixed(2)}',
                ],
            ],
            border: pw.TableBorder.all(color: border, width: .6),
            headerDecoration: pw.BoxDecoration(color: blue),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(1.6),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FlexColumnWidth(1.6),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.2),
              6: const pw.FlexColumnWidth(1.3),
              7: const pw.FlexColumnWidth(1.5),
            },
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 260,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F3F7FF'),
                border: pw.Border.all(color: border),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _totalRow('Active Sales Count', activeCount.toDouble(), muted),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Quantity Sold', style: pw.TextStyle(color: muted, fontSize: 9)),
                      pw.Text('$totalQty Pcs', style: pw.TextStyle(color: muted, fontSize: 9)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  _totalRow('Cash Collected', totalCash, muted),
                  pw.SizedBox(height: 5),
                  _totalRow('UPI Collected', totalUpi, muted),
                  pw.SizedBox(height: 5),
                  if (totalBank > 0) ...[
                    _totalRow('Bank Transfer', totalBank, muted),
                    pw.SizedBox(height: 5),
                  ],
                  if (totalDue > 0) ...[
                    _totalRow('Outstanding Due', totalDue, PdfColor.fromHex('#DC2626')),
                    pw.SizedBox(height: 5),
                  ],
                  pw.Divider(color: border),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Grand Total Amount',
                        style: pw.TextStyle(color: blue, fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Rs. ${grandTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(color: primary, fontSize: 11.5, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
