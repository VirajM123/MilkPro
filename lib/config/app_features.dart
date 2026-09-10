import 'package:flutter/material.dart';

import '../models/access_models.dart';

class AppFeature {
  const AppFeature({
    required this.title,
    required this.icon,
    required this.route,
    required this.permission,
    this.assetPath,
    this.adminVisible = true,
    this.salesmanVisible = true,
    this.adminOnly = false,
  });

  final String title;
  final IconData icon;
  final String route;
  final AppPermission permission;
  final String? assetPath;
  final bool adminVisible;
  final bool salesmanVisible;
  final bool adminOnly;
}

abstract final class AppFeatures {
  static const products = AppFeature(
    title: 'Products',
    icon: Icons.local_drink_outlined,
    route: '/products',
    permission: AppPermission.productsView,
    assetPath: 'assets/img/product_full_cream_milk.png',
  );
    static const suppliers = AppFeature(
    title: 'Suppliers',
    icon: Icons.local_shipping_outlined,
    route: '/suppliers',
    permission: AppPermission.suppliersView,
  );
  static const customers = AppFeature(
    title: 'Customers',
    icon: Icons.people_outline_rounded,
    route: '/customers',
    permission: AppPermission.customersView,
    assetPath: 'assets/img/TotalCustomer.png',
  );
  static const customerRates = AppFeature(
    title: 'Customer Rates',
    icon: Icons.price_change_outlined,
    route: '/customer-rates',
    permission: AppPermission.customerRatesManage,
  );
  static const allocation = AppFeature(
    title: 'Allocation',
    icon: Icons.inventory_2_outlined,
    route: '/allocation',
    permission: AppPermission.allocationView,
    assetPath: 'assets/img/AllocationImg.png',
  );
  static const sales = AppFeature(
    title: 'Sales',
    icon: Icons.receipt_long_outlined,
    route: '/sales',
    permission: AppPermission.salesView,
    assetPath: 'assets/img/SalesQui.png',
  );
  static const returns = AppFeature(
    title: 'Returns',
    icon: Icons.assignment_return_outlined,
    route: '/returns',
    permission: AppPermission.returnsManage,
    assetPath: 'assets/img/ReturnsSideNav.png',
  );
  static const collection = AppFeature(
    title: 'Collection',
    icon: Icons.payments_outlined,
    route: '/collection',
    permission: AppPermission.collectionView,
    assetPath: 'assets/img/CollectionQui.png',
  );
  static const routes = AppFeature(
    title: 'Routes',
    icon: Icons.route_outlined,
    route: '/routes',
    permission: AppPermission.routesView,
    assetPath: 'assets/img/Routes.png',
  );
  static const purchase = AppFeature(
    title: 'Purchase',
    icon: Icons.shopping_bag_outlined,
    route: '/purchase',
    permission: AppPermission.purchaseView,
    assetPath: 'assets/img/PurchaseSideNav.png',
  );
  static const reports = AppFeature(
    title: 'Reports',
    icon: Icons.analytics_outlined,
    route: '/reports',
    permission: AppPermission.reportsView,
    assetPath: 'assets/img/ReportsQui.png',
  );
  static const payments = AppFeature(
    title: 'Payments',
    icon: Icons.account_balance_wallet_outlined,
    route: '/payments',
    permission: AppPermission.paymentsView,
    assetPath: 'assets/img/PaymentsSideNav.png',
  );
  static const ledger = AppFeature(
    title: 'Ledger',
    icon: Icons.menu_book_outlined,
    route: '/ledger',
    permission: AppPermission.ledgerView,
    assetPath: 'assets/img/LedgerSideNav.png',
  );
  static const expenses = AppFeature(
    title: 'Expenses',
    icon: Icons.account_balance_wallet_outlined,
    route: '/expenses',
    permission: AppPermission.expensesView,
    assetPath: 'assets/img/ExpenseQui.png',
  );

static const all = <AppFeature>[
  customers,
  customerRates,
  products,
  suppliers,
  allocation,
  sales,
  returns,
  collection,
  routes,
  purchase,
  reports,
  expenses,
  payments,
  ledger,
];

  static List<AppFeature> visibleFor(AppUser user) => all
      .where((feature) {
        if (feature.adminOnly && user.role != UserRole.admin) return false;
        if (user.role == UserRole.admin) return feature.adminVisible;
        return feature.salesmanVisible && user.can(feature.permission);
      })
      .toList(growable: false);
}
