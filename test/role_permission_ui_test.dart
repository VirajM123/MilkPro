import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_distribution_app/config/app_features.dart';
import 'package:milk_distribution_app/config/app_theme.dart';
import 'package:milk_distribution_app/models/access_models.dart';
import 'package:milk_distribution_app/providers/auth_provider.dart';
import 'package:milk_distribution_app/providers/salesman_ui_store.dart';
import 'package:milk_distribution_app/screens/dashboard/dashboard_screen.dart';
import 'package:milk_distribution_app/services/app_navigation.dart';

void main() {
  tearDown(UiSession.instance.signOut);

  test('admin automatically has access to every feature', () {
    UiSession.instance.signInForUi('admin');

    expect(AppFeatures.visibleFor(UiSession.instance.currentUser), AppFeatures.all);
    expect(
      AppPermission.values.every(UiSession.instance.can),
      isTrue,
    );
  });

  test('salesman feature menu is permission filtered', () {
    UiSession.instance.signInForUi('SM001');
    final visible = AppFeatures.visibleFor(UiSession.instance.currentUser);

    expect(visible, contains(AppFeatures.customers));
    expect(visible, contains(AppFeatures.sales));
    expect(visible, isNot(contains(AppFeatures.purchase)));
    expect(visible, isNot(contains(AppFeatures.reports)));
  });

  testWidgets('salesman dashboard fits a small phone', (tester) async {
    UiSession.instance.signInForUi('SM001');
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const DashboardScreen()),
    );
    await tester.pump();

    expect(find.text('My Day'), findsOneWidget);
    expect(find.text('Purchase'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('central navigation guard opens access restricted state', (
    tester,
  ) async {
    UiSession.instance.signInForUi('SM001');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => AppNavigation.openWidget<void>(
                context,
                AppFeatures.reports,
                (_) => const Text('Protected report'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Access Restricted'), findsOneWidget);
    expect(find.text('Protected report'), findsNothing);
  });

  test('permission changes stay isolated in the local UI store', () {
    final store = SalesmanUiStore.instance;
    final original = Set<AppPermission>.from(store.byId('SM001').permissions);
    addTearDown(() => store.updatePermissions('SM001', original));

    store.updatePermissions('SM001', {AppPermission.customersView});

    expect(store.byId('SM001').permissions, {AppPermission.customersView});
  });
}
