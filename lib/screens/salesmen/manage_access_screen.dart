import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../common/access_denied_screen.dart';

class ManageAccessScreen extends StatefulWidget {
  const ManageAccessScreen({
    super.key,
    required this.salesmanId,
  });

  final String salesmanId;

  @override
  State<ManageAccessScreen> createState() =>
      _ManageAccessScreenState();
}

class _ManageAccessScreenState
    extends State<ManageAccessScreen> {
  final Set<AppPermission> _selected =
      <AppPermission>{};
  final Set<AppPermission> _inherited =
      <AppPermission>{};
  final Set<AppPermission> _custom =
      <AppPermission>{};

  String _permissionMode = 'inherit';
  String _query = '';

  bool _loading = true;
  bool _saving = false;

  String _salesmanName = '';
  String _salesmanCode = '';

  // ============================================================
  // API HEADERS
  // ============================================================

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (ApiConfig.token.isNotEmpty)
          'Authorization':
              'Bearer ${ApiConfig.token}',
      };

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _salesmanCode =
        widget.salesmanId.trim().toUpperCase();

    _loadSalesmanAccess();
  }

  // ============================================================
  // LOAD SALESMAN + CURRENT PERMISSIONS
  // ============================================================

  Future<void> _loadSalesmanAccess() async {
    try {
      setState(() {
        _loading = true;
      });

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/salesmen/${widget.salesmanId}',
        ),
        headers: _headers,
      );

      final Map<String, dynamic> body =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (response.statusCode != 200 ||
          body['success'] != true) {
        throw Exception(
          body['message'] ??
              'Unable to load salesman access.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        body['data'] as Map,
      );

      final mode = (data['permissionMode'] ?? 'inherit')
          .toString()
          .toLowerCase();
      _permissionMode =
          mode == 'custom' ? 'custom' : 'inherit';

      final permissions =
          data['permissions'];
      final customPermissions =
          data['customPermissions'];

      final Set<AppPermission> loadedEffective =
          <AppPermission>{};

      if (permissions is List) {
        for (final permission in permissions) {
          final permissionName =
              permission.toString().trim();

          for (final value
              in AppPermission.values) {
            if (value.name == permissionName) {
              loadedEffective.add(value);
              break;
            }
          }
        }
      }

      final Set<AppPermission> loadedCustom =
          <AppPermission>{};

      if (customPermissions is List) {
        for (final permission in customPermissions) {
          final permissionName =
              permission.toString().trim();

          for (final value
              in AppPermission.values) {
            if (value.name == permissionName) {
              loadedCustom.add(value);
              break;
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _salesmanName =
            (data['name'] ?? '').toString();

        _salesmanCode =
            (data['salesmanId'] ??
                    widget.salesmanId)
                .toString();

        _inherited
          ..clear()
          ..addAll(loadedEffective);

        _custom
          ..clear()
          ..addAll(
            loadedCustom.isNotEmpty
                ? loadedCustom
                : loadedEffective,
          );

        _selected
          ..clear()
          ..addAll(
            _permissionMode == 'custom'
                ? _custom
                : _inherited,
          );

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

  void _setPermissionMode(String mode) {
    if (_permissionMode == mode) return;

    setState(() {
      _permissionMode = mode;

      if (mode == 'custom') {
        if (_custom.isEmpty && _inherited.isNotEmpty) {
          _custom.addAll(_inherited);
        }
        _selected
          ..clear()
          ..addAll(_custom);
      } else {
        _selected
          ..clear()
          ..addAll(_inherited);
      }
    });
  }

  // ============================================================
  // SAVE ACCESS TO MONGODB
  // ============================================================

  Future<void> _save() async {
    if (_saving) return;

    try {
      setState(() {
        _saving = true;
      });

      final Map<String, dynamic> payload = {
        'permissionMode': _permissionMode,
      };

      if (_permissionMode == 'custom') {
        payload['permissions'] = _selected
            .map(
              (permission) =>
                  permission.name,
            )
            .toList()
          ..sort();
      }

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/salesmen/${widget.salesmanId}/permissions',
        ),
        headers: _headers,
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> body =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (response.statusCode != 200 ||
          body['success'] != true) {
        throw Exception(
          body['message'] ??
              'Unable to save feature access.',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            body['message'] ??
                'Salesman feature access saved successfully.',
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

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? AppColors.error : null,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (UiSession.instance.role != UserRole.admin) {
      return const AccessDeniedScreen();
    }

    final query =
        _query.trim().toLowerCase();

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Manage Access',
        subtitle: _salesmanName.isEmpty
            ? _salesmanCode
            : '$_salesmanName · $_salesmanCode',
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  _loadSalesmanAccess,

              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  110,
                ),

                children: [
                  _profileCard(),

                  const SizedBox(
                    height: 14,
                  ),

                  _permissionModeSelector(),

                  const SizedBox(
                    height: 14,
                  ),

                  if (_permissionMode == 'inherit') ...[
                    _inheritedBanner(),
                    const SizedBox(
                      height: 4,
                    ),
                  ],

                  const AppSectionTitle(
                    title:
                        'Feature Access',
                    subtitle:
                        'Choose the tools available in the salesman workspace.',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  AppSearchField(
                    hint:
                        'Search permissions',
                    onChanged: (value) =>
                        setState(
                      () =>
                          _query = value,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed: (_saving ||
                                  _permissionMode ==
                                      'inherit')
                              ? null
                              : () {
                                  setState(
                                    () {
                                      _selected
                                        ..clear()
                                        ..addAll(
                                          AppPermission
                                              .values,
                                        );
                                      _custom
                                        ..clear()
                                        ..addAll(
                                          AppPermission
                                              .values,
                                        );
                                    },
                                  );
                                },
                          child:
                              const Text(
                            'Enable All',
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed: (_saving ||
                                  _permissionMode ==
                                      'inherit')
                              ? null
                              : () {
                                  setState(
                                    () {
                                      _selected
                                          .clear();
                                      _custom
                                          .clear();
                                    },
                                  );
                                },
                          child:
                              const Text(
                            'Disable All',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  for (final group
                      in permissionGroups)
                    if (query.isEmpty ||
                        group.title
                            .toLowerCase()
                            .contains(
                              query,
                            ) ||
                        group.items.any(
                          (item) =>
                              item.label
                                  .toLowerCase()
                                  .contains(
                                    query,
                                  ),
                        ))
                      _permissionGroup(
                        group,
                        query,
                      ),
                ],
              ),
            ),

      bottomNavigationBar:
          _loading
              ? null
              : BottomActionBar(
                  label: _saving
                      ? 'SAVING...'
                      : 'SAVE ACCESS',

                  onPressed: () {
                    if (!_saving) {
                      _save();
                    }
                  },
                ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _profileCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor:
                  AppColors.primarySoft,
              foregroundColor:
                  AppColors.primary,
              child: Text(
                _initials(
                  _salesmanName.isEmpty
                      ? _salesmanCode
                      : _salesmanName,
                ),
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    _salesmanName.isEmpty
                        ? 'Salesman'
                        : _salesmanName,
                    style:
                        Theme.of(context)
                            .textTheme
                            .titleMedium,
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    '$_salesmanCode · Salesman',
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall,
                  ),
                ],
              ),
            ),

            StatusChip(
              label: _permissionMode == 'inherit'
                  ? 'Inherited (${_selected.length})'
                  : 'Custom (${_selected.length})',
              color: _permissionMode == 'inherit'
                  ? AppColors.primary
                  : AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PERMISSION MODE SELECTOR
  // ============================================================

  Widget _permissionModeSelector() {
    final isInherit = _permissionMode == 'inherit';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PERMISSION SOURCE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _saving
                        ? null
                        : () => _setPermissionMode('inherit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isInherit
                            ? AppColors.primary
                            : AppColors.primarySoft
                                .withValues(alpha: 0.3),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: isInherit
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 16,
                            color: isInherit
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Use Common Access',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isInherit
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _saving
                        ? null
                        : () => _setPermissionMode('custom'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: !isInherit
                            ? AppColors.primary
                            : AppColors.primarySoft
                                .withValues(alpha: 0.3),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: !isInherit
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: !isInherit
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Custom Access',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: !isInherit
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INHERITED BANNER
  // ============================================================

  Widget _inheritedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Inherited from Common Salesman Access',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Permissions below are managed by the Common Salesman Access template. Switches are view-only. Select "Custom Access" above to customize permissions for this specific salesman.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERMISSION GROUP
  // ============================================================

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
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            14,
            13,
            10,
            6,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                group.title
                    .toUpperCase(),
                style:
                    const TextStyle(
                  color:
                      AppColors.primary,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              for (final item
                  in items)
                SwitchListTile
                    .adaptive(
                  contentPadding:
                      EdgeInsets.zero,

                  visualDensity:
                      VisualDensity
                          .compact,

                  title: Text(
                    item.label,
                    style:
                        TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight
                              .w600,
                      color: _permissionMode == 'inherit'
                          ? Colors.black54
                          : Colors.black87,
                    ),
                  ),

                  value:
                      _selected.contains(
                    item.permission,
                  ),

                  onChanged: (_saving ||
                          _permissionMode == 'inherit')
                      ? null
                      : (enabled) {
                          setState(
                            () {
                              if (enabled) {
                                _selected
                                    .add(
                                  item.permission,
                                );
                                _custom
                                    .add(
                                  item.permission,
                                );
                              } else {
                                _selected
                                    .remove(
                                  item.permission,
                                );
                                _custom
                                    .remove(
                                  item.permission,
                                );
                              }
                            },
                          );
                        },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String _initials(String name) {
    final parts = name
        .split(' ')
        .where(
          (part) =>
              part.trim().isNotEmpty,
        )
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return 'SM';
    }

    return parts
        .map(
          (part) =>
              part[0].toUpperCase(),
        )
        .join();
  }
}