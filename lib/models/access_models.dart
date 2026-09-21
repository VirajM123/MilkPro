enum UserRole {
  admin,
  salesman,
}

extension UserRoleLabel on UserRole {
  String get label =>
      this == UserRole.admin
          ? 'Administrator'
          : 'Salesman';
}

// ============================================================
// SALESMAN ROUTE
//
// One salesman can now have multiple routes.
//
// IMPORTANT:
// Customer / Route Master logic is unchanged.
// One route still belongs to one salesman.
// ============================================================

class SalesmanRoute {
  const SalesmanRoute({
    required this.routeId,
    required this.routeName,
  });

  final String routeId;
  final String routeName;

  factory SalesmanRoute.fromMap(
    Map<String, dynamic> data,
  ) {
    return SalesmanRoute(
      routeId:
          data['routeId']
              ?.toString()
              .trim() ??
          '',
      routeName:
          (data['routeName'] ??
                  data['name'] ??
                  '')
              .toString()
              .trim(),
    );
  }

  bool get isValid =>
      routeId.isNotEmpty ||
      routeName.isNotEmpty;
}

enum AppPermission {
  productsView,
  customersView,
  customersCreate,
  customersEdit,
  customerRatesManage,
  allocationView,
  salesView,
  salesCreate,
  returnsManage,
  collectionView,
  collectionCreate,
  routesView,
  purchaseView,
  paymentsView,
  ledgerView,
  reportsView,
  expensesView,
  suppliersView,
}

// ============================================================
// APP USER
// ============================================================

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.branch,
    this.mobile = '',
    this.salesmanId,

    // ----------------------------------------------------------
    // LEGACY SINGLE ROUTE
    //
    // Do not remove yet.
    // Existing screens may still use currentUser.route.
    // ----------------------------------------------------------
    this.route,

    // ----------------------------------------------------------
    // NEW MULTI-ROUTE FIELD
    // ----------------------------------------------------------
    this.routes =
        const <SalesmanRoute>[],

    this.permissions =
        const <AppPermission>{},
  });

  final String id;
  final String name;
  final UserRole role;
  final String branch;
  final String mobile;

  final String? salesmanId;

  // ==========================================================
  // LEGACY
  // ==========================================================

  final String? route;

  // ==========================================================
  // NEW
  // ==========================================================

  final List<SalesmanRoute> routes;

  final Set<AppPermission> permissions;

  // ==========================================================
  // ROUTE HELPERS
  // ==========================================================

  int get routeCount =>
      routes.isNotEmpty
          ? routes.length
          : route != null &&
                  route!.trim().isNotEmpty
              ? 1
              : 0;

  bool get hasRoutes =>
      routeCount > 0;

  bool get hasMultipleRoutes =>
      routeCount > 1;

  List<String> get routeNames {
    if (routes.isNotEmpty) {
      return routes
          .map(
            (item) =>
                item.routeName.trim(),
          )
          .where(
            (name) =>
                name.isNotEmpty,
          )
          .toList(
            growable: false,
          );
    }

    final oldRoute =
        route?.trim() ?? '';

    if (oldRoute.isEmpty) {
      return const <String>[];
    }

    return <String>[
      oldRoute,
    ];
  }

  String get routeDisplay {
    final names =
        routeNames;

    if (names.isEmpty) {
      return '';
    }

    return names.join(', ');
  }

  String? get primaryRouteName {
    if (routes.isNotEmpty) {
      final value =
          routes.first.routeName
              .trim();

      return value.isEmpty
          ? null
          : value;
    }

    final oldRoute =
        route?.trim() ?? '';

    return oldRoute.isEmpty
        ? null
        : oldRoute;
  }

  String? get primaryRouteId {
    if (routes.isEmpty) {
      return null;
    }

    final value =
        routes.first.routeId
            .trim();

    return value.isEmpty
        ? null
        : value;
  }

  bool isAssignedToRoute(
    String value,
  ) {
    final target =
        value.trim().toLowerCase();

    if (target.isEmpty) {
      return false;
    }

    if (routes.isNotEmpty) {
      return routes.any(
        (item) =>
            item.routeId
                    .trim()
                    .toLowerCase() ==
                target ||
            item.routeName
                    .trim()
                    .toLowerCase() ==
                target,
      );
    }

    return (route ?? '')
            .trim()
            .toLowerCase() ==
        target;
  }

  bool can(
    AppPermission permission,
  ) =>
      role == UserRole.admin ||
      permissions.contains(
        permission,
      );
}

// ============================================================
// SALESMAN PROFILE
// ============================================================

class SalesmanProfile {
  const SalesmanProfile({
    required this.id,
    required this.name,
    required this.mobile,

    // Legacy primary route
    required this.route,

    // New full route list
    this.routes =
        const <SalesmanRoute>[],

    required this.isActive,
    required this.permissions,
  });

  final String id;
  final String name;
  final String mobile;

  // ==========================================================
  // LEGACY
  // ==========================================================

  final String route;

  // ==========================================================
  // NEW
  // ==========================================================

  final List<SalesmanRoute> routes;

  final bool isActive;

  final Set<AppPermission>
      permissions;

  // ==========================================================
  // ROUTE HELPERS
  // ==========================================================

  int get routeCount =>
      routes.isNotEmpty
          ? routes.length
          : route.trim().isNotEmpty
              ? 1
              : 0;

  List<String> get routeNames {
    if (routes.isNotEmpty) {
      return routes
          .map(
            (item) =>
                item.routeName.trim(),
          )
          .where(
            (name) =>
                name.isNotEmpty,
          )
          .toList(
            growable: false,
          );
    }

    if (route.trim().isEmpty) {
      return const <String>[];
    }

    return <String>[
      route.trim(),
    ];
  }

  String get routeDisplay {
    final names =
        routeNames;

    return names.isEmpty
        ? ''
        : names.join(', ');
  }

  SalesmanProfile copyWith({
    String? name,
    String? mobile,
    String? route,
    List<SalesmanRoute>? routes,
    bool? isActive,
    Set<AppPermission>?
        permissions,
  }) {
    return SalesmanProfile(
      id: id,

      name:
          name ?? this.name,

      mobile:
          mobile ?? this.mobile,

      route:
          route ?? this.route,

      routes:
          routes ?? this.routes,

      isActive:
          isActive ??
          this.isActive,

      permissions:
          permissions ??
          this.permissions,
    );
  }

  AppUser toUser() {
    final effectiveRoutes =
        routes;

    final effectivePrimaryRoute =
        effectiveRoutes.isNotEmpty
            ? effectiveRoutes
                .first
                .routeName
            : route;

    return AppUser(
      id: id,

      name: name,

      role:
          UserRole.salesman,

      branch:
          'Main Distribution Centre',

      mobile:
          mobile,

      salesmanId:
          id,

      // Legacy compatibility
      route:
          effectivePrimaryRoute,

      // New multi-route support
      routes:
          List<SalesmanRoute>.unmodifiable(
        effectiveRoutes,
      ),

      permissions:
          Set<AppPermission>.unmodifiable(
        permissions,
      ),
    );
  }
}

// ============================================================
// PERMISSION MODELS
// ============================================================

class PermissionGroup {
  const PermissionGroup(
    this.title,
    this.items,
  );

  final String title;
  final List<PermissionOption>
      items;
}

class PermissionOption {
  const PermissionOption(
    this.permission,
    this.label,
  );

  final AppPermission permission;
  final String label;
}

// ============================================================
// PERMISSION GROUPS
// ============================================================

const permissionGroups =
    <PermissionGroup>[
  PermissionGroup(
    'Products',
    [
      PermissionOption(
        AppPermission.productsView,
        'View products',
      ),
    ],
  ),

  PermissionGroup(
    'Suppliers',
    [
      PermissionOption(
        AppPermission.suppliersView,
        'View suppliers',
      ),
    ],
  ),

  PermissionGroup(
    'Customers',
    [
      PermissionOption(
        AppPermission.customersView,
        'View customers',
      ),
      PermissionOption(
        AppPermission.customersCreate,
        'Add customer',
      ),
      PermissionOption(
        AppPermission.customersEdit,
        'Edit customer',
      ),
      PermissionOption(
        AppPermission.customerRatesManage,
        'Customer rates',
      ),
    ],
  ),

  PermissionGroup(
    'Sales',
    [
      PermissionOption(
        AppPermission.salesView,
        'View sales',
      ),
      PermissionOption(
        AppPermission.salesCreate,
        'Create sale',
      ),
    ],
  ),

  PermissionGroup(
    'Collection',
    [
      PermissionOption(
        AppPermission.collectionView,
        'View collection',
      ),
      PermissionOption(
        AppPermission.collectionCreate,
        'Record collection',
      ),
    ],
  ),

  PermissionGroup(
    'Allocation',
    [
      PermissionOption(
        AppPermission.allocationView,
        'View allocation',
      ),
    ],
  ),

  PermissionGroup(
    'Returns',
    [
      PermissionOption(
        AppPermission.returnsManage,
        'Return settlement',
      ),
    ],
  ),

  PermissionGroup(
    'Routes',
    [
      PermissionOption(
        AppPermission.routesView,
        'View routes',
      ),
    ],
  ),

  PermissionGroup(
    'Purchase',
    [
      PermissionOption(
        AppPermission.purchaseView,
        'Purchase',
      ),
    ],
  ),

  PermissionGroup(
    'Payments',
    [
      PermissionOption(
        AppPermission.paymentsView,
        'Payments',
      ),
    ],
  ),

  PermissionGroup(
    'Ledger',
    [
      PermissionOption(
        AppPermission.ledgerView,
        'Customer ledger',
      ),
    ],
  ),

  PermissionGroup(
    'Reports',
    [
      PermissionOption(
        AppPermission.reportsView,
        'Reports',
      ),
    ],
  ),

  PermissionGroup(
    'Expenses',
    [
      PermissionOption(
        AppPermission.expensesView,
        'Expenses',
      ),
    ],
  ),
];