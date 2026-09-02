import 'package:flutter/material.dart';

import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../common/simple_screen_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _businessController = TextEditingController(text: 'Milk Distribution');
  final _phoneController = TextEditingController(text: '9876543210');
  final _addressController = TextEditingController(text: 'Kothrud, Pune');
  bool _notifications = true;
  bool _dailyReminder = true;

  @override
  void dispose() {
    _businessController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = UiSession.instance.currentUser;
    return SimpleModuleScaffold(
      title: 'Settings',
      subtitle: 'Account, business and application preferences',
      children: [
        _label('ACCOUNT'),
        SimpleSection(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.person_outline_rounded),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(user.role.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _label('BUSINESS'),
        SimpleSection(
          child: Column(
            children: [
              TextField(
                controller: _businessController,
                decoration: simpleInput(
                  'Business name',
                  Icons.storefront_outlined,
                ),
              ),
              const SizedBox(height: 11),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: simpleInput('Phone number', Icons.phone_outlined),
              ),
              const SizedBox(height: 11),
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: simpleInput(
                  'Branch address',
                  Icons.location_on_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _label('APP'),
        SimpleSection(
          child: Column(
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Notifications',
                  style: TextStyle(
                    color: moduleDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Receive important operational alerts',
                  style: TextStyle(color: moduleMuted, fontSize: 11),
                ),
                value: _notifications,
                onChanged: (value) => setState(() => _notifications = value),
              ),
              const Divider(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Daily closing reminder',
                  style: TextStyle(
                    color: moduleDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Reminder at the end of the working day',
                  style: TextStyle(color: moduleMuted, fontSize: 11),
                ),
                value: _dailyReminder,
                onChanged: (value) => setState(() => _dailyReminder = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _label('ABOUT'),
        const SimpleSection(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline_rounded),
                title: Text('App version'),
                subtitle: Text('Developed by Total Solution'),
                trailing: Text('1.0.0'),
              ),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Privacy'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: () =>
              showSavedMessage(context, 'Settings saved successfully.'),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Settings'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label: const Text('Logout', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
      ),
    ),
  );

  Future<void> _logout() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will return to the sign-in screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    UiSession.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
