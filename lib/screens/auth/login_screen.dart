import 'package:flutter/material.dart';

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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      // Preserve the existing UI-only boundary. The selected role is explicit
      // and can later be sent to the real authentication endpoint.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      UiSession.instance.signInForRole(_role, _identifierController.text);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) _message('Unable to sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
                    minHeight: constraints.maxHeight - 52,
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
                                            ? 'Admin ID / Username'
                                            : 'Salesman ID / Mobile / Username',
                                        hintText: _role == UserRole.admin
                                            ? 'Enter admin ID'
                                            : 'Example: SM001',
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
                          const SizedBox(height: 18),
                          const Text(
                            'Secure Distribution Management  •  Version 1.0.0',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
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
