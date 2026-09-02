import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_distribution_app/config/app_theme.dart';
import 'package:milk_distribution_app/models/access_models.dart';
import 'package:milk_distribution_app/providers/auth_provider.dart';
import 'package:milk_distribution_app/screens/allocation/allocation_screen.dart';
import 'package:milk_distribution_app/screens/allocation/assign_allocation_page.dart';
import 'package:milk_distribution_app/screens/auth/login_screen.dart';
import 'package:milk_distribution_app/screens/auth/registration_screen.dart';
import 'package:milk_distribution_app/screens/common/access_denied_screen.dart';
import 'package:milk_distribution_app/screens/dashboard/dashboard_screen.dart';
import 'package:milk_distribution_app/screens/products/products_screen.dart';
import 'package:milk_distribution_app/screens/profile/profile_screen.dart';
import 'package:milk_distribution_app/screens/returns/return_settlement_screen.dart';
import 'package:milk_distribution_app/screens/routes/routes_screen.dart';
import 'package:milk_distribution_app/screens/salesmen/manage_access_screen.dart';
import 'package:milk_distribution_app/screens/salesmen/salesman_detail_screen.dart';
import 'package:milk_distribution_app/screens/salesmen/salesman_management_screen.dart';

void main() {
  tearDown(UiSession.instance.signOut);

  final screens = <String, Widget>{
    'Login': const LoginScreen(),
    'Registration': const RegistrationScreen(),
    'Admin Dashboard': const DashboardScreen(),
    'Products': const ProductsScreen(),
    'Allocation': const AllocationScreen(),
    'Assign Allocation': const AssignAllocationPage(
      routes: ['Route A'],
      salesmen: ['Mahesh'],
      products: ['Full Cream Milk', 'Ghee'],
    ),
    'Returns': const ReturnSettlementScreen(),
    'Routes': const RoutesScreen(),
    'Salesmen': const SalesmanManagementScreen(),
    'Salesman Detail': const SalesmanDetailScreen(salesmanId: 'SM001'),
    'Manage Access': const ManageAccessScreen(salesmanId: 'SM001'),
    'Profile': const ProfileScreen(),
    'Access Denied': const AccessDeniedScreen(),
  };

  testWidgets('login uses the KK ENTERPRISES firm name', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );
    expect(find.text('KK ENTERPRISES'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/img/Logo.png',
      ),
      findsOneWidget,
    );
  });

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders at 360x800', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      UiSession.instance.signInForRole(
        entry.key == 'Login' ? UserRole.salesman : UserRole.admin,
        entry.key == 'Login' ? 'SM001' : 'ADMIN',
      );

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: entry.value),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
