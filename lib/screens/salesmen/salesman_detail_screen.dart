import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../common/access_denied_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'manage_access_screen.dart';

class SalesmanDetailScreen
    extends StatefulWidget {
  const SalesmanDetailScreen({
    super.key,
    required this.salesmanId,
  });

  final String salesmanId;

  @override
  State<SalesmanDetailScreen>
      createState() =>
          _SalesmanDetailScreenState();
}

class _SalesmanDetailScreenState
    extends State<SalesmanDetailScreen> {
  bool _loading = true;
  bool _saving = false;

  String _salesmanId = '';
  String _name = '';
  String _mobile = '';
  String _email = '';
  String _username = '';
  String _businessName = '';
  String _routeName = '';
  String _routeId = '';

  bool _isActive = true;

  final Set<AppPermission>
      _permissions = {};

  // ============================================================
  // HEADERS
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

    _salesmanId =
        widget.salesmanId
            .trim()
            .toUpperCase();

    _loadSalesman();
  }

  // ============================================================
  // LOAD SALESMAN
  // ============================================================

  Future<void> _loadSalesman() async {
    try {
      setState(() {
        _loading = true;
      });

      final response = await http.get(
        Uri.parse(
          ApiConfig.salesmanById(
            widget.salesmanId,
          ),
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
              'Unable to load salesman.',
        );
      }

      final rawData = body['data'];

      if (rawData is! Map) {
        throw Exception(
          'Invalid salesman response.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        rawData,
      );

      final loadedPermissions =
          <AppPermission>{};

      final rawPermissions =
          data['permissions'];

      if (rawPermissions is List) {
        for (final item
            in rawPermissions) {
          final name =
              item.toString().trim();

          for (final permission
              in AppPermission.values) {
            if (permission.name ==
                name) {
              loadedPermissions
                  .add(permission);
              break;
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _salesmanId =
            (data['salesmanId'] ??
                    widget.salesmanId)
                .toString();

        _name =
            (data['name'] ?? '')
                .toString();

        _mobile =
            (data['mobile'] ?? '')
                .toString();

        _email =
            (data['email'] ?? '')
                .toString();

        _username =
            (data['username'] ?? '')
                .toString();

        _businessName =
            (data['businessName'] ??
                    '')
                .toString();

        _routeName =
            (data['routeName'] ?? '')
                .toString();

        _routeId =
            (data['routeId'] ?? '')
                .toString();

        _isActive =
            data['isActive'] != false;

        _permissions
          ..clear()
          ..addAll(
            loadedPermissions,
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

  // ============================================================
  // MANAGE ACCESS
  // ============================================================

  Future<void> _manageAccess() async {
    final saved =
        await Navigator.of(context)
            .push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ManageAccessScreen(
          salesmanId: _salesmanId,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      await _loadSalesman();
    }
  }

  // ============================================================
  // EDIT SALESMAN
  // ============================================================

  Future<void> _edit() async {
    final name =
        TextEditingController(
      text: _name,
    );

    final mobile =
        TextEditingController(
      text: _mobile,
    );

    final email =
        TextEditingController(
      text: _email,
    );

    final username =
        TextEditingController(
      text: _username,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (
            sheetContext,
            setSheetState,
          ) {
            Future<void> save() async {
              if (saving) return;

              if (name.text
                  .trim()
                  .isEmpty) {
                _showMessage(
                  'Salesman name is required.',
                  error: true,
                );
                return;
              }

              if (mobile.text
                      .trim()
                      .length !=
                  10) {
                _showMessage(
                  'Enter a valid 10-digit mobile number.',
                  error: true,
                );
                return;
              }

              if (username.text
                  .trim()
                  .isEmpty) {
                _showMessage(
                  'Username is required.',
                  error: true,
                );
                return;
              }

              try {
                setSheetState(() {
                  saving = true;
                });

                setState(() {
                  _saving = true;
                });

                final response =
                    await http.put(
                  Uri.parse(
                    ApiConfig
                        .salesmanById(
                      _salesmanId,
                    ),
                  ),
                  headers: _headers,
                  body: jsonEncode({
                    'name':
                        name.text.trim(),
                    'mobile':
                        mobile.text.trim(),
                    'email':
                        email.text.trim(),
                    'username':
                        username.text.trim(),
                  }),
                );

                final Map<String, dynamic>
                    body =
                    jsonDecode(
                  response.body,
                ) as Map<String, dynamic>;

                if (response.statusCode !=
                        200 ||
                    body['success'] != true) {
                  throw Exception(
                    body['message'] ??
                        'Unable to update salesman.',
                  );
                }

                if (!mounted) return;

                Navigator.of(
                  sheetContext,
                ).pop();

                _showMessage(
                  body['message'] ??
                      'Salesman updated successfully.',
                );

                await _loadSalesman();
              } catch (error) {
                if (!mounted) return;

                setSheetState(() {
                  saving = false;
                });

                _showMessage(
                  _cleanError(error),
                  error: true,
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _saving = false;
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                6,
                18,
                MediaQuery.viewInsetsOf(
                      sheetContext,
                    ).bottom +
                    20,
              ),
              child:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Salesman',
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleLarge,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Full name',
                        prefixIcon: Icon(
                          Icons
                              .person_outline,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    TextField(
                      controller: mobile,
                      keyboardType:
                          TextInputType.phone,
                      maxLength: 10,
                      decoration:
                          const InputDecoration(
                        labelText: 'Mobile',
                        prefixIcon: Icon(
                          Icons
                              .phone_outlined,
                        ),
                        counterText: '',
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    TextField(
                      controller: email,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      decoration:
                          const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons
                              .email_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    TextField(
                      controller:
                          username,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Username',
                        prefixIcon: Icon(
                          Icons
                              .alternate_email_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    TextFormField(
                      initialValue:
                          _routeName.isEmpty
                              ? 'Not Assigned'
                              : _routeName,
                      readOnly: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Assigned Route',
                        prefixIcon: Icon(
                          Icons
                              .route_outlined,
                        ),
                        helperText:
                            'Change route from Route Master.',
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton(
                        onPressed:
                            saving
                                ? null
                                : save,
                        child: Text(
                          saving
                              ? 'Saving...'
                              : 'Save Changes',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    await Future.delayed(
      const Duration(
        milliseconds: 250,
      ),
    );

    name.dispose();
    mobile.dispose();
    email.dispose();
    username.dispose();
  }

  // ============================================================
  // ACTIVE / INACTIVE
  // ============================================================

  Future<void> _setActive(
    bool value,
  ) async {
    if (_saving) return;

    final previous = _isActive;

    setState(() {
      _isActive = value;
      _saving = true;
    });

    try {
      final response =
          await http.put(
        Uri.parse(
          ApiConfig.salesmanById(
            _salesmanId,
          ),
        ),
        headers: _headers,
        body: jsonEncode({
          'isActive': value,
        }),
      );

      final Map<String, dynamic> body =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (response.statusCode != 200 ||
          body['success'] != true) {
        throw Exception(
          body['message'] ??
              'Unable to update salesman status.',
        );
      }

      if (!mounted) return;

      _showMessage(
        value
            ? 'Salesman activated successfully.'
            : 'Salesman deactivated successfully.',
      );

      await _loadSalesman();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isActive = previous;
      });

      _showMessage(
        _cleanError(error),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  void _preview() {
    UiSession.instance
        .previewSalesman(
      _salesmanId,
    );

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) =>
            const DashboardScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

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

    if (text.startsWith(
      'Exception: ',
    )) {
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

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Salesman Details',
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  _loadSalesman,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  28,
                ),
                children: [
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor:
                                AppColors
                                    .primarySoft,
                            foregroundColor:
                                AppColors
                                    .primary,
                            child: Text(
                              _initials(
                                _name,
                              ),
                              style:
                                  const TextStyle(
                                fontSize:
                                    19,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 11,
                          ),
                          Text(
                            _name,
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            'Salesman · $_salesmanId',
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodyMedium,
                          ),
                          const SizedBox(
                            height: 9,
                          ),
                          StatusChip(
                            label: _isActive
                                ? 'Active'
                                : 'Inactive',
                            color: _isActive
                                ? AppColors
                                    .success
                                : AppColors
                                    .error,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _section(
                    'CONTACT',
                    [
                      _info(
                        Icons
                            .phone_outlined,
                        'Mobile',
                        _mobile,
                      ),
                      if (_email.isNotEmpty)
                        _info(
                          Icons
                              .email_outlined,
                          'Email',
                          _email,
                        ),
                      if (_username
                          .isNotEmpty)
                        _info(
                          Icons
                              .alternate_email_rounded,
                          'Username',
                          _username,
                        ),
                      _info(
                        Icons
                            .route_outlined,
                        'Assigned route',
                        _routeName.isEmpty
                            ? 'Not Assigned'
                            : _routeName,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  const AppSectionTitle(
                    title: 'Today',
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Row(
                    children: [
                      Expanded(
                        child:
                            SummaryCard(
                          label:
                              'Orders',
                          value: '12',
                          icon: Icons
                              .shopping_bag_outlined,
                          color:
                              AppColors
                                  .primary,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            SummaryCard(
                          label:
                              'Visits',
                          value:
                              '8 / 15',
                          icon: Icons
                              .pin_drop_outlined,
                          color:
                              AppColors
                                  .info,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Row(
                    children: [
                      Expanded(
                        child:
                            SummaryCard(
                          label:
                              'Sales',
                          value:
                              '₹18,420',
                          icon: Icons
                              .receipt_long_outlined,
                          color:
                              AppColors
                                  .success,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            SummaryCard(
                          label:
                              'Collection',
                          value:
                              '₹12,300',
                          icon: Icons
                              .payments_outlined,
                          color:
                              AppColors
                                  .purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  Card(
                    child: ListTile(
                      leading:
                          const Icon(
                        Icons
                            .admin_panel_settings_outlined,
                        color: AppColors
                            .primary,
                      ),
                      title:
                          const Text(
                        'Feature access',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      subtitle: Text(
                        '${_permissions.length} / ${AppPermission.values.length} permissions enabled',
                      ),
                      trailing:
                          const Icon(
                        Icons
                            .chevron_right_rounded,
                      ),
                      onTap:
                          _manageAccess,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _section(
                    'ACCOUNT',
                    [
                      SwitchListTile
                          .adaptive(
                        contentPadding:
                            EdgeInsets
                                .zero,
                        title:
                            const Text(
                          'Active account',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                        subtitle:
                            const Text(
                          'Allow this salesman to use the field workspace',
                        ),
                        value:
                            _isActive,
                        onChanged:
                            _saving
                                ? null
                                : _setActive,
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding:
                            EdgeInsets
                                .zero,
                        leading:
                            const Icon(
                          Icons
                              .edit_outlined,
                        ),
                        title:
                            const Text(
                          'Edit salesman',
                        ),
                        trailing:
                            const Icon(
                          Icons
                              .chevron_right_rounded,
                        ),
                        onTap:
                            _saving
                                ? null
                                : _edit,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  OutlinedButton.icon(
                    onPressed:
                        _preview,
                    icon:
                        const Icon(
                      Icons
                          .phone_android_rounded,
                    ),
                    label:
                        const Text(
                      'Preview Salesman Workspace',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(
    String title,
    List<Widget> children,
  ) =>
      Card(
        child: Padding(
          padding:
              const EdgeInsets.all(
            15,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
                height: 8,
              ),
              ...children,
            ],
          ),
        ),
      );

  Widget _info(
    IconData icon,
    String label,
    String value,
  ) =>
      ListTile(
        contentPadding:
            EdgeInsets.zero,
        dense: true,
        leading: Icon(
          icon,
          color: AppColors
              .textSecondary,
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors
                .textSecondary,
            fontSize: 11,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color:
                AppColors.textPrimary,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      );

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