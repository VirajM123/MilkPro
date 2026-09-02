import 'package:flutter/foundation.dart';

import '../models/access_models.dart';

/// Temporary, isolated UI-only store. Replace this class with an API-backed
/// repository when the authentication backend is introduced.
class SalesmanUiStore extends ChangeNotifier {
  SalesmanUiStore._();

  static final SalesmanUiStore instance = SalesmanUiStore._();

  final List<SalesmanProfile> _salesmen = <SalesmanProfile>[
    const SalesmanProfile(
      id: 'SM001',
      name: 'Rahul Patil',
      mobile: '9876543210',
      route: 'Pune West',
      isActive: true,
      permissions: {
        AppPermission.productsView,
        AppPermission.customersView,
        AppPermission.salesView,
        AppPermission.salesCreate,
        AppPermission.collectionView,
        AppPermission.collectionCreate,
        AppPermission.routesView,
        AppPermission.allocationView,
        AppPermission.returnsManage,
      },
    ),
    const SalesmanProfile(
      id: 'SM002',
      name: 'Omkar Jadhav',
      mobile: '9822012345',
      route: 'Kothrud',
      isActive: true,
      permissions: {
        AppPermission.productsView,
        AppPermission.customersView,
        AppPermission.salesView,
        AppPermission.salesCreate,
        AppPermission.collectionView,
        AppPermission.collectionCreate,
        AppPermission.routesView,
      },
    ),
    const SalesmanProfile(
      id: 'SM003',
      name: 'Sagar More',
      mobile: '9765432108',
      route: 'Warje',
      isActive: false,
      permissions: {AppPermission.customersView, AppPermission.routesView},
    ),
  ];

  List<SalesmanProfile> get salesmen => List.unmodifiable(_salesmen);

  SalesmanProfile byId(String id) =>
      _salesmen.firstWhere((item) => item.id == id);

  void updatePermissions(String id, Set<AppPermission> permissions) {
    final index = _salesmen.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _salesmen[index] = _salesmen[index].copyWith(
      permissions: Set<AppPermission>.unmodifiable(permissions),
    );
    notifyListeners();
  }

  void setActive(String id, bool active) {
    final index = _salesmen.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _salesmen[index] = _salesmen[index].copyWith(isActive: active);
    notifyListeners();
  }

  void updateProfile(
    String id, {
    required String name,
    required String mobile,
    required String route,
  }) {
    final index = _salesmen.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _salesmen[index] = _salesmen[index].copyWith(
      name: name,
      mobile: mobile,
      route: route,
    );
    notifyListeners();
  }
}
