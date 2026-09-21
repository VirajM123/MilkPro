import 'dart:convert';
import '../../services/data_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.admin;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _loading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

Future<void> _login() async {
  FocusScope.of(context).unfocus();

  if (!(_formKey.currentState?.validate() ?? false)) {
    return;
  }

  setState(() => _loading = true);

  try {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'role': _role == UserRole.admin
            ? 'admin'
            : 'salesman',

        'identifier':
            _identifierController.text.trim(),

        'password':
            _passwordController.text,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (!mounted) return;

    if (response.statusCode == 200 &&
        data['success'] == true) {

      final user =
          data['user'] as Map<String, dynamic>?;


      if (user == null) {
        _message('Invalid response from server.');
        return;
      }
      ApiConfig.token =
    data['token']?.toString() ?? '';

ApiConfig.farmId =
    user['farmId']?.toString() ?? '';

      final serverRole =
          user['role']?.toString() ?? '';

      if (_role == UserRole.admin &&
          serverRole != 'admin') {
        _message(
          'This account is not an Admin account.',
        );
        return;
      }

      if (_role == UserRole.salesman &&
          serverRole != 'salesman') {
        _message(
          'This account is not a Salesman account.',
        );
        return;
      }
      // ============================================================
// LOAD FULL CURRENT USER PROFILE
//
// Login response is intentionally kept lightweight.
// /api/profile contains the complete salesman information,
// including the new multi-route routes[] array.
// ============================================================

Map<String, dynamic> sessionUser =
    Map<String, dynamic>.from(
  user,
);

if (
    serverRole == 'salesman' &&
    ApiConfig.token.isNotEmpty
) {
  try {
    final profileResponse =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/profile',
      ),
      headers: {
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer ${ApiConfig.token}',
      },
    );

    if (
        profileResponse.statusCode ==
            200
    ) {
      final profileBody =
          jsonDecode(
        profileResponse.body,
      );

      if (
          profileBody is Map &&
          profileBody['success'] ==
              true &&
          profileBody['data']
              is Map
      ) {
        sessionUser =
            Map<String, dynamic>.from(
          profileBody['data']
              as Map,
        );
      }
    }
  } catch (_) {
    // --------------------------------------------------------
    // Do not block login if profile refresh temporarily fails.
    // Existing login information remains available.
    // --------------------------------------------------------
  }
}
// ============================================================
// CONVERT BACKEND PERMISSIONS TO AppPermission
// ============================================================

final Set<AppPermission> permissions =
    <AppPermission>{};

final rawPermissions =
sessionUser['permissions'];

if (rawPermissions is List) {
  for (final permission in rawPermissions) {
    final permissionName =
        permission.toString().trim();

    for (final appPermission
        in AppPermission.values) {
      if (appPermission.name ==
          permissionName) {
        permissions.add(appPermission);
        break;
      }
    }
  }
}


// ============================================================
// PARSE SALESMAN ASSIGNED ROUTES
// ============================================================

final List<SalesmanRoute>
    assignedRoutes =
    <SalesmanRoute>[];

final rawRoutes =
    sessionUser['routes'];

if (rawRoutes is List) {
  for (
    final rawRoute
    in rawRoutes
  ) {
    if (rawRoute is! Map) {
      continue;
    }

    final route =
        SalesmanRoute.fromMap(
      Map<String, dynamic>.from(
        rawRoute,
      ),
    );

    if (route.isValid) {
      assignedRoutes.add(
        route,
      );
    }
  }
}

// ============================================================
// LEGACY FALLBACK
//
// Supports old server response containing only
// routeId + routeName.
// ============================================================

if (assignedRoutes.isEmpty) {
  final legacyRouteId =
      (sessionUser['routeId'] ??
              '')
          .toString()
          .trim();

  final legacyRouteName =
      (sessionUser['routeName'] ??
              '')
          .toString()
          .trim();

  if (
      legacyRouteId.isNotEmpty ||
      legacyRouteName.isNotEmpty
  ) {
    assignedRoutes.add(
      SalesmanRoute(
        routeId:
            legacyRouteId,

        routeName:
            legacyRouteName,
      ),
    );
  }
}

final String?
    legacyPrimaryRoute =
    assignedRoutes.isNotEmpty
        ? assignedRoutes
            .first
            .routeName
        : null;
// ============================================================
// CREATE REAL APP USER FROM BACKEND
// ============================================================

final loggedInUser =
    AppUser(
  id:
      sessionUser['_id']
              ?.toString() ??
          sessionUser['id']
              ?.toString() ??
          user['id']
              ?.toString() ??
          '',

  name:
      sessionUser['name']
              ?.toString() ??
          user['name']
              ?.toString() ??
          '',

  role:
      serverRole == 'salesman'
          ? UserRole.salesman
          : UserRole.admin,

  branch:
      sessionUser[
                  'businessName']
              ?.toString() ??
          user['businessName']
              ?.toString() ??
          'Main Distribution Centre',

  mobile:
      sessionUser['mobile']
              ?.toString() ??
          user['mobile']
              ?.toString() ??
          '',

  salesmanId:
      serverRole == 'salesman'
          ? (
              sessionUser[
                          'salesmanId']
                      ?.toString() ??
                  user[
                          'salesmanId']
                      ?.toString()
            )
          : null,

  // ========================================================
  // LEGACY PRIMARY ROUTE
  // ========================================================

  route:
      legacyPrimaryRoute,

  // ========================================================
  // NEW MULTI-ROUTE SUPPORT
  // ========================================================

  routes:
      List<SalesmanRoute>.unmodifiable(
    assignedRoutes,
  ),

  permissions:
      permissions,
);


// ============================================================
// SAVE AUTHENTICATED USER IN UI SESSION
// ============================================================

UiSession.instance.signInFromBackend(
  loggedInUser,
);
DataSyncService.instance
    .startAutoSessionRefresh();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
        ),
        (_) => false,
      );
    } else {
      _message(
        data['message']?.toString() ??
            'Invalid login credentials.',
      );
    }
  } catch (error) {
    if (!mounted) return;

    _message(
      'Unable to connect to backend. Make sure server.js is running.',
    );
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}
  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/img/LoginBackground.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: AppColors.primary),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: ConstrainedBox(
  constraints: BoxConstraints(
    minHeight:
        (constraints.maxHeight - 52)
            .clamp(
              0.0,
              double.infinity,
            )
            .toDouble(),
  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _brand(),
                          const SizedBox(height: 28),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Choose your workspace role to continue',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _roleSelector(),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _identifierController,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      decoration: InputDecoration(
                                 labelText: _role == UserRole.admin
    ? 'Farm ID / Admin ID / Username'
    : 'Salesman ID / Mobile / Username',

hintText: _role == UserRole.admin
    ? 'Example: FARM123456'
    : 'Example: SM123456',
                                        prefixIcon: Icon(
                                          _role == UserRole.admin
                                              ? Icons
                                                    .admin_panel_settings_outlined
                                              : Icons.badge_outlined,
                                        ),
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? 'Enter your ID or username'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) =>
                                          _loading ? null : _login(),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'Enter your password'
                                          : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => setState(
                                              () => _rememberMe = !_rememberMe,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: _rememberMe,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  onChanged: (value) =>
                                                      setState(
                                                        () => _rememberMe =
                                                            value ?? false,
                                                      ),
                                                ),
                                                const Flexible(
                                                  child: Text(
                                                    'Remember me',
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                            ),
                                            onPressed: () => _message(
                                              'Password recovery requires backend integration.',
                                            ),
                                            child: const Text(
                                              'Forgot Password?',
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _login,
                                        child: _loading
                                            ? const SizedBox.square(
                                                dimension: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Text(
                                                _role == UserRole.admin
                                                    ? 'LOGIN AS ADMIN'
                                                    : 'LOGIN AS SALESMAN',
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        const Text(
                                          "Don't have an account?",
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      RegistrationScreen(
                                                        initialRole: _role,
                                                      ),
                                                ),
                                              ),
                                          child: const Text('Register'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                     const SizedBox(height: 16),

// ============================================================
// SOFTWARE DEVELOPER BRANDING
// ============================================================

Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  ),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.90),
    borderRadius: BorderRadius.circular(10),
  ),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.code_rounded,
        size: 14,
        color: AppColors.primary,
      ),
      SizedBox(width: 6),
      Text(
        'Developed & Powered by ',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        'TOTAL SOLUTION',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .2,
        ),
      ),
    ],
  ),
),

const SizedBox(height: 7),

const Text(
  'Secure Distribution Management  •  Version 1.0.0',
  textAlign: TextAlign.center,
  style: TextStyle(
    color: AppColors.textMuted,
    fontSize: 9.5,
    fontWeight: FontWeight.w500,
  ),
),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand() => Column(
    children: [
      Container(
        height: 112,
        width: 112,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowPrimary,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Image.asset(
            'assets/img/Logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.local_drink_rounded,
              color: AppColors.primary,
              size: 46,
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'KK ENTERPRISES',
        style: TextStyle(
          color: Colors.white,
          fontSize: 23,
          fontWeight: FontWeight.w900,
          letterSpacing: -.4,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Distribution Management System',
        style: TextStyle(color: Color(0xFFE3EEFF), fontSize: 12),
      ),
    ],
  );

  Widget _roleSelector() => Semantics(
    label: 'Login type',
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _roleOption(UserRole.admin, Icons.admin_panel_settings_outlined),
          _roleOption(UserRole.salesman, Icons.badge_outlined),
        ],
      ),
    ),
  );

  Widget _roleOption(UserRole role, IconData icon) {
    final selected = _role == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _role = role;
          _identifierController.clear();
        }),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 8)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                role == UserRole.admin ? 'Admin' : 'Salesman',
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
