import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.initialRole = UserRole.admin});

  final UserRole initialRole;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(12, (_) => TextEditingController());

  late UserRole _role;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _loading = false;

  TextEditingController get _name => _controllers[0];
  TextEditingController get _mobile => _controllers[1];
  TextEditingController get _email => _controllers[2];
  TextEditingController get _username => _controllers[3];
  TextEditingController get _password => _controllers[4];
  TextEditingController get _confirm => _controllers[5];
  TextEditingController get _business => _controllers[6];
  TextEditingController get _address => _controllers[7];
  TextEditingController get _city => _controllers[8];
  TextEditingController get _state => _controllers[9];
  TextEditingController get _pin => _controllers[10];
  TextEditingController get _farmId => _controllers[11];

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
Future<void> _register() async {
  FocusScope.of(context).unfocus();

  if (!(_formKey.currentState?.validate() ?? false)) {
    return;
  }

  setState(() => _loading = true);

  try {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'role': _role == UserRole.admin ? 'admin' : 'salesman',

        'farmId': _role == UserRole.salesman
            ? _farmId.text.trim().toUpperCase()
            : null,

        'name': _name.text.trim(),
        'mobile': _mobile.text.trim(),
        'email': _email.text.trim(),
        'username': _username.text.trim(),
        'password': _password.text,

        'businessName':
            _role == UserRole.admin ? _business.text.trim() : '',

        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'pin': _pin.text.trim(),
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (!mounted) return;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final accountData =
          data['data'] as Map<String, dynamic>? ?? {};

      final generatedId = _role == UserRole.admin
          ? accountData['farmId']?.toString() ?? ''
          : accountData['salesmanId']?.toString() ?? '';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              _role == UserRole.admin
                  ? 'Admin Registered Successfully'
                  : 'Salesman Registered Successfully',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['message']?.toString() ??
                      'Account created successfully.',
                ),

                const SizedBox(height: 18),

                Text(
                  _role == UserRole.admin
                      ? 'Your Farm ID'
                      : 'Your Salesman ID',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                SelectableText(
                  generatedId,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (_role == UserRole.admin) ...[
                  const SizedBox(height: 12),

                  Text(
                    'Admin ID: ${accountData['adminId'] ?? ''}',
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Keep this Farm ID safe. Give this Farm ID to your salesman for registration.',
                  ),
                ],

                if (_role == UserRole.salesman) ...[
                  const SizedBox(height: 12),

                  Text(
                    'Farm ID: ${accountData['farmId'] ?? ''}',
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Keep your Salesman ID safe. You can use it for login.',
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.maybePop(context);
    } else {
      _message(
        data['message']?.toString() ??
            'Unable to create account.',
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
    ..showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Create Account',
        subtitle: 'Set up your distribution workspace',
      ),
      bottomNavigationBar: BottomActionBar(
        label: 'CREATE ACCOUNT',
        loading: _loading,
        onPressed: _register,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (_role == UserRole.salesman) ...[
  _section(
    'Farm Details',
    Icons.business_outlined,
    [
      _field(
        _farmId,
        'Farm ID',
        Icons.badge_outlined,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Farm ID is required';
          }

          if (!value.trim().toUpperCase().startsWith('FARM')) {
            return 'Enter a valid Farm ID';
          }

          return null;
        },
      ),
    ],
  ),

  const SizedBox(height: 14),
],
            _section('Personal Details', Icons.person_outline_rounded, [
              _field(_name, 'Full Name', Icons.person_outline_rounded),
              _field(
                _mobile,
                'Mobile Number',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) => value?.length == 10
                    ? null
                    : 'Enter a valid 10-digit mobile number',
              ),
              _field(
                _email,
                'Email',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                required: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)
                      ? null
                      : 'Enter a valid email address';
                },
              ),
            ]),
            const SizedBox(height: 14),
            _section('Account Details', Icons.lock_outline_rounded, [
              _field(_username, 'Username', Icons.badge_outlined),
              _passwordField(
                _password,
                'Password',
                _hidePassword,
                () => setState(() => _hidePassword = !_hidePassword),
                (value) => (value?.length ?? 0) >= 6
                    ? null
                    : 'Use at least 6 characters',
              ),
              _passwordField(
                _confirm,
                'Confirm Password',
                _hideConfirm,
                () => setState(() => _hideConfirm = !_hideConfirm),
                (value) =>
                    value == _password.text ? null : 'Passwords do not match',
              ),
            ]),
           const SizedBox(height: 14),

if (_role == UserRole.admin) ...[
  _section(
    'Business Details',
    Icons.storefront_outlined,
    [
      _field(
        _business,
        'Business / Dairy Name',
        Icons.storefront_outlined,
      ),

      _field(
        _address,
        'Address',
        Icons.location_on_outlined,
        required: false,
        maxLines: 2,
      ),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _field(
              _city,
              'City',
              Icons.location_city_outlined,
              required: false,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _field(
              _state,
              'State',
              Icons.map_outlined,
              required: false,
            ),
          ),
        ],
      ),

      _field(
        _pin,
        'PIN Code',
        Icons.pin_drop_outlined,
        required: false,
        keyboardType: TextInputType.number,
        formatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
      ),
    ],
  ),

  const SizedBox(height: 14),
],
            _section('Role', Icons.manage_accounts_outlined, [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                      value: UserRole.admin,
                      label: Text('Admin'),
                      icon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    ButtonSegment(
                      value: UserRole.salesman,
                      label: Text('Salesman'),
                      icon: Icon(Icons.badge_outlined),
                    ),
                  ],
                  selected: {_role},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _role = value.first),
                ),
              ),
             Text(
  _role == UserRole.admin
      ? 'A unique Farm ID and Admin ID will be generated automatically.'
      : 'Enter your Admin Farm ID. Your Salesman ID will be generated automatically.',
  style: const TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
  ),
),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('LOGIN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> fields) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < fields.length; index++) ...[
            fields[index],
            if (index != fields.length - 1) const SizedBox(height: 11),
          ],
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    bool required = true,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: formatters,
    maxLines: maxLines,
    textInputAction: maxLines > 1
        ? TextInputAction.newline
        : TextInputAction.next,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator:
        validator ??
        (required
            ? (value) => value == null || value.trim().isEmpty
                  ? '$label is required'
                  : null
            : null),
  );

  Widget _passwordField(
    TextEditingController controller,
    String label,
    bool obscure,
    VoidCallback toggle,
    String? Function(String?) validator,
  ) => TextFormField(
    controller: controller,
    obscureText: obscure,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    ),
    validator: validator,
  );
}
