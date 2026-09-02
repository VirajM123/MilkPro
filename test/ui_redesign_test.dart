import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_distribution_app/config/app_theme.dart';
import 'package:milk_distribution_app/providers/auth_provider.dart';
import 'package:milk_distribution_app/screens/allocation/assign_allocation_page.dart';
import 'package:milk_distribution_app/screens/auth/login_screen.dart';
import 'package:milk_distribution_app/screens/auth/registration_screen.dart';
import 'package:milk_distribution_app/screens/products/products_screen.dart';

void main() {
  tearDown(UiSession.instance.signOut);

  testWidgets('explicit salesman login opens the salesman workspace', (
    tester,
  ) async {
    _phone(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );

    await tester.tap(find.text('Salesman'));
    await tester.enterText(find.byType(TextFormField).at(0), 'SM001');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('LOGIN AS SALESMAN'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(find.text('My Day'), findsOneWidget);
    expect(UiSession.instance.currentUser.salesmanId, 'SM001');
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration and products fit a compact phone', (tester) async {
    _phone(tester, const Size(360, 640));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const RegistrationScreen()),
    );
    await tester.pump();
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Personal Details'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProductsScreen()),
    );
    await tester.pump();
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Full Cream Milk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('products can be added and opened for editing', (tester) async {
    _phone(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProductsScreen()),
    );

    await tester.tap(find.byTooltip('Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Add Product'), findsWidgets);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Paneer');
    await tester.enterText(fields.at(1), '200 gm pack');
    await tester.enterText(fields.at(2), 'Dairy');
    await tester.enterText(fields.at(3), '25');
    await tester.enterText(fields.at(4), '90');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Paneer'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Paneer'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Edit').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit Product'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('salesman products catalogue is read only', (tester) async {
    UiSession.instance.signInForUi('SM001');
    _phone(tester, const Size(390, 844));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProductsScreen()),
    );

    expect(find.text('Full Cream Milk'), findsOneWidget);
    expect(find.byTooltip('Add product'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Edit'), findsNothing);
  });

  testWidgets('allocation keeps litre and piece totals separate', (
    tester,
  ) async {
    _phone(tester, const Size(412, 1200));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AssignAllocationPage(
          routes: ['Route A'],
          salesmen: ['Mahesh'],
          products: [
            'Full Cream Milk',
            'Toned Milk',
            'Buffalo Milk',
            'Ghee',
            'Curd',
          ],
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Select all visible products'));
    await tester.pump();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '10');
    await tester.enterText(fields.at(4), '2');
    await tester.pump();

    expect(find.text('10 Ltr • 2 Pcs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
