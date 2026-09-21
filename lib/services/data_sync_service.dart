import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/access_models.dart';
import '../providers/auth_provider.dart';

enum SyncEventType {
  none,

  allocation,
  sale,
  returnSettlement,

  customers,
  products,
  customerRates,
  collections,
  routes,

  profile,

  all,
}

class DataSyncService extends ChangeNotifier {
  DataSyncService._();

  static final DataSyncService instance =
      DataSyncService._();

  SyncEventType _lastEventType =
      SyncEventType.none;

  SyncEventType get lastEventType =>
      _lastEventType;

  DateTime? _lastSyncTime;

  DateTime? get lastSyncTime =>
      _lastSyncTime;

  int _allocationVersion = 0;
  int _saleVersion = 0;
  int _returnVersion = 0;
  int _customerVersion = 0;
  int _productVersion = 0;
  int _customerRateVersion = 0;
  int _collectionVersion = 0;
  int _routeVersion = 0;
  int _profileVersion = 0;
  int _allVersion = 0;

  int get allocationVersion =>
      _allocationVersion;

  int get saleVersion =>
      _saleVersion;

  int get returnVersion =>
      _returnVersion;

  int get customerVersion =>
      _customerVersion;

  int get productVersion =>
      _productVersion;

  int get customerRateVersion =>
      _customerRateVersion;

  int get collectionVersion =>
      _collectionVersion;

  int get routeVersion =>
      _routeVersion;

  int get profileVersion =>
      _profileVersion;

  int get allVersion =>
      _allVersion;

  bool _syncInProgress = false;

  bool get syncInProgress =>
      _syncInProgress;

  Timer? _sessionRefreshTimer;

  // ============================================================
  // NORMAL EVENT NOTIFICATIONS
  // ============================================================

  void notifyAllocationChanged() {
    _allocationVersion++;

    _emit(
      SyncEventType.allocation,
    );
  }

  void notifySaleChanged() {
    _saleVersion++;

    _emit(
      SyncEventType.sale,
    );
  }

  void notifyReturnChanged() {
    _returnVersion++;

    _emit(
      SyncEventType.returnSettlement,
    );
  }

  void notifyCustomerChanged() {
    _customerVersion++;

    _emit(
      SyncEventType.customers,
    );
  }

  void notifyProductChanged() {
    _productVersion++;

    _emit(
      SyncEventType.products,
    );
  }

  void notifyCustomerRateChanged() {
    _customerRateVersion++;

    _emit(
      SyncEventType.customerRates,
    );
  }

  void notifyCollectionChanged() {
    _collectionVersion++;

    _emit(
      SyncEventType.collections,
    );
  }

  void notifyRouteChanged() {
    _routeVersion++;

    _emit(
      SyncEventType.routes,
    );
  }

  void notifyProfileChanged() {
    _profileVersion++;

    _emit(
      SyncEventType.profile,
    );
  }

  void notifyAllChanged() {
    _allVersion++;

    _allocationVersion++;
    _saleVersion++;
    _returnVersion++;
    _customerVersion++;
    _productVersion++;
    _customerRateVersion++;
    _collectionVersion++;
    _routeVersion++;

    _emit(
      SyncEventType.all,
    );
  }

  void _emit(
    SyncEventType type,
  ) {
    _lastEventType =
        type;

    _lastSyncTime =
        DateTime.now();

    notifyListeners();
  }

  // ============================================================
  // UNIVERSAL SYNC
  //
  // 1. Refresh logged-in profile
  // 2. Refresh permissions/routes
  // 3. Broadcast ALL event
  //
  // Every mounted screen then reloads its own authoritative API.
  // ============================================================

  Future<void> syncEverything() async {
    if (_syncInProgress) {
      return;
    }

    _syncInProgress = true;

    try {
      await refreshCurrentSession(
        notifyDataScreens: false,
      );

      notifyAllChanged();
    } finally {
      _syncInProgress = false;
    }
  }

  // ============================================================
  // SESSION / PERMISSION REFRESH
  // ============================================================

  Future<bool> refreshCurrentSession({
    bool notifyDataScreens = true,
  }) async {
    if (!UiSession.instance.isAuthenticated) {
      return false;
    }

    final String token =
        ApiConfig.token?.toString() ?? '';

    if (token.trim().isEmpty) {
      return false;
    }

    final response =
        await http
            .get(
              Uri.parse(
                '${ApiConfig.baseUrl}/api/profile',
              ),
              headers: {
                'Content-Type':
                    'application/json',

                'Authorization':
                    'Bearer $token',
              },
            )
            .timeout(
              const Duration(
                seconds: 20,
              ),
            );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(
        response.body,
      );
    } catch (_) {
      decoded =
          null;
    }

    if (response.statusCode != 200 ||
        decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map) {
      throw Exception(
        decoded is Map
            ? (decoded['message'] ??
                    'Unable to refresh session.')
                .toString()
            : 'Unable to refresh session.',
      );
    }

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      decoded['data'] as Map,
    );

    final AppUser oldUser =
        UiSession.instance.currentUser;

    // ========================================================
    // PERMISSIONS
    // ========================================================

    final Set<AppPermission>
        permissions =
        <AppPermission>{};

    final dynamic rawPermissions =
        data['permissions'];

    if (rawPermissions is List) {
      final Set<String> apiValues =
          rawPermissions
              .map(
                (item) =>
                    item
                        .toString()
                        .trim(),
              )
              .where(
                (item) =>
                    item.isNotEmpty,
              )
              .toSet();

      for (final permission
          in AppPermission.values) {
        if (apiValues.contains(
          permission.name,
        )) {
          permissions.add(
            permission,
          );
        }
      }
    }

    // ========================================================
    // ROUTES
    // ========================================================

    final List<SalesmanRoute>
        routes =
        <SalesmanRoute>[];

    final dynamic rawRoutes =
        data['routes'];

    if (rawRoutes is List) {
      for (final rawRoute
          in rawRoutes) {
        if (rawRoute is! Map) {
          continue;
        }

        final SalesmanRoute route =
            SalesmanRoute.fromMap(
          Map<String, dynamic>.from(
            rawRoute,
          ),
        );

        if (route.isValid) {
          routes.add(route);
        }
      }
    }

    // Backward compatibility
    if (routes.isEmpty) {
      final String routeId =
          (data['routeId'] ?? '')
              .toString()
              .trim();

      final String routeName =
          (data['routeName'] ?? '')
              .toString()
              .trim();

      if (routeId.isNotEmpty ||
          routeName.isNotEmpty) {
        routes.add(
          SalesmanRoute(
            routeId:
                routeId,

            routeName:
                routeName,
          ),
        );
      }
    }

    final String? primaryRoute =
        routes.isEmpty
            ? oldUser.route
            : routes.first.routeName;

    final AppUser updatedUser =
        AppUser(
      id:
          (data['_id'] ??
                  data['id'] ??
                  oldUser.id)
              .toString(),

      name:
          (data['name'] ??
                  oldUser.name)
              .toString(),

      role:
          oldUser.role,

      branch:
          (data['businessName'] ??
                  oldUser.branch)
              .toString(),

      mobile:
          (data['mobile'] ??
                  oldUser.mobile)
              .toString(),

      salesmanId:
          oldUser.role ==
                  UserRole.salesman
              ? (data['salesmanId'] ??
                      oldUser.salesmanId)
                  ?.toString()
              : null,

      route:
          primaryRoute,

      routes:
          routes.isEmpty
              ? oldUser.routes
              : List<
                  SalesmanRoute>.unmodifiable(
                  routes,
                ),

      // Never wipe existing permissions if an old
      // server response does not include permissions.
      permissions:
          oldUser.role ==
                  UserRole.admin
              ? oldUser.permissions
              : permissions.isNotEmpty ||
                      rawPermissions is List
                  ? Set<
                      AppPermission>.unmodifiable(
                      permissions,
                    )
                  : oldUser.permissions,
    );

    final bool changed =
        !_sameUser(
      oldUser,
      updatedUser,
    );

    if (changed) {
      UiSession.instance
          .signInFromBackend(
        updatedUser,
      );

      _profileVersion++;

      _lastEventType =
          SyncEventType.profile;

      _lastSyncTime =
          DateTime.now();

      if (notifyDataScreens) {
        notifyAllChanged();
      }
    }

    return changed;
  }

  // ============================================================
  // AUTO PERMISSION / PROFILE REFRESH
  //
  // Cheap profile-only check.
  // It does NOT reload every business screen every 30 seconds.
  //
  // Only if permissions/profile/routes changed will ALL screens
  // be notified.
  // ============================================================

  void startAutoSessionRefresh() {
    _sessionRefreshTimer?.cancel();

    _sessionRefreshTimer =
        Timer.periodic(
      const Duration(
        seconds: 30,
      ),
      (_) async {
        if (!UiSession
            .instance
            .isAuthenticated) {
          return;
        }

        try {
          await refreshCurrentSession();
        } catch (_) {
          // Silent background refresh.
          // Normal API calls will still enforce
          // backend permissions.
        }
      },
    );
  }

  void stopAutoSessionRefresh() {
    _sessionRefreshTimer
        ?.cancel();

    _sessionRefreshTimer =
        null;
  }

  bool _sameUser(
    AppUser a,
    AppUser b,
  ) {
    if (a.id != b.id ||
        a.name != b.name ||
        a.branch != b.branch ||
        a.mobile != b.mobile ||
        a.salesmanId != b.salesmanId ||
        a.route != b.route) {
      return false;
    }

    if (!setEquals(
      a.permissions,
      b.permissions,
    )) {
      return false;
    }

    if (a.routes.length !=
        b.routes.length) {
      return false;
    }

    final List<String> aRoutes =
        a.routes
            .map(
              (route) =>
                  '${route.routeId}|${route.routeName}',
            )
            .toList()
          ..sort();

    final List<String> bRoutes =
        b.routes
            .map(
              (route) =>
                  '${route.routeId}|${route.routeName}',
            )
            .toList()
          ..sort();

    return listEquals(
      aRoutes,
      bRoutes,
    );
  }
}