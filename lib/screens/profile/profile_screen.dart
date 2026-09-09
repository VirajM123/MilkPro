import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  bool _loading = true;
  bool _saving = false;

  Map<String, dynamic> _profile = {};

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
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _loading = true;
      });

      final response = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: _headers,
      );

      final Map<String, dynamic> body =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (response.statusCode != 200 ||
          body['success'] != true) {
        throw Exception(
          body['message'] ??
              'Unable to load profile.',
        );
      }

      final rawData = body['data'];

      if (rawData is! Map) {
        throw Exception(
          'Invalid profile response.',
        );
      }

      if (!mounted) return;

      setState(() {
        _profile =
            Map<String, dynamic>.from(rawData);

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
  // ROLE
  // ============================================================

  bool get _isAdmin =>
      (_profile['role'] ?? '')
          .toString()
          .toLowerCase() ==
      'admin';

  bool get _isSalesman =>
      (_profile['role'] ?? '')
          .toString()
          .toLowerCase() ==
      'salesman';

  String _value(String key) =>
      (_profile[key] ?? '').toString();

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Future<void> _editProfile() async {
    final name = TextEditingController(
      text: _value('name'),
    );  

    final mobile = TextEditingController(
      text: _value('mobile'),
    );

    final email = TextEditingController(
      text: _value('email'),
    );

    final username = TextEditingController(
      text: _value('username'),
    );

    final businessName =
        TextEditingController(
      text: _value('businessName'),
    );

    final address = TextEditingController(
      text: _value('address'),
    );

    final city = TextEditingController(
      text: _value('city'),
    );

    final state = TextEditingController(
      text: _value('state'),
    );

    final pin = TextEditingController(
      text: _value('pin'),
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

              if (name.text.trim().isEmpty) {
                _showMessage(
                  'Name is required.',
                  error: true,
                );
                return;
              }

              if (mobile.text.trim().length !=
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

                if (mounted) {
                  setState(() {
                    _saving = true;
                  });
                }
final payload = <String, dynamic>{
  'name': name.text.trim(),
  'mobile': mobile.text.trim(),
  'email': email.text.trim(),
  'username': username.text.trim(),
};

if (_isAdmin) {
  payload['businessName'] =
      businessName.text.trim();

  payload.addAll({
    'address': address.text.trim(),
    'city': city.text.trim(),
    'state': state.text.trim(),
    'pin': pin.text.trim(),
  });
}


                final response =
                    await http.put(
                  Uri.parse(
                    ApiConfig.profile,
                  ),
                  headers: _headers,
                  body:
                      jsonEncode(payload),
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
                        'Unable to update profile.',
                  );
                }

                if (!mounted) return;

                Navigator.of(
                  sheetContext,
                ).pop();

                _showMessage(
                  body['message'] ??
                      'Profile updated successfully.',
                );

                await _loadProfile();
              } catch (error) {
                if (!mounted) return;

                _showMessage(
                  _cleanError(error),
                  error: true,
                );

                setSheetState(() {
                  saving = false;
                });
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
                8,
                18,
                MediaQuery.viewInsetsOf(
                      sheetContext,
                    ).bottom +
                    22,
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
                      'Edit Profile',
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
                              .person_outline_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 11,
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
                      height: 11,
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
                      height: 11,
                    ),

                    TextField(
                      controller: username,
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
                      height: 11,
                    ),

              TextFormField(
  controller: businessName,
  readOnly: _isSalesman,
  decoration: InputDecoration(
    labelText: 'Business name',
    prefixIcon: const Icon(
      Icons.storefront_outlined,
    ),
    helperText: _isSalesman
        ? 'Business details are controlled by administrator.'
        : null,
  ),
),

                    if (_isAdmin) ...[
                      const SizedBox(
                        height: 11,
                      ),
                      TextField(
                        controller:
                            address,
                        maxLines: 2,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Address',
                          prefixIcon:
                              Icon(
                            Icons
                                .location_on_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 11,
                      ),
                      TextField(
                        controller: city,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'City',
                          prefixIcon:
                              Icon(
                            Icons
                                .location_city_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 11,
                      ),
                      TextField(
                        controller: state,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'State',
                          prefixIcon:
                              Icon(
                            Icons
                                .map_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 11,
                      ),
                      TextField(
                        controller: pin,
                        keyboardType:
                            TextInputType
                                .number,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'PIN Code',
                          prefixIcon:
                              Icon(
                            Icons
                                .pin_drop_outlined,
                          ),
                        ),
                      ),
                    ],

                    if (_isSalesman &&
                        _value(
                          'routeName',
                        ).isNotEmpty) ...[
                      const SizedBox(
                        height: 11,
                      ),
                      TextFormField(
                        initialValue:
                            _value(
                          'routeName',
                        ),
                        readOnly: true,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Assigned Route',
                          prefixIcon:
                              Icon(
                            Icons
                                .route_outlined,
                          ),
                          helperText:
                              'Route is controlled by administrator.',
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 20,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            saving
                                ? null
                                : save,
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .save_outlined,
                              ),
                        label: Text(
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
    businessName.dispose();
    address.dispose();
    city.dispose();
    state.dispose();
    pin.dispose();
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> _changePassword() async {
    final currentPassword =
        TextEditingController();

    final newPassword =
        TextEditingController();

    final confirmPassword =
        TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;
        bool showCurrent = false;
        bool showNew = false;

        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            Future<void> save() async {
              if (saving) return;

              if (currentPassword
                      .text.isEmpty ||
                  newPassword.text.isEmpty) {
                _showMessage(
                  'Enter current and new password.',
                  error: true,
                );
                return;
              }

              if (newPassword.text.length <
                  6) {
                _showMessage(
                  'New password must contain at least 6 characters.',
                  error: true,
                );
                return;
              }

              if (newPassword.text !=
                  confirmPassword.text) {
                _showMessage(
                  'New password and confirm password do not match.',
                  error: true,
                );
                return;
              }

              try {
                setDialogState(() {
                  saving = true;
                });

                final response =
                    await http.put(
                  Uri.parse(
                    ApiConfig
                        .profilePassword,
                  ),
                  headers: _headers,
                  body: jsonEncode({
                    'currentPassword':
                        currentPassword
                            .text,
                    'newPassword':
                        newPassword.text,
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
                        'Unable to change password.',
                  );
                }

                if (!mounted) return;

                Navigator.of(
                  dialogContext,
                ).pop();

                _showMessage(
                  body['message'] ??
                      'Password changed successfully.',
                );
              } catch (error) {
                if (!mounted) return;

                setDialogState(() {
                  saving = false;
                });

                _showMessage(
                  _cleanError(error),
                  error: true,
                );
              }
            }

            return AlertDialog(
              title: const Text(
                'Change Password',
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        currentPassword,
                    obscureText:
                        !showCurrent,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Current password',
                      prefixIcon:
                          const Icon(
                        Icons
                            .lock_outline_rounded,
                      ),
                      suffixIcon:
                          IconButton(
                        onPressed: () {
                          setDialogState(
                            () {
                              showCurrent =
                                  !showCurrent;
                            },
                          );
                        },
                        icon: Icon(
                          showCurrent
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextField(
                    controller:
                        newPassword,
                    obscureText: !showNew,
                    decoration:
                        InputDecoration(
                      labelText:
                          'New password',
                      prefixIcon:
                          const Icon(
                        Icons
                            .password_rounded,
                      ),
                      suffixIcon:
                          IconButton(
                        onPressed: () {
                          setDialogState(
                            () {
                              showNew =
                                  !showNew;
                            },
                          );
                        },
                        icon: Icon(
                          showNew
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextField(
                    controller:
                        confirmPassword,
                    obscureText: !showNew,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Confirm new password',
                      prefixIcon: Icon(
                        Icons
                            .verified_user_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () =>
                          Navigator.pop(
                            dialogContext,
                          ),
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      saving ? null : save,
                  child: Text(
                    saving
                        ? 'Saving...'
                        : 'Change Password',
                  ),
                ),
              ],
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

    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
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
    if (_loading) {
      return const Scaffold(
        appBar:
            PremiumAppBar(title: 'Profile'),
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final name = _value('name');

    final roleLabel =
        _isAdmin ? 'Admin' : 'Salesman';

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Profile',
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
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
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor:
                          AppColors
                              .primarySoft,
                      foregroundColor:
                          AppColors.primary,
                      child: Text(
                        _initials(name),
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      name.isEmpty
                          ? roleLabel
                          : name,
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleLarge,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    StatusChip(
                      label: roleLabel,
                      color: _isAdmin
                          ? AppColors.primary
                          : AppColors
                              .success,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (_isAdmin &&
                        _value(
                          'adminId',
                        ).isNotEmpty)
                      _row(
                        Icons
                            .admin_panel_settings_outlined,
                        'Admin ID',
                        _value(
                          'adminId',
                        ),
                      ),

                    if (_isSalesman &&
                        _value(
                          'salesmanId',
                        ).isNotEmpty)
                      _row(
                        Icons
                            .badge_outlined,
                        'Salesman ID',
                        _value(
                          'salesmanId',
                        ),
                      ),

                    if (_value(
                      'businessName',
                    ).isNotEmpty)
                      _row(
                        Icons
                            .storefront_outlined,
                        'Business',
                        _value(
                          'businessName',
                        ),
                      ),

                    if (_value(
                      'mobile',
                    ).isNotEmpty)
                      _row(
                        Icons
                            .phone_outlined,
                        'Mobile',
                        _value(
                          'mobile',
                        ),
                      ),

                    if (_value(
                      'email',
                    ).isNotEmpty)
                      _row(
                        Icons
                            .email_outlined,
                        'Email',
                        _value(
                          'email',
                        ),
                      ),

                    if (_value(
                      'username',
                    ).isNotEmpty)
                      _row(
                        Icons
                            .alternate_email_rounded,
                        'Username',
                        _value(
                          'username',
                        ),
                      ),

                    if (_isSalesman)
                      _row(
                        Icons
                            .route_outlined,
                        'Assigned Route',
                        _value(
                          'routeName',
                        ).isEmpty
                            ? 'Not Assigned'
                            : _value(
                                'routeName',
                              ),
                      ),

                    if (_isSalesman)
                      _row(
                        Icons
                            .work_outline_rounded,
                        'Account Status',
                        _profile[
                                    'isActive'] ==
                                false
                            ? 'Inactive'
                            : 'Active',
                      ),

                    if (_isAdmin &&
                        _value(
                          'address',
                        ).isNotEmpty)
                      _row(
                        Icons
                            .location_on_outlined,
                        'Address',
                        _value(
                          'address',
                        ),
                      ),

                    if (_isAdmin &&
                        _value(
                          'city',
                        ).isNotEmpty)
                      _row(
                        Icons
                            .location_city_outlined,
                        'City',
                        _value(
                          'city',
                        ),
                      ),

                    if (_isAdmin &&
                        _value(
                          'state',
                        ).isNotEmpty)
                      _row(
                        Icons
                            .map_outlined,
                        'State',
                        _value(
                          'state',
                        ),
                      ),

                    if (_isAdmin &&
                        _value(
                          'pin',
                        ).isNotEmpty)
                      _row(
                        Icons
                            .pin_drop_outlined,
                        'PIN Code',
                        _value(
                          'pin',
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.edit_outlined,
                    ),
                    title: const Text(
                      'Edit Profile',
                    ),
                    subtitle: const Text(
                      'Update your account details',
                    ),
                    trailing: const Icon(
                      Icons
                          .chevron_right_rounded,
                    ),
                    onTap: _saving
                        ? null
                        : _editProfile,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons
                          .lock_outline_rounded,
                    ),
                    title: const Text(
                      'Change Password',
                    ),
                    subtitle: const Text(
                      'Update your login password',
                    ),
                    trailing: const Icon(
                      Icons
                          .chevron_right_rounded,
                    ),
                    onTap:
                        _changePassword,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons
                          .settings_outlined,
                    ),
                    title: const Text(
                      'Settings',
                    ),
                    trailing: const Icon(
                      Icons
                          .chevron_right_rounded,
                    ),
                    onTap: () =>
                        Navigator.pushNamed(
                      context,
                      '/settings',
                    ),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(
                      Icons
                          .info_outline_rounded,
                    ),
                    title:
                        Text('App version'),
                    subtitle: Text(
                      'Developed by Total Solution',
                    ),
                    trailing: Text(
                      '1.0.0',
                      style: TextStyle(
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
              ),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label,
    String value,
  ) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color:
              AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: const TextStyle(
            color:
                AppColors.textSecondary,
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

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final approved =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'You will return to the sign-in screen.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              false,
            ),
            child:
                const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              true,
            ),
            child:
                const Text('Logout'),
          ),
        ],
      ),
    );

    if (approved != true ||
        !mounted) {
      return;
    }

    UiSession.instance.signOut();

    Navigator.of(context)
        .pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

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
      return 'MP';
    }

    return parts
        .map(
          (part) =>
              part[0].toUpperCase(),
        )
        .join();
  }
}