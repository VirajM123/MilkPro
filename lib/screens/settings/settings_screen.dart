import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../common/simple_screen_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  bool _loading = true;

  bool _notifications = true;
  bool _dailyReminder = true;

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
  // PROFILE HELPERS
  // ============================================================

  String _value(String key) =>
      (_profile[key] ?? '').toString();

  bool get _isAdmin =>
      _value('role').toLowerCase() ==
      'admin';

  bool get _isSalesman =>
      _value('role').toLowerCase() ==
      'salesman';

  // ============================================================
  // LOAD PROFILE FROM MONGODB
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
              'Unable to load settings.',
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
            Map<String, dynamic>.from(
          rawData,
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final sessionUser =
        UiSession.instance.currentUser;

    return SimpleModuleScaffold(
      title: 'Settings',
      subtitle:
          'Account, business and application preferences',
      children: [
        if (_loading)
          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 60,
            ),
            child: Center(
              child:
                  CircularProgressIndicator(),
            ),
          )
        else ...[
          // ====================================================
          // ACCOUNT
          // ====================================================

          _label('ACCOUNT'),

          SimpleSection(
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  leading:
                      const CircleAvatar(
                    backgroundColor:
                        AppColors
                            .primarySoft,
                    foregroundColor:
                        AppColors.primary,
                    child: Icon(
                      Icons
                          .person_outline_rounded,
                    ),
                  ),
                  title: Text(
                    _value('name').isEmpty
                        ? sessionUser.name
                        : _value('name'),
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    _isAdmin
                        ? 'Admin'
                        : 'Salesman',
                  ),
                  trailing:
                      const Icon(
                    Icons
                        .chevron_right_rounded,
                  ),
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      '/profile',
                    );

                    if (!mounted) return;

                    await _loadProfile();
                  },
                ),

                if (_value(
                  'mobile',
                ).isNotEmpty) ...[
                  const Divider(),
                  _infoTile(
                    Icons.phone_outlined,
                    'Account Mobile',
                    _value('mobile'),
                  ),
                ],

                if (_value(
                  'email',
                ).isNotEmpty) ...[
                  const Divider(),
                  _infoTile(
                    Icons.email_outlined,
                    'Email',
                    _value('email'),
                  ),
                ],

                if (_value(
                  'username',
                ).isNotEmpty) ...[
                  const Divider(),
                  _infoTile(
                    Icons
                        .alternate_email_rounded,
                    'Username',
                    _value('username'),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // BUSINESS
          // READ ONLY
          // ====================================================

          _label('BUSINESS'),

          SimpleSection(
            child: Column(
              children: [
                _infoTile(
                  Icons
                      .storefront_outlined,
                  'Business name',
                  _value(
                    'businessName',
                  ).isEmpty
                      ? 'Not Available'
                      : _value(
                          'businessName',
                        ),
                ),

                // ADMIN BUSINESS ADDRESS
                if (_isAdmin) ...[
                  if (_value(
                    'address',
                  ).isNotEmpty) ...[
                    const Divider(),
                    _infoTile(
                      Icons
                          .location_on_outlined,
                      'Address',
                      _value('address'),
                    ),
                  ],

                  if (_value(
                    'city',
                  ).isNotEmpty) ...[
                    const Divider(),
                    _infoTile(
                      Icons
                          .location_city_outlined,
                      'City',
                      _value('city'),
                    ),
                  ],

                  if (_value(
                    'state',
                  ).isNotEmpty) ...[
                    const Divider(),
                    _infoTile(
                      Icons.map_outlined,
                      'State',
                      _value('state'),
                    ),
                  ],

                  if (_value(
                    'pin',
                  ).isNotEmpty) ...[
                    const Divider(),
                    _infoTile(
                      Icons
                          .pin_drop_outlined,
                      'PIN Code',
                      _value('pin'),
                    ),
                  ],
                ],

                // SALESMAN ASSIGNED ROUTE
                if (_isSalesman) ...[
                  const Divider(),
                  _infoTile(
                    Icons.route_outlined,
                    'Assigned route',
                    _value(
                      'routeName',
                    ).isEmpty
                        ? 'Not Assigned'
                        : _value(
                            'routeName',
                          ),
                  ),

                  const Divider(),

                  _infoTile(
                    Icons
                        .verified_user_outlined,
                    'Account status',
                    _profile[
                                'isActive'] ==
                            false
                        ? 'Inactive'
                        : 'Active',
                  ),
                ],

                const Divider(),

                ListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  leading: Icon(
                    Icons.lock_outline,
                    color: AppColors
                        .textSecondary,
                  ),
                  title: const Text(
                    'Business details are read only',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _isAdmin
                        ? 'Use Profile → Edit Profile to update business details.'
                        : 'Business and route details are controlled by administrator.',
                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          moduleMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // APP SETTINGS
          // ====================================================

          _label('APP'),

          SimpleSection(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding:
                      EdgeInsets.zero,
                  title:
                      const Text(
                    'Notifications',
                    style: TextStyle(
                      color: moduleDark,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'Receive important operational alerts',
                    style: TextStyle(
                      color:
                          moduleMuted,
                      fontSize: 11,
                    ),
                  ),
                  value:
                      _notifications,
                  onChanged: (value) {
                    setState(() {
                      _notifications =
                          value;
                    });
                  },
                ),

                const Divider(),

                SwitchListTile.adaptive(
                  contentPadding:
                      EdgeInsets.zero,
                  title:
                      const Text(
                    'Daily closing reminder',
                    style: TextStyle(
                      color: moduleDark,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'Reminder at the end of the working day',
                    style: TextStyle(
                      color:
                          moduleMuted,
                      fontSize: 11,
                    ),
                  ),
                  value:
                      _dailyReminder,
                  onChanged: (value) {
                    setState(() {
                      _dailyReminder =
                          value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // ABOUT
          // ====================================================

          _label('ABOUT'),

          const SimpleSection(
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  leading: Icon(
                    Icons
                        .info_outline_rounded,
                  ),
                  title: Text(
                    'App version',
                  ),
                  subtitle: Text(
                    'Developed by Total Solution',
                  ),
                  trailing:
                      Text('1.0.0'),
                ),

                Divider(),

                ListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  leading: Icon(
                    Icons
                        .privacy_tip_outlined,
                  ),
                  title:
                      Text('Privacy'),
                  trailing: Icon(
                    Icons
                        .chevron_right_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ====================================================
          // SAVE APP PREFERENCES
          // ====================================================

          ElevatedButton.icon(
            onPressed: () {
              showSavedMessage(
                context,
                'Settings saved successfully.',
              );
            },
            icon: const Icon(
              Icons.save_outlined,
            ),
            label: const Text(
              'Save Settings',
            ),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
            ),
            label: const Text(
              'Logout',
              style: TextStyle(
                color:
                    AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // READ ONLY INFO TILE
  // ============================================================

  Widget _infoTile(
    IconData icon,
    String label,
    String value,
  ) {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,
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
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label(String text) =>
      Padding(
        padding:
            const EdgeInsets.only(
          left: 2,
          bottom: 7,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color:
                AppColors.primary,
            fontSize: 10,
            fontWeight:
                FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      );

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
            error
                ? AppColors.error
                : null,
      ),
    );
  }

  String _cleanError(
    Object error,
  ) {
    final text =
        error.toString();

    if (text.startsWith(
      'Exception: ',
    )) {
      return text.substring(11);
    }

    return text;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final approved =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) =>
              AlertDialog(
        title:
            const Text('Logout?'),
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
}