enum UserRole { admin, salesman }

extension UserRoleLabel on UserRole {
  String get label => this == UserRole.admin ? 'Administrator' : 'Salesman';
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
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.branch,
    this.mobile = '',
    this.salesmanId,
    this.route,
    this.permissions = const <AppPermission>{},
  });

  final String id;
  final String name;
  final UserRole role;
  final String branch;
  final String mobile;
  final String? salesmanId;
  final String? route;
  final Set<AppPermission> permissions;

  bool can(AppPermission permission) =>
      role == UserRole.admin || permissions.contains(permission);
}

class SalesmanProfile {
  const SalesmanProfile({
    required this.id,
    required this.name,
    required this.mobile,
    required this.route,
    required this.isActive,
    required this.permissions,
  });

  final String id;
  final String name;
  final String mobile;
  final String route;
  final bool isActive;
  final Set<AppPermission> permissions;

  SalesmanProfile copyWith({
    String? name,
    String? mobile,
    String? route,
    bool? isActive,
    Set<AppPermission>? permissions,
  }) {
    return SalesmanProfile(
      id: id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      route: route ?? this.route,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }

  AppUser toUser() => AppUser(
    id: id,
    name: name,
    role: UserRole.salesman,
    branch: 'Main Distribution Centre',
    mobile: mobile,
    salesmanId: id,
    route: route,
    permissions: Set<AppPermission>.unmodifiable(permissions),
  );
}

class PermissionGroup {
  const PermissionGroup(this.title, this.items);

  final String title;
  final List<PermissionOption> items;
}

class PermissionOption {
  const PermissionOption(this.permission, this.label);

  final AppPermission permission;
  final String label;
}

const permissionGroups = <PermissionGroup>[
  PermissionGroup('Products', [
    PermissionOption(AppPermission.productsView, 'View products'),
  ]),
  PermissionGroup('Customers', [
    PermissionOption(AppPermission.customersView, 'View customers'),
    PermissionOption(AppPermission.customersCreate, 'Add customer'),
    PermissionOption(AppPermission.customersEdit, 'Edit customer'),
  ]),
  PermissionGroup('Sales', [
    PermissionOption(AppPermission.salesView, 'View sales'),
    PermissionOption(AppPermission.salesCreate, 'Create sale'),
  ]),
  PermissionGroup('Collection', [
    PermissionOption(AppPermission.collectionView, 'View collection'),
    PermissionOption(AppPermission.collectionCreate, 'Record collection'),
  ]),
  PermissionGroup('Allocation', [
    PermissionOption(AppPermission.allocationView, 'View allocation'),
  ]),
  PermissionGroup('Returns', [
    PermissionOption(AppPermission.returnsManage, 'Return settlement'),
  ]),
  PermissionGroup('Routes', [
    PermissionOption(AppPermission.routesView, 'View routes'),
  ]),
  PermissionGroup('Purchase', [
    PermissionOption(AppPermission.purchaseView, 'Purchase'),
  ]),
  PermissionGroup('Payments', [
    PermissionOption(AppPermission.paymentsView, 'Payments'),
  ]),
  PermissionGroup('Ledger', [
    PermissionOption(AppPermission.ledgerView, 'Customer ledger'),
  ]),
  PermissionGroup('Reports', [
    PermissionOption(AppPermission.reportsView, 'Reports'),
  ]),
  PermissionGroup('Expenses', [
    PermissionOption(AppPermission.expensesView, 'Expenses'),
  ]),
];
