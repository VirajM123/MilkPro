import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

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
        if (ApiConfig.token != null &&
            ApiConfig.token!.isNotEmpty)
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

      final permissions =
          data['permissions'];

      final Set<AppPermission> loadedPermissions =
          <AppPermission>{};

      if (permissions is List) {
        for (final permission in permissions) {
          final permissionName =
              permission.toString().trim();

          for (final value
              in AppPermission.values) {
            if (value.name == permissionName) {
              loadedPermissions.add(value);
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

  // ============================================================
  // SAVE ACCESS TO MONGODB
  // ============================================================

  Future<void> _save() async {
    if (_saving) return;

    try {
      setState(() {
        _saving = true;
      });

      final permissions = _selected
          .map(
            (permission) =>
                permission.name,
          )
          .toList()
        ..sort();

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/salesmen/${widget.salesmanId}/permissions',
        ),
        headers: _headers,
        body: jsonEncode({
          'permissions': permissions,
        }),
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
                    height: 16,
                  ),

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
                          onPressed:
                              _saving
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
                          onPressed:
                              _saving
                                  ? null
                                  : () {
                                      setState(
                                        () {
                                          _selected
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
              label:
                  '${_selected.length} enabled',
              color:
                  AppColors.success,
            ),
          ],
        ),
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
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),

                  value:
                      _selected.contains(
                    item.permission,
                  ),

                  onChanged:
                      _saving
                          ? null
                          : (enabled) {
                              setState(
                                () {
                                  if (enabled) {
                                    _selected
                                        .add(
                                      item.permission,
                                    );
                                  } else {
                                    _selected
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