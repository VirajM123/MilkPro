import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_distribution_app/screens/collection/collection_screen.dart';
import 'package:milk_distribution_app/screens/dashboard/dashboard_screen.dart';
import 'package:milk_distribution_app/screens/purchase/purchase_screen.dart';
import 'package:milk_distribution_app/screens/sales/sales_screen.dart';
import 'package:milk_distribution_app/providers/sales_provider.dart';

void main() {
  testWidgets('purchase screen builds', (WidgetTester tester) async {
    _setTestSize(tester, const Size(412, 914));
    await tester.pumpWidget(const MaterialApp(home: PurchaseScreen()));
    await tester.pump();

    expect(find.text('My Purchases'), findsOneWidget);
    expect(find.text('New Purchase'), findsOneWidget);
    await tester.tap(find.text('New Purchase'));
    await tester.pump();
    expect(find.text('Purchase'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved purchase returns to purchase history', (
    WidgetTester tester,
  ) async {
    _setTestSize(tester, const Size(412, 914));
    await tester.pumpWidget(const MaterialApp(home: PurchaseScreen()));
    await tester.pump();

    await tester.tap(find.text('New Purchase'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save Purchase'));
    await tester.tap(find.text('Save Purchase'));
    await tester.pump();

    expect(find.text('My Purchases'), findsOneWidget);
    expect(find.textContaining('PUR-2026-'), findsWidgets);
    expect(find.textContaining('Supplier: Gokul Dairy Farm'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('purchase products can be searched and phone quantity edited', (
    WidgetTester tester,
  ) async {
    _setTestSize(tester, const Size(412, 914));
    await tester.pumpWidget(const MaterialApp(home: PurchaseScreen()));
    await tester.tap(find.text('New Purchase'));
    await tester.pump();

    final search = find.byKey(const Key('purchaseProductSearch'));
    await tester.ensureVisible(search);
    await tester.enterText(search, 'Butter');
    await tester.pump();

    expect(find.text('Butter'), findsWidgets);
    expect(find.text('Raw Milk'), findsNothing);

    final quantity = find.byKey(const ValueKey('purchaseQty-Butter'));
    await tester.enterText(quantity, '12');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('collection screen builds', (WidgetTester tester) async {
    _setTestSize(tester, const Size(412, 914));
    await tester.pumpWidget(const MaterialApp(home: CollectionScreen()));
    await tester.pump();

    expect(find.text('Collection'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sales screen shows allotted milk', (WidgetTester tester) async {
    _setTestSize(tester, const Size(412, 914));
    await tester.pumpWidget(const MaterialApp(home: SalesScreen()));
    await tester.pump();

    expect(find.text('My Sales'), findsOneWidget);
    expect(find.text('Create New Sale'), findsOneWidget);
    await tester.tap(find.text('Create New Sale'));
    await tester.pump();

    expect(find.text('Sale Information'), findsOneWidget);
    expect(find.text('Customer Information'), findsOneWidget);
    expect(find.textContaining('500 ml Milk'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sales screen records multiple allotted products in one sale', (
    WidgetTester tester,
  ) async {
    _setTestSize(tester, const Size(412, 914));
    await tester.pumpWidget(const MaterialApp(home: SalesScreen()));
    await tester.pump();

    await tester.tap(find.text('Create New Sale'));
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Anita Patil');

    await tester.ensureVisible(find.text('500 ml Milk').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('500 ml Milk').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '10');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('1 L Milk').last);
    await tester.tap(find.textContaining('1 L Milk').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '5');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('2 items'), findsOneWidget);
    await tester.ensureVisible(find.text('Complete Sale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Sale'));
    await tester.pump();

    expect(find.textContaining('Customer: Anita Patil'), findsNWidgets(2));
    final saved = SalesStore.sales
        .where((sale) => sale.customerName == 'Anita Patil')
        .toList();
    expect(saved, hasLength(2));
    expect(
      saved.map((sale) => sale.product),
      containsAll(<String>['500 ml Milk', '1 L Milk']),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('purchase drawer menu opens purchase screen', (
    WidgetTester tester,
  ) async {
    _setTestSize(tester, const Size(800, 600));
    await tester.pumpWidget(
      MaterialApp(
        home: const DashboardScreen(),
        routes: <String, WidgetBuilder>{
          '/purchase': (_) => const PurchaseScreen(),
          '/collection': (_) => const CollectionScreen(),
          '/sales': (_) => const SalesScreen(),
        },
      ),
    );
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Purchase').last);
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collection drawer menu opens collection screen', (
    WidgetTester tester,
  ) async {
    _setTestSize(tester, const Size(800, 600));
    await tester.pumpWidget(
      MaterialApp(
        home: const DashboardScreen(),
        routes: <String, WidgetBuilder>{
          '/purchase': (_) => const PurchaseScreen(),
          '/collection': (_) => const CollectionScreen(),
          '/sales': (_) => const SalesScreen(),
        },
      ),
    );
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collection').last);
    await tester.pumpAndSettle();

    expect(find.byType(CollectionScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('purchase opens from dashboard on a phone without blank frame', (
    WidgetTester tester,
  ) async {
    _setTestSize(tester, const Size(412, 914));
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Purchase').last);
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseScreen), findsOneWidget);
    expect(find.text('My Purchases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'collection opens from dashboard on a phone without blank frame',
    (WidgetTester tester) async {
      _setTestSize(tester, const Size(412, 914));
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Collection').last);
      await tester.pumpAndSettle();

      expect(find.byType(CollectionScreen), findsOneWidget);
      expect(find.text("Today's Overview"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sales drawer menu opens sales screen', (
    WidgetTester tester,
  ) async {
    _setTestSize(tester, const Size(800, 600));
    await tester.pumpWidget(
      MaterialApp(
        home: const DashboardScreen(),
        routes: <String, WidgetBuilder>{
          '/purchase': (_) => const PurchaseScreen(),
          '/collection': (_) => const CollectionScreen(),
          '/sales': (_) => const SalesScreen(),
        },
      ),
    );
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sales').last);
    await tester.pumpAndSettle();

    expect(find.byType(SalesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setTestSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
