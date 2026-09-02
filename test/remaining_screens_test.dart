import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_distribution_app/screens/customers/customers_screen.dart';
import 'package:milk_distribution_app/screens/expenses/expenses_screen.dart';
import 'package:milk_distribution_app/screens/ledger/ledger_screen.dart';
import 'package:milk_distribution_app/screens/payments/payments_screen.dart';
import 'package:milk_distribution_app/screens/reports/reports_screen.dart';
import 'package:milk_distribution_app/screens/settings/settings_screen.dart';

void main() {
  final screens = <String, Widget>{
    'Customers': const CustomersScreen(),
    'Payments': const PaymentsScreen(),
    'Ledger': const LedgerScreen(),
    'Reports': const ReportsScreen(),
    'Expenses': const ExpensesScreen(),
    'Settings': const SettingsScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} screen builds on a phone', (tester) async {
      _setTestSize(tester, const Size(412, 914));
      await tester.pumpWidget(MaterialApp(home: entry.value));
      await tester.pump();

      expect(find.text(entry.key), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}

void _setTestSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
