import 'package:flutter/foundation.dart';

import '../models/access_models.dart';
import 'salesman_ui_store.dart';

/// Temporary UI session for role and permission previews.
/// It deliberately contains no token, API, or persistence behavior.
class UiSession extends ChangeNotifier {
  UiSession._();

  static final UiSession instance = UiSession._();

  static const AppUser _admin = AppUser(
    id: 'ADMIN',
    name: 'Admin',
    role: UserRole.admin,
    branch: 'Main Distribution Centre',
    mobile: '9876543210',
  );

  AppUser? _currentUser;

  AppUser get currentUser => _currentUser ?? _admin;
  bool get isAuthenticated => _currentUser != null;
  UserRole get role => currentUser.role;

  bool can(AppPermission permission) => currentUser.can(permission);

  /// UI-only role-aware sign in. This keeps the selected login type explicit
  /// without implying that a backend has authenticated either role.
  void signInForRole(UserRole role, String identifier) {
    if (role == UserRole.salesman) {
      final normalized = identifier.trim().toLowerCase();
      final salesmen = SalesmanUiStore.instance.salesmen;
      final match = salesmen.where((item) {
        return item.id.toLowerCase() == normalized ||
            item.mobile == identifier.trim() ||
            item.name.toLowerCase() == normalized;
      });
      _currentUser = (match.isEmpty ? salesmen.first : match.first).toUser();
    } else {
      _currentUser = _admin;
    }
    notifyListeners();
  }

  void signInForUi(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    final salesmanLogin =
        normalized == 'salesman' || normalized.startsWith('sm');
    signInForRole(
      salesmanLogin ? UserRole.salesman : UserRole.admin,
      identifier,
    );
  }

  void previewSalesman(String salesmanId) {
    _currentUser = SalesmanUiStore.instance.byId(salesmanId).toUser();
    notifyListeners();
  }

  void refreshSalesmanPermissions(String salesmanId) {
    if (_currentUser?.salesmanId != salesmanId) return;
    _currentUser = SalesmanUiStore.instance.byId(salesmanId).toUser();
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }
}
