import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import 'manage_access_screen.dart';
import 'salesman_detail_screen.dart';

enum _SalesmanFilter { all, active, inactive }

class SalesmanManagementScreen extends StatefulWidget {
  const SalesmanManagementScreen({super.key});

  @override
  State<SalesmanManagementScreen> createState() =>
      _SalesmanManagementScreenState();
}

class _SalesmanManagementScreenState
    extends State<SalesmanManagementScreen> {
  String _query = '';
  _SalesmanFilter _filter = _SalesmanFilter.all;

  bool _loading = true;

  final List<SalesmanProfile> _salesmen = [];

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (ApiConfig.token != null &&
            ApiConfig.token!.isNotEmpty)
          'Authorization': 'Bearer ${ApiConfig.token}',
      };

  @override
  void initState() {
    super.initState();
    _loadSalesmen();
  }

  Future<void> _loadSalesmen() async {
    try {
      setState(() {
        _loading = true;
      });

      final response = await http.get(
        Uri.parse(ApiConfig.salesmen),
        headers: _headers,
      );

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 ||
          body['success'] != true) {
        throw Exception(
          body['message'] ?? 'Unable to load salesmen.',
        );
      }

      final List rawData =
          body['data'] is List ? body['data'] as List : [];

      final List<SalesmanProfile> loaded = [];

      for (final item in rawData) {
        if (item is! Map) continue;

        final data =
            Map<String, dynamic>.from(item);

        final Set<AppPermission> permissions = {};

        final rawPermissions = data['permissions'];

        if (rawPermissions is List) {
          for (final permission in rawPermissions) {
            final permissionName =
                permission.toString().trim();

            for (final value in AppPermission.values) {
              if (value.name == permissionName) {
                permissions.add(value);
                break;
              }
            }
          }
        }

        final salesmanId =
            (data['salesmanId'] ?? '').toString();

        if (salesmanId.isEmpty) continue;

        loaded.add(
          SalesmanProfile(
            id: salesmanId,
            name: (data['name'] ?? '').toString(),
            mobile: (data['mobile'] ?? '').toString(),
            route: (data['routeName'] ?? '').toString(),
            isActive: data['isActive'] != false,
            permissions: permissions,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _salesmen
          ..clear()
          ..addAll(loaded);

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

  List<SalesmanProfile> get _filtered {
    final query = _query.trim().toLowerCase();

    return _salesmen.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query) ||
          item.route.toLowerCase().contains(query);

      final matchesFilter =
          _filter == _SalesmanFilter.all ||
          (_filter == _SalesmanFilter.active &&
              item.isActive) ||
          (_filter == _SalesmanFilter.inactive &&
              !item.isActive);

      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _openDetail(
    SalesmanProfile salesman,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SalesmanDetailScreen(
          salesmanId: salesman.id,
        ),
      ),
    );

    if (!mounted) return;

    await _loadSalesmen();
  }

  Future<void> _openAccess(
    SalesmanProfile salesman,
  ) async {
    final bool? saved =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManageAccessScreen(
          salesmanId: salesman.id,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      await _loadSalesmen();
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    final all = _salesmen;

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Salesmen',
        subtitle: 'Team and feature access',
      ),
      body: RefreshIndicator(
        onRefresh: _loadSalesmen,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    hint: 'Name, ID or route',
                    onChanged: (value) =>
                        setState(() => _query = value),
                  ),
                ),
                const SizedBox(width: 9),
                IconButton.filledTonal(
                  onPressed: _showFilter,
                  icon:
                      const Icon(Icons.tune_rounded),
                  tooltip: 'Filter',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _chip(
                  'All ${all.length}',
                  _SalesmanFilter.all,
                ),
                _chip(
                  'Active ${all.where((item) => item.isActive).length}',
                  _SalesmanFilter.active,
                ),
                _chip(
                  'Inactive ${all.where((item) => !item.isActive).length}',
                  _SalesmanFilter.inactive,
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppSectionTitle(
              title: '${_filtered.length} Salesmen',
              subtitle:
                  'Live data from MAS_SALESMAN',
            ),
            const SizedBox(height: 10),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 50,
                ),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filtered.isEmpty)
              const Card(
                child: AppEmptyState(
                  icon: Icons.badge_outlined,
                  title: 'No Salesmen Found',
                  message:
                      'Try changing the search or status filter.',
                ),
              )
            else
              ..._filtered.map(_card),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    String label,
    _SalesmanFilter value,
  ) =>
      ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) =>
            setState(() => _filter = value),
      );

  Widget _card(
    SalesmanProfile salesman,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openDetail(salesman),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppColors.primarySoft,
                        foregroundColor:
                            AppColors.primary,
                        child: Text(
                          _initials(salesman.name),
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              salesman.name,
                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Salesman ID: ${salesman.id}',
                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: salesman.isActive
                            ? 'Active'
                            : 'Inactive',
                        color: salesman.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _meta(
                          Icons.route_outlined,
                          'Route',
                          salesman.route.isEmpty
                              ? 'Not Assigned'
                              : salesman.route,
                        ),
                      ),
                      Expanded(
                        child: _meta(
                          Icons.phone_outlined,
                          'Mobile',
                          salesman.mobile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${salesman.permissions.length} permissions enabled',
                          style: const TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            _openAccess(salesman),
                        child:
                            const Text('Manage Access'),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () =>
                            _openDetail(salesman),
                        icon:
                            const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _meta(
    IconData icon,
    String label,
    String value,
  ) =>
      Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        AppColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  void _showFilter() =>
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            2,
            18,
            22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Filter salesmen',
                style:
                    Theme.of(context)
                        .textTheme
                        .titleLarge,
              ),
              const SizedBox(height: 12),
              for (final filter
                  in _SalesmanFilter.values)
                ListTile(
                  leading: Icon(
                    _filter == filter
                        ? Icons
                            .radio_button_checked_rounded
                        : Icons
                            .radio_button_off_rounded,
                    color: _filter == filter
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  title: Text(
                    filter.name[0].toUpperCase() +
                        filter.name.substring(1),
                  ),
                  onTap: () {
                    setState(() {
                      _filter = filter;
                    });

                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      );

  String _initials(String name) {
    final parts = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return 'SM';
    }

    return parts
        .map(
          (part) => part[0].toUpperCase(),
        )
        .join();
  }
}