import 'package:flutter/material.dart';

import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UiSession.instance.currentUser;
    return Scaffold(
      appBar: const PremiumAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                    child: Text(
                      _initials(user.name),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  StatusChip(
                    label: user.role.label,
                    color: user.role == UserRole.admin
                        ? AppColors.primary
                        : AppColors.success,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _row(Icons.storefront_outlined, 'Branch', user.branch),
                  if (user.salesmanId != null)
                    _row(Icons.badge_outlined, 'Salesman ID', user.salesmanId!),
                  if (user.route != null)
                    _row(Icons.route_outlined, 'Assigned route', user.route!),
                  if (user.mobile.isNotEmpty)
                    _row(Icons.phone_outlined, 'Mobile', user.mobile),
                  if (user.role == UserRole.salesman)
                    _row(Icons.work_outline_rounded, 'Status', 'On Duty'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('App version'),
                  subtitle: Text('Developed by Total Solution'),
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.textSecondary),
    title: Text(
      label,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Future<void> _logout(BuildContext context) async {
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
    if (approved != true || !context.mounted) return;
    UiSession.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  String _initials(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join();
}
