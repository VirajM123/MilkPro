import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_distribution_app/config/app_theme.dart';
import 'package:milk_distribution_app/providers/auth_provider.dart';
import 'package:milk_distribution_app/providers/customer_provider.dart';
import 'package:milk_distribution_app/providers/customer_rate_provider.dart';
import 'package:milk_distribution_app/providers/product_provider.dart';
import 'package:milk_distribution_app/screens/customer_rates/customer_rates_screen.dart';

void main() {
  tearDown(UiSession.instance.signOut);

  testWidgets('admin can view and edit a customer product rate', (
    tester,
  ) async {
    UiSession.instance.signInForUi('admin');
    final customer = CustomerStore.customers.first;
    final product = ProductStore.products.first;
    CustomerRateStore.useDefaultRate(customer, product);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CustomerRatesScreen()),
    );

    expect(find.text('Customer Rates'), findsOneWidget);
    expect(find.text(product.name), findsOneWidget);
    expect(find.text('Select Customer'), findsOneWidget);

    final rateField = find.byKey(
      ValueKey('customer-rate-${CustomerRateStore.productKey(product)}'),
    );
    await tester.enterText(rateField, '35.50');
    await tester.tap(find.byKey(const ValueKey('save-customer-rates')));
    await tester.pumpAndSettle();

    expect(CustomerRateStore.rateFor(customer, product).customRate, 35.50);
    expect(find.textContaining('custom rate saved'), findsOneWidget);
  });

  testWidgets('salesman cannot open the customer rates screen', (tester) async {
    UiSession.instance.signInForUi('SM001');

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CustomerRatesScreen()),
    );

    expect(find.text('Access Restricted'), findsOneWidget);
    expect(find.text('Customer Rates'), findsNothing);
  });

  testWidgets('customer rates screen fits a compact phone', (tester) async {
    UiSession.instance.signInForUi('admin');
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CustomerRatesScreen()),
    );
    await tester.pump();

    expect(find.text('Customer Rates'), findsOneWidget);
    expect(find.text('CURRENT RATE'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
