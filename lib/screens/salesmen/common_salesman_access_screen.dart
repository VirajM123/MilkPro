import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../common/access_denied_screen.dart';

class CommonSalesmanAccessScreen extends StatefulWidget {
  const CommonSalesmanAccessScreen({super.key});

  @override
  State<CommonSalesmanAccessScreen> createState() =>
      _CommonSalesmanAccessScreenState();
}

class _CommonSalesmanAccessScreenState
    extends State<CommonSalesmanAccessScreen> {
  final Set<AppPermission> _selected = <AppPermission>{};

  String _query = '';
  bool _loading = true;
  bool _saving = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (ApiConfig.token.isNotEmpty)
          'Authorization': 'Bearer ${ApiConfig.token}',
      };

  @override
  void initState() {
    super.initState();
    _loadCommonAccess();
  }

  Future<void> _loadCommonAccess() async {
    try {
      setState(() {
        _loading = true;
      });

      final response = await http.get(
        Uri.parse(ApiConfig.salesmanDefaultPermissions),
        headers: _headers,
      );

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(
          body['message'] ??
              'Unable to load common salesman permissions.',
        );
      }

      final data =
          Map<String, dynamic>.from(body['data'] as Map);
      final permissions = data['permissions'];

      final Set<AppPermission> loadedPermissions =
          <AppPermission>{};

      if (permissions is List) {
        for (final permission in permissions) {
          final permissionName =
              permission.toString().trim();
          for (final value in AppPermission.values) {
            if (value.name == permissionName) {
              loadedPermissions.add(value);
              break;
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _selected
          ..clear()
          ..addAll(loadedPermissions);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        _cleanError(error),
        error: true,
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    try {
      setState(() {
        _saving = true;
      });

      final permissions = _selected
          .map((permission) => permission.name)
          .toList()
        ..sort();

      final response = await http.put(
        Uri.parse(ApiConfig.salesmanDefaultPermissions),
        headers: _headers,
        body: jsonEncode({
          'permissions': permissions,
        }),
      );

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(
          body['message'] ??
              'Unable to save common salesman permissions.',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            body['message'] ??
                'Common salesman permissions saved successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        _cleanError(error),
        error: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
  }

  String _cleanError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    if (UiSession.instance.role != UserRole.admin) {
      return const AccessDeniedScreen();
    }

    final query = _query.trim().toLowerCase();

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Common Salesman Access',
        subtitle:
            'Default permissions for salesmen using inherited access',
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadCommonAccess,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  110,
                ),
                children: [
                  _infoCard(),
                  const SizedBox(height: 16),
                  const AppSectionTitle(
                    title: 'Common Permissions',
                    subtitle:
                        'All salesmen set to "Use Common Access" receive these permissions.',
                  ),
                  const SizedBox(height: 12),
                  AppSearchField(
                    hint: 'Search permissions',
                    onChanged: (value) => setState(
                      () => _query = value,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  setState(() {
                                    _selected
                                      ..clear()
                                      ..addAll(
                                        AppPermission.values,
                                      );
                                  });
                                },
                          child: const Text('Enable All'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  setState(() {
                                    _selected.clear();
                                  });
                                },
                          child: const Text('Disable All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final group in permissionGroups)
                    if (query.isEmpty ||
                        group.title
                            .toLowerCase()
                            .contains(query) ||
                        group.items.any(
                          (item) => item.label
                              .toLowerCase()
                              .contains(query),
                        ))
                      _permissionGroup(group, query),
                ],
              ),
            ),
      bottomNavigationBar: _loading
          ? null
          : BottomActionBar(
              label:
                  _saving ? 'SAVING...' : 'SAVE COMMON ACCESS',
              onPressed: () {
                if (!_saving) {
                  _save();
                }
              },
            ),
    );
  }

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              child: const Icon(
                Icons.groups_rounded,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Template',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Applies automatically to inherited salesmen',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ],
              ),
            ),
            StatusChip(
              label:
                  '${_selected.length}/${AppPermission.values.length} on',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionGroup(
    PermissionGroup group,
    String query,
  ) {
    final items = query.isEmpty
        ? group.items
        : group.items
            .where(
              (item) =>
                  group.title
                      .toLowerCase()
                      .contains(query) ||
                  item.label
                      .toLowerCase()
                      .contains(query),
            )
            .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 4),
              for (final item in items)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _selected.contains(item.permission),
                  onChanged: _saving
                      ? null
                      : (enabled) {
                          setState(() {
                            if (enabled) {
                              _selected.add(item.permission);
                            } else {
                              _selected.remove(item.permission);
                            }
                          });
                        },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

