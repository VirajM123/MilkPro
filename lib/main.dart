import 'package:flutter/material.dart';

import 'config/app_features.dart';
import 'config/app_theme.dart';
import 'models/access_models.dart';
import 'providers/auth_provider.dart';
import 'screens/allocation/allocation_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/collection/collection_screen.dart';
import 'screens/common/access_denied_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/customer_rates/customer_rates_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/ledger/ledger_screen.dart';
import 'screens/payments/payments_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/purchase/purchase_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/returns/return_settlement_screen.dart';
import 'screens/routes/routes_screen.dart';
import 'screens/sales/sales_screen.dart';
import 'screens/salesmen/salesman_management_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  runApp(const MilkDistributionApp());
}

class MilkDistributionApp extends StatelessWidget {
  const MilkDistributionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milk Distribution',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '/';
    if (name == '/') return _page(const LoginScreen(), settings);

    if (!UiSession.instance.isAuthenticated && name != '/register') {
      return _page(const LoginScreen(), settings);
    }

    final feature = AppFeatures.all
        .where((item) => item.route == name)
        .firstOrNull;
    if (feature != null &&
        ((feature.adminOnly && UiSession.instance.role != UserRole.admin) ||
            !UiSession.instance.can(feature.permission))) {
      return _page(const AccessDeniedScreen(), settings);
    }

    final screen = switch (name) {
      '/dashboard' => const DashboardScreen(),
      '/register' => const RegistrationScreen(),
      '/purchase' => const PurchaseScreen(),
      '/allocation' => const AllocationScreen(),
      '/collection' => const CollectionScreen(),
      '/sales' => const SalesScreen(),
      '/returns' => const ReturnSettlementScreen(),
      '/routes' => const RoutesScreen(),
      '/customers' => const CustomersScreen(),
      '/customer-rates' => const CustomerRatesScreen(),
      '/payments' => const PaymentsScreen(),
      '/ledger' => const LedgerScreen(),
      '/reports' => const ReportsScreen(),
      '/expenses' => const ExpensesScreen(),
      '/settings' => const SettingsScreen(),
      '/profile' => const ProfileScreen(),
      '/products' => const ProductsScreen(),
      '/salesmen' => const SalesmanManagementScreen(),
      _ => const DashboardScreen(),
    };
    return _page(screen, settings);
  }

  MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}
