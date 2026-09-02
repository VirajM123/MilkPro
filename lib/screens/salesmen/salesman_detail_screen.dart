import 'package:flutter/material.dart';

import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/salesman_ui_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../dashboard/dashboard_screen.dart';
import 'manage_access_screen.dart';

class SalesmanDetailScreen extends StatefulWidget {
  const SalesmanDetailScreen({super.key, required this.salesmanId});

  final String salesmanId;

  @override
  State<SalesmanDetailScreen> createState() => _SalesmanDetailScreenState();
}

class _SalesmanDetailScreenState extends State<SalesmanDetailScreen> {
  SalesmanProfile get salesman =>
      SalesmanUiStore.instance.byId(widget.salesmanId);

  Future<void> _manageAccess() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManageAccessScreen(salesmanId: salesman.id),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _edit() async {
    final name = TextEditingController(text: salesman.name);
    final mobile = TextEditingController(text: salesman.mobile);
    final route = TextEditingController(text: salesman.route);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit salesman',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: route,
              decoration: const InputDecoration(
                labelText: 'Assigned route',
                prefixIcon: Icon(Icons.route_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (name.text.trim().isEmpty || route.text.trim().isEmpty) {
                    return;
                  }
                  SalesmanUiStore.instance.updateProfile(
                    salesman.id,
                    name: name.text.trim(),
                    mobile: mobile.text.trim(),
                    route: route.text.trim(),
                  );
                  Navigator.pop(sheetContext);
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    mobile.dispose();
    route.dispose();
    if (mounted) setState(() {});
  }

  void _preview() {
    UiSession.instance.previewSalesman(salesman.id);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(title: 'Salesman Details'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                    child: Text(
                      _initials(salesman.name),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    salesman.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Salesman · ${salesman.id}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 9),
                  StatusChip(
                    label: salesman.isActive ? 'Active' : 'Inactive',
                    color: salesman.isActive
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section('CONTACT', [
            _info(Icons.phone_outlined, 'Mobile', salesman.mobile),
            _info(Icons.route_outlined, 'Assigned route', salesman.route),
          ]),
          const SizedBox(height: 14),
          const AppSectionTitle(title: 'Today'),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: 'Orders',
                  value: '12',
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SummaryCard(
                  label: 'Visits',
                  value: '8 / 15',
                  icon: Icons.pin_drop_outlined,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: 'Sales',
                  value: '₹18,420',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SummaryCard(
                  label: 'Collection',
                  value: '₹12,300',
                  icon: Icons.payments_outlined,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Feature access',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${salesman.permissions.length} / ${AppPermission.values.length} permissions enabled',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _manageAccess,
            ),
          ),
          const SizedBox(height: 14),
          _section('ACCOUNT', [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Active account',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Allow this salesman to use the field workspace',
              ),
              value: salesman.isActive,
              onChanged: (value) => setState(
                () => SalesmanUiStore.instance.setActive(salesman.id, value),
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit salesman'),
              onTap: _edit,
            ),
          ]),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _preview,
            icon: const Icon(Icons.phone_android_rounded),
            label: const Text('Preview Salesman Workspace'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );

  Widget _info(IconData icon, String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
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

  String _initials(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join();
}
