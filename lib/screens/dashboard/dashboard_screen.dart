import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

import '../../config/app_features.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_navigation.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../allocation/allocation_screen.dart';
import '../collection/collection_screen.dart';
import '../customers/customers_screen.dart';
import '../customer_rates/customer_rates_screen.dart';
import '../expenses/expenses_screen.dart';
import '../profile/profile_screen.dart';
import '../products/products_screen.dart';
import '../payments/payments_screen.dart';
import '../ledger/ledger_screen.dart';
import '../purchase/purchase_screen.dart';
import '../reports/reports_screen.dart';
import '../returns/return_settlement_screen.dart';
import '../routes/routes_screen.dart';
import '../sales/sales_screen.dart';
import '../salesmen/salesman_management_screen.dart';
import '../suppliers/supplier_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  _DashboardData _dashboard = const _DashboardData();

  bool _dashboardLoading = true;

  String _dashboardError = '';

  @override
  void initState() {
    super.initState();

    _loadDashboard();
  }

  AppUser get user => UiSession.instance.currentUser;

  Future<void> _loadDashboard() async {
    try {
      if (mounted) {
        setState(() {
          _dashboardLoading = true;

          _dashboardError = '';
        });
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/dashboard/summary'),
        headers: <String, String>{
          'Content-Type': 'application/json',

          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode != 200 ||
          decoded is! Map ||
          decoded['success'] != true) {
        String message = 'Unable to load dashboard.';

        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }

        throw Exception(message);
      }

      final data = decoded['data'];

      if (data is! Map) {
        throw Exception('Dashboard data not found.');
      }

      if (!mounted) return;

      setState(() {
        _dashboard = _DashboardData.fromJson(Map<String, dynamic>.from(data));

        _dashboardLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _dashboardLoading = false;

        _dashboardError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _money(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
    }

    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)}L';
    }

    return '₹${value.toStringAsFixed(0)}';
  }

  String _qty(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _percent(double value) {
    return '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UiSession.instance,
      builder: (context, _) => Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: user.role == UserRole.admin
            ? _adminDashboard()
            : _salesmanDashboard(),
        bottomNavigationBar: _bottomNavigation(),
      ),
    );
  }

  Widget _adminDashboard() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header(admin: true)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          sliver: SliverList.list(
            children: [
              const AppSectionTitle(
                title: 'Today Summary',
                subtitle: 'Live business overview',
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: "Today's Sales",

                      value: _money(_dashboard.todaySalesAmount),

                      icon: Icons.receipt_long_outlined,

                      color: AppColors.success,

                      caption: '${_dashboard.todayBills} bills',

                      imagePath: 'assets/img/TotalSales.png',
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: SummaryCard(
                      label: "Today's Collection",

                      value: _money(_dashboard.todayCollectionAmount),

                      icon: Icons.payments_outlined,

                      color: AppColors.primary,

                      caption: '${_dashboard.collectionReceipts} receipts',

                      imagePath: 'assets/img/TotalCollection.png',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'Pending Collection',

                      value: _money(_dashboard.pendingCollection),

                      icon: Icons.schedule_rounded,

                      color: AppColors.warning,

                      caption: '${_dashboard.pendingAccounts} accounts',

                      imagePath: 'assets/img/DueAmt.png',
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: SummaryCard(
                      label: 'Sales Bills Today',

                      value: _dashboard.todayBills.toString(),

                      icon: Icons.shopping_bag_outlined,

                      color: AppColors.purple,

                      caption: '${_qty(_dashboard.todaySalesQuantity)} qty',

                      imagePath: 'assets/img/SalesOverview.png',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const AppSectionTitle(
                title: 'Quick Actions',
                subtitle: 'Frequently used operations',
              ),
              const SizedBox(height: 11),
              _featureGrid(AppFeatures.all.take(8).toList()),
              const SizedBox(height: 22),
              const AppSectionTitle(
                title: "Today's Distribution",
                subtitle: 'Operational progress',
              ),
              const SizedBox(height: 11),
              _operationsCard(),
              const SizedBox(height: 22),
              const AppSectionTitle(
                title: 'Management',
                subtitle: 'Team, access and workspace controls',
              ),
              const SizedBox(height: 11),
              _managementCards(),
              const SizedBox(height: 20),
              _footerBanner(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _salesmanDashboard() {
    final features = AppFeatures.visibleFor(user);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header(admin: false)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          sliver: SliverList.list(
            children: [
              const AppSectionTitle(
                title: 'Today at a Glance',
                subtitle: 'Your field activity',
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'Sales Bills',

                      value: _dashboard.todayBills.toString(),

                      icon: Icons.shopping_bag_outlined,

                      color: AppColors.primary,

                      caption: 'Today',

                      imagePath: 'assets/img/TotalQuantityAllocation.png',
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: SummaryCard(
                      label: 'Sales',

                      value: _money(_dashboard.todaySalesAmount),

                      icon: Icons.receipt_long_outlined,

                      color: AppColors.success,

                      caption: '${_qty(_dashboard.todaySalesQuantity)} qty',

                      imagePath: 'assets/img/TotalSales.png',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'Collection',

                      value: _money(_dashboard.todayCollectionAmount),

                      icon: Icons.payments_outlined,

                      color: AppColors.purple,

                      caption: '${_dashboard.collectionReceipts} receipts',

                      imagePath: 'assets/img/TotalCollection.png',
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: SummaryCard(
                      label: 'Pending Delivery',

                      value: _qty(_dashboard.pendingDeliveryQuantity),

                      icon: Icons.local_shipping_outlined,

                      color: AppColors.warning,

                      caption: 'Qty remaining',

                      imagePath: 'assets/img/TotalAllocationVehicle.png',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const AppSectionTitle(
                title: 'My Day',
                subtitle: 'Daily route workflow',
              ),
              const SizedBox(height: 11),
              _workflowCard(),
              const SizedBox(height: 22),
              const AppSectionTitle(
                title: 'Quick Actions',
                subtitle: 'Only your enabled features are shown',
              ),
              const SizedBox(height: 11),
              _featureGrid(features),
              const SizedBox(height: 22),
              const AppSectionTitle(
                title: "Today's Customers",
                subtitle: 'Next visits on your route',
              ),
              const SizedBox(height: 11),
              _customerPreview(),
              const SizedBox(height: 22),
              const AppSectionTitle(title: "Today's Progress"),
              const SizedBox(height: 11),
              _salesmanProgress(),
              const SizedBox(height: 20),
              _footerBanner(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header({required bool admin}) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        image: DecorationImage(
          image: const AssetImage('assets/img/Dashboardback.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.primaryDeep.withValues(alpha: .62),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 14, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Menu',
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, ${user.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      admin
                          ? user.branch
                          : "Today's Route · ${user.route ?? 'Unassigned'}",
                      style: const TextStyle(
                        color: Color(0xFFCADBFA),
                        fontSize: 11.5,
                      ),
                    ),
                    if (!admin) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        children: [
                          _headerChip(user.salesmanId ?? 'Salesman'),
                          _headerChip('On Duty', dot: true),
                          _headerChip('Synced 8:42 AM'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Notifications',
              ),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(24),
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  child: Text(
                    _initials(user.name),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerChip(String label, {bool dot = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          const SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF67E89B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _featureGrid(List<AppFeature> features) {
    if (features.isEmpty) {
      return const Card(
        child: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'No Features Enabled',
          message: 'Contact your administrator to request access.',
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 350 ? 3 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: .92,
          ),
          itemBuilder: (context, index) {
            final feature = features[index];
            return FeatureActionCard(
              title: feature.title,
              icon: feature.icon,
              imagePath: feature.assetPath,
              onTap: () => _openFeature(feature),
            );
          },
        );
      },
    );
  }

  Widget _operationsCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),

      child: Column(
        children: [
          _progressRow(
            'Allocation dispatched',

            '${_qty(_dashboard.todayAllocatedQuantity)} qty',

            _dashboard.todayAllocatedQuantity > 0 ? 1 : 0,

            AppColors.primary,
          ),

          const SizedBox(height: 15),

          _progressRow(
            'Sales completed',

            '${_qty(_dashboard.todaySalesQuantity)} / '
                '${_qty(_dashboard.todayAllocatedQuantity)} qty',

            _dashboard.salesProgress,

            AppColors.success,
          ),

          const SizedBox(height: 15),

          _progressRow(
            'Collections received',

            '${_money(_dashboard.todayCollectionAmount)} / '
                '${_money(_dashboard.todaySalesAmount)}',

            _dashboard.collectionProgress,

            AppColors.purple,
          ),

          const SizedBox(height: 15),

          _progressRow(
            'Good returns received',

            '${_qty(_dashboard.todayReturnQuantity)} qty',

            _dashboard.returnProgress,

            AppColors.warning,
          ),
        ],
      ),
    ),
  );
  Widget _progressRow(
    String label,
    String value,
    double progress,
    Color color,
  ) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      LinearProgressIndicator(
        value: progress,
        minHeight: 7,
        color: color,
        backgroundColor: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
      ),
    ],
  );

  Widget _managementCards() => Row(
    children: [
      Expanded(
        child: FeatureActionCard(
          title: 'Salesmen',
          icon: Icons.badge_outlined,
          imagePath: 'assets/img/TotalSalesmanAllocation.png',
          onTap: _openSalesmen,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: FeatureActionCard(
          title: 'Feature Access',
          icon: Icons.admin_panel_settings_outlined,
          imagePath: 'assets/img/AllocationSideNav.png',
          onTap: _openSalesmen,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: FeatureActionCard(
          title: 'Settings',
          icon: Icons.settings_outlined,
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
      ),
    ],
  );

  Widget _workflowCard() {
    const steps = <(String, IconData)>[
      ('Start Route', Icons.play_circle_outline_rounded),
      ('Visit Customers', Icons.people_outline_rounded),
      ('Take Orders', Icons.shopping_bag_outlined),
      ('Collect Payments', Icons.payments_outlined),
      ('Complete Delivery', Icons.local_shipping_outlined),
      ('Return Settlement', Icons.assignment_return_outlined),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: List.generate(steps.length, (index) {
            final completed = index < 2;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: completed
                            ? AppColors.success
                            : AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: completed
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 17,
                            )
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                    ),
                    if (index != steps.length - 1)
                      Container(width: 1, height: 24, color: AppColors.border),
                  ],
                ),
                const SizedBox(width: 11),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Icon(
                    steps[index].$2,
                    size: 19,
                    color: completed
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      steps[index].$1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (index == 2)
                  const StatusChip(label: 'Next', color: AppColors.primary),
              ],
            );
          }),
        ),
      ),
    );
  }

Widget _customerPreview() {
  final customers = _dashboard.todayCustomers.take(3).toList();

  if (customers.isEmpty) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        child: AppEmptyState(
          icon: Icons.people_outline_rounded,
          title: 'No Customers',
          message: 'No customers are assigned to your route.',
        ),
      ),
    );
  }

  return Card(
    child: Column(
      children: List.generate(
        customers.length,
        (index) {
          final customer =
              customers[index];

          final firstLetter =
              customer.customerName
                      .trim()
                      .isNotEmpty
                  ? customer
                      .customerName
                      .trim()[0]
                      .toUpperCase()
                  : '?';

          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 3,
                ),

                leading: CircleAvatar(
                  backgroundColor:
                      AppColors.primarySoft,
                  foregroundColor:
                      AppColors.primary,
                  child: Text(firstLetter),
                ),

                title: Text(
                  customer.customerName,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 13,
                  ),
                ),

                subtitle: Text(
                  '${customer.route} · '
                  'Outstanding ${_money(customer.outstanding)}',
                ),

                trailing: customer.status ==
                        'Visited'
                    ? const StatusChip(
                        label: 'Visited',
                        color:
                            AppColors.success,
                      )
                    : OutlinedButton(
                        onPressed: () =>
                            _openFeature(
                          AppFeatures
                              .customers,
                        ),
                        child:
                            const Text(
                          'Visit',
                        ),
                      ),
              ),

              if (index <
                  customers.length - 1)
                const Divider(
                  indent: 66,
                ),
            ],
          );
        },
      ),
    ),
  );
}
  Widget _salesmanProgress() => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          _progressRow('Customers Visited', '8 / 15', .53, AppColors.primary),
          const SizedBox(height: 15),
          _progressRow('Orders Completed', '6 / 12', .50, AppColors.success),
          const SizedBox(height: 15),
          _progressRow(
            'Collection Target',
            '₹12,300 / ₹20,000',
            .615,
            AppColors.purple,
          ),
          const SizedBox(height: 15),
          _progressRow('Delivery Status', '70%', .70, AppColors.warning),
        ],
      ),
    ),
  );
  Widget _bottomNavigation() {
    final admin = user.role == UserRole.admin;

    // ============================================================
    // ADMIN BOTTOM NAVIGATION
    // ============================================================
    if (admin) {
      const items = <(IconData, String)>[
        (Icons.home_outlined, 'Home'),
        (Icons.people_outline_rounded, 'Customers'),
        (Icons.inventory_2_outlined, 'Allocation'),
        (Icons.analytics_outlined, 'Reports'),
        (Icons.more_horiz_rounded, 'More'),
      ];

      return NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) => _navTap(index, true),
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.$1),
                selectedIcon: Icon(item.$1, color: AppColors.primary),
                label: item.$2,
              ),
            )
            .toList(),
      );
    }

    // ============================================================
    // SALESMAN BOTTOM NAVIGATION
    // ONLY SHOW FEATURES THAT THE SALESMAN HAS PERMISSION FOR
    // ============================================================

    final List<(IconData, String, AppFeature?)> items = [
      (Icons.home_outlined, 'Home', null),
    ];

    if (user.can(AppPermission.routesView)) {
      items.add((Icons.route_outlined, 'Route', AppFeatures.routes));
    }

    if (user.can(AppPermission.salesView)) {
      items.add((Icons.receipt_long_outlined, 'Sales', AppFeatures.sales));
    }

    if (user.can(AppPermission.collectionView)) {
      items.add((
        Icons.payments_outlined,
        'Collection',
        AppFeatures.collection,
      ));
    }

    items.add((Icons.more_horiz_rounded, 'More', null));

    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 0) {
          return;
        }

        final item = items[index];

        // MORE
        if (item.$3 == null) {
          _scaffoldKey.currentState?.openDrawer();
          return;
        }

        // Extra safety check before navigation.
        _openFeature(item.$3!);
      },
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.$1),
              selectedIcon: Icon(item.$1, color: AppColors.primary),
              label: item.$2,
            ),
          )
          .toList(),
    );
  }

  void _navTap(int index, bool admin) {
    if (index == 0) return;

    if (!admin) {
      return;
    }

    if (index == 4) {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }

    if (index == 1) {
      _openFeature(AppFeatures.customers);
    }

    if (index == 2) {
      _openFeature(AppFeatures.allocation);
    }

    if (index == 3) {
      _openFeature(AppFeatures.reports);
    }
  }

  Widget _buildDrawer() {
    final admin = user.role == UserRole.admin;
    final visible = AppFeatures.visibleFor(user);
    final operations = visible
        .where(
          (item) =>
              item != AppFeatures.reports &&
              item != AppFeatures.expenses &&
              item != AppFeatures.customerRates,
        )
        .toList();
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primaryDeep,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    child: Text(
                      _initials(user.name),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.role.label,
                    style: const TextStyle(
                      color: Color(0xFFCADBFA),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    admin ? user.branch : user.route ?? '',
                    style: const TextStyle(
                      color: Color(0xFFCADBFA),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _drawerHeading('OPERATIONS'),
                  for (final feature in operations)
                    _drawerTile(
                      feature.icon,
                      feature.title,
                      () => _openFromDrawer(feature),
                      assetPath: feature.assetPath,
                    ),
                  if (admin) ...[
                    _drawerHeading('MANAGEMENT'),
                    _drawerTile(
                      Icons.price_change_outlined,
                      'Customer Rates',
                      () => _openFromDrawer(AppFeatures.customerRates),
                    ),
                    _drawerTile(
                      Icons.badge_outlined,
                      'Salesmen',
                      _openSalesmenFromDrawer,
                      assetPath: 'assets/img/TotalSalesmanAllocation.png',
                    ),
                    _drawerTile(
                      Icons.admin_panel_settings_outlined,
                      'Feature Access',
                      _openSalesmenFromDrawer,
                    ),
                    _drawerHeading('REPORTS'),
                    _drawerTile(
                      Icons.analytics_outlined,
                      'Reports',
                      () => _openFromDrawer(AppFeatures.reports),
                      assetPath: AppFeatures.reports.assetPath,
                    ),
                    _drawerHeading('SYSTEM'),
                    _drawerTile(
                      Icons.account_balance_wallet_outlined,
                      'Expenses',
                      () => _openFromDrawer(AppFeatures.expenses),
                      assetPath: AppFeatures.expenses.assetPath,
                    ),
                    _drawerTile(
                      Icons.settings_outlined,
                      'Settings',
                      () => _openNamedFromDrawer('/settings'),
                    ),
                  ],
                  _drawerTile(
                    Icons.person_outline_rounded,
                    'Profile',
                    () => _openWidgetFromDrawer(const ProfileScreen()),
                  ),
                  _drawerTile(Icons.logout_rounded, 'Logout', _logout),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerHeading(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 13, 18, 5),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
      ),
    ),
  );

  Widget _drawerTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? assetPath,
  }) => ListTile(
    dense: true,
    leading: Container(
      height: 36,
      width: 36,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: assetPath == null
          ? Icon(icon, color: AppColors.primary, size: 20)
          : Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(icon, color: AppColors.primary, size: 20),
            ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: AppColors.textMuted,
    ),
    onTap: onTap,
  );

  Widget _footerBanner() => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: double.infinity,
      height: 110,
      child: Image.asset(
        'assets/img/DashboardFooter.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: AppColors.primarySoft,
          child: Center(
            child: Text(
              'Fresh Milk, Happy Customers!',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _openFromDrawer(AppFeature feature) async {
    _scaffoldKey.currentState?.closeDrawer();
    await Future<void>.delayed(kThemeAnimationDuration);
    if (mounted) _openFeature(feature);
  }

  Future<void> _openNamedFromDrawer(String route) async {
    _scaffoldKey.currentState?.closeDrawer();
    await Future<void>.delayed(kThemeAnimationDuration);
    if (mounted) Navigator.pushNamed(context, route);
  }

  Future<void> _openWidgetFromDrawer(Widget screen) async {
    _scaffoldKey.currentState?.closeDrawer();
    await Future<void>.delayed(kThemeAnimationDuration);
    if (mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }
  }

  Future<void> _openSalesmenFromDrawer() async {
    _scaffoldKey.currentState?.closeDrawer();
    await Future<void>.delayed(kThemeAnimationDuration);
    if (mounted) _openSalesmen();
  }

  void _openSalesmen() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SalesmanManagementScreen()),
  );

  void _openFeature(AppFeature feature) {
    AppNavigation.openWidget<void>(
      context,
      feature,
      (_) => _screenFor(feature),
    );
  }

  Widget _screenFor(AppFeature feature) {
    if (feature == AppFeatures.customers) {
      return const CustomersScreen();
    }

    if (feature == AppFeatures.customerRates) {
      return const CustomerRatesScreen();
    }

    if (feature == AppFeatures.products) {
      return const ProductsScreen();
    }

    // ============================================================
    // SUPPLIERS
    // ============================================================
    if (feature == AppFeatures.suppliers) {
      return const SupplierScreen();
    }

    if (feature == AppFeatures.allocation) {
      return const AllocationScreen();
    }

    if (feature == AppFeatures.sales) {
      return const SalesScreen();
    }

    if (feature == AppFeatures.returns) {
      return const ReturnSettlementScreen();
    }

    if (feature == AppFeatures.collection) {
      return const CollectionScreen();
    }

    if (feature == AppFeatures.routes) {
      return const RoutesScreen();
    }

    if (feature == AppFeatures.purchase) {
      return const PurchaseScreen();
    }

    if (feature == AppFeatures.reports) {
      return const ReportsScreen();
    }

    if (feature == AppFeatures.payments) {
      return const PaymentsScreen();
    }

    if (feature == AppFeatures.ledger) {
      return const LedgerScreen();
    }

    if (feature == AppFeatures.expenses) {
      return const ExpensesScreen();
    }

    return const DashboardScreen();
  }

  Future<void> _logout() async {
    _scaffoldKey.currentState?.closeDrawer();
    await Future<void>.delayed(kThemeAnimationDuration);
    if (!mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will return to the sign-in screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    UiSession.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  String _initials(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join();
}
class _DashboardData {
  const _DashboardData({
    this.todaySalesAmount = 0,
    this.todaySalesQuantity = 0,
    this.todayBills = 0,
    this.todayCollectionAmount = 0,
    this.collectionReceipts = 0,
    this.pendingCollection = 0,
    this.pendingAccounts = 0,
    this.todayAllocations = 0,
    this.todayAllocatedQuantity = 0,
    this.todayReturnQuantity = 0,
    this.pendingDeliveryQuantity = 0,
    this.salesProgress = 0,
    this.collectionProgress = 0,
    this.returnProgress = 0,
    this.todayCustomers = const [],
  });

  final double
      todaySalesAmount;

  final double
      todaySalesQuantity;

  final int
      todayBills;

  final double
      todayCollectionAmount;

  final int
      collectionReceipts;

  final double
      pendingCollection;

  final int
      pendingAccounts;

  final int
      todayAllocations;

  final double
      todayAllocatedQuantity;

  final double
      todayReturnQuantity;

  final double
      pendingDeliveryQuantity;

  final double
      salesProgress;

  final double
      collectionProgress;

  final double
      returnProgress;
      final List<_DashboardCustomer>
    todayCustomers;


  factory _DashboardData.fromJson(
    Map<String, dynamic> json,
  ) {
    double number(
      String key,
    ) {
      return double.tryParse(
            json[key]
                    ?.toString() ??
                '0',
          ) ??
          0;
    }

    int integer(
      String key,
    ) {
      return int.tryParse(
            json[key]
                    ?.toString() ??
                '0',
          ) ??
          0;
    }
    final todayCustomers =
    (json['todayCustomers']
                as List? ??
            const [])
        .whereType<Map>()
        .map(
          (item) =>
              _DashboardCustomer
                  .fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList(
          growable: false,
        );

    return _DashboardData(
      todaySalesAmount:
          number(
        'todaySalesAmount',
      ),

      todaySalesQuantity:
          number(
        'todaySalesQuantity',
      ),

      todayBills:
          integer(
        'todayBills',
      ),

      todayCollectionAmount:
          number(
        'todayCollectionAmount',
      ),

      collectionReceipts:
          integer(
        'collectionReceipts',
      ),

      pendingCollection:
          number(
        'pendingCollection',
      ),

      pendingAccounts:
          integer(
        'pendingAccounts',
      ),

      todayAllocations:
          integer(
        'todayAllocations',
      ),

      todayAllocatedQuantity:
          number(
        'todayAllocatedQuantity',
      ),

      todayReturnQuantity:
          number(
        'todayReturnQuantity',
      ),

      pendingDeliveryQuantity:
          number(
        'pendingDeliveryQuantity',
      ),

      salesProgress:
          number(
        'salesProgress',
      ),

      collectionProgress:
          number(
        'collectionProgress',
      ),

      returnProgress:
          number(
        'returnProgress',
      ),
      todayCustomers:
    todayCustomers,
    );
  }
}
class _DashboardCustomer {
  const _DashboardCustomer({
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.route,
    required this.outstanding,
    required this.todaySale,
    required this.todayCollection,
    required this.status,
  });

  final String customerId;
  final String customerName;
  final String mobile;
  final String route;

  final double outstanding;
  final double todaySale;
  final double todayCollection;

  final String status;

  factory _DashboardCustomer.fromJson(
    Map<String, dynamic> json,
  ) {
    double number(String key) {
      return double.tryParse(
            json[key]?.toString() ?? '0',
          ) ??
          0;
    }

    return _DashboardCustomer(
      customerId:
          json['customerId']?.toString() ?? '',

      customerName:
          json['customerName']?.toString() ?? '',

      mobile:
          json['mobile']?.toString() ?? '',

      route:
          json['route']?.toString() ?? '',

      outstanding:
          number('outstanding'),

      todaySale:
          number('todaySale'),

      todayCollection:
          number('todayCollection'),

      status:
          json['status']?.toString() ?? 'Pending',
    );
  }
}