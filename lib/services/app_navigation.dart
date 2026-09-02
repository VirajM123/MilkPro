import 'package:flutter/material.dart';

import '../config/app_features.dart';
import '../models/access_models.dart';
import '../providers/auth_provider.dart';
import '../screens/common/access_denied_screen.dart';

abstract final class AppNavigation {
  static bool _canOpen(AppFeature feature) {
    final user = UiSession.instance.currentUser;
    if (feature.adminOnly && user.role != UserRole.admin) return false;
    return UiSession.instance.can(feature.permission);
  }

  static Future<T?> open<T>(BuildContext context, AppFeature feature) {
    if (!_canOpen(feature)) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute<T>(builder: (_) => const AccessDeniedScreen()),
      );
    }
    return Navigator.of(context).pushNamed<T>(feature.route);
  }

  static Future<T?> openWidget<T>(
    BuildContext context,
    AppFeature feature,
    WidgetBuilder builder,
  ) {
    if (!_canOpen(feature)) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute<T>(builder: (_) => const AccessDeniedScreen()),
      );
    }
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute<T>(builder: builder));
  }
}
