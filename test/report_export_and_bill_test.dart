import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_distribution_app/config/app_theme.dart';
import 'package:milk_distribution_app/models/sale_model.dart';
import 'package:milk_distribution_app/providers/auth_provider.dart';
import 'package:milk_distribution_app/providers/report_demo_provider.dart';
import 'package:milk_distribution_app/screens/reports/reports_screen.dart';
import 'package:milk_distribution_app/screens/sales/sales_screen.dart';
import 'package:milk_distribution_app/services/bill_pdf_service.dart';
import 'package:milk_distribution_app/services/excel_service.dart';
import 'package:milk_distribution_app/services/report_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(UiSession.instance.signOut);

  const reportTitles = <String>[
    'Current Stock',
    'Low Stock',
    'Stock Movement',
    'Product-wise Stock',
    'Sales Trend',
    'Purchase Trend',
    'Sales vs Purchase',
    'Product Trend',
    'Salesman-wise Outstanding',
    'Customer / Outlet-wise Outstanding',
    'Route-wise Outstanding',
    'Outstanding Ageing',
    'Salesman-wise Sales',
    'Customer-wise Sales',
    'Route-wise Sales',
    'Product-wise Sales',
    'Date-wise Sales',
    'Purchase Register',
    'Supplier-wise Purchase',
    'Product-wise Purchase',
    'Purchase Payment Due',
    'Collection Report',
    'Allocation Report',
    'Return Report',
    'Expense Report',
  ];

  test('every listed report has complete demo data', () {
    for (final title in reportTitles) {
      final report = ReportDemoProvider.forReport(title, 'Description');
      expect(report.columns, isNotEmpty, reason: title);
      expect(report.rows, isNotEmpty, reason: title);
      expect(report.metrics, hasLength(3), reason: title);
      expect(
        report.rows.every((row) => row.length == report.columns.length),
        isTrue,
        reason: title,
      );
    }
  });

  test('Excel and CSV exports contain report headers and rows', () {
    final report = ReportDemoProvider.forReport(
      'Current Stock',
      'Available stock',
    );
    final from = DateTime(2026, 8, 1);
    final to = DateTime(2026, 9, 2);

    final xlsx = ExcelService.buildExcelBytes(report, from: from, to: to);
    final workbook = Excel.decodeBytes(xlsx);
    final sheet = workbook.tables['Current Stock']!;
    expect(sheet.rows.length, greaterThanOrEqualTo(report.rows.length + 2));
    expect(
      sheet.rows.any(
        (row) =>
            row.isNotEmpty &&
            row.first?.value.toString() == 'KK ENTERPRISES - Current Stock',
      ),
      isTrue,
    );
    expect(
      sheet.rows.any(
        (row) =>
            row.isNotEmpty && row.first?.value.toString() == 'Full Cream Milk',
      ),
      isTrue,
    );

    final csvBytes = ExcelService.buildCsvBytes(report, from: from, to: to);
    final csvText = utf8.decode(csvBytes, allowMalformed: false);
    expect(csvText, contains('Current Stock'));
    expect(csvText, contains('Full Cream Milk'));
    expect(csvText, contains('Stock,Unit,Rate,Value'));
  });

  test('sales bill generator creates a valid PDF document', () async {
    final bytes = await BillPdfService.buildBill(
      SaleModel(
        id: 'SALE-TEST-001',
        date: DateTime(2026, 9, 2, 10, 30),
        customerName: 'Anita Patil',
        route: 'Route A',
        salesman: 'Mahesh Patil',
        product: 'Full Cream Milk',
        quantity: 12,
        rate: 32,
        paymentMode: 'Cash',
      ),
    );

    expect(bytes.length, greaterThan(2000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('report print generator creates a valid landscape PDF', () async {
    final report = ReportDemoProvider.forReport(
      'Salesman-wise Sales',
      'Sales by salesman',
    );
    final bytes = await ReportPdfService.buildReport(
      report,
      from: DateTime(2026, 8, 1),
      to: DateTime(2026, 9, 2),
      filterSummary: 'Salesman: All',
    );

    expect(bytes.length, greaterThan(2000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });

  testWidgets('report opens populated detail preview', (tester) async {
    UiSession.instance.signInForUi('admin');
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ReportsScreen()),
    );

    await tester.tap(find.text('Current Stock'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('report-filter-Current Stock')),
      findsOneWidget,
    );
    await tester.tap(find.text('VIEW REPORT'));
    await tester.pumpAndSettle();
    expect(find.text('STOCK VALUE'), findsOneWidget);
    expect(find.text('Full Cream Milk'), findsOneWidget);
    expect(find.byKey(const ValueKey('export-excel')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-csv')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-print')), findsOneWidget);
    expect(find.text('Search in this report'), findsOneWidget);
    expect(find.text('Report data'), findsOneWidget);
  });

  testWidgets('salesman report filter limits generated rows', (tester) async {
    UiSession.instance.signInForUi('admin');
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ReportsScreen()),
    );

    await tester.enterText(find.byType(TextField).first, 'Salesman-wise Sales');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salesman-wise Sales').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('report-filter-Salesman-wise Sales')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mahesh Patil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('VIEW REPORT'));
    await tester.pumpAndSettle();

    expect(find.text('Salesman: Mahesh Patil'), findsOneWidget);
    expect(find.text('Mahesh Patil'), findsWidgets);
    expect(find.text('Suresh Jadhav'), findsNothing);
  });

  testWidgets('sales history exposes PDF and WhatsApp bill actions', (
    tester,
  ) async {
    UiSession.instance.signInForUi('admin');
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SalesScreen()),
    );

    await tester.tap(find.byTooltip('Bill actions').first);
    await tester.pumpAndSettle();

    expect(find.text('View PDF Bill'), findsOneWidget);
    expect(find.text('Send on WhatsApp'), findsOneWidget);
  });
}
