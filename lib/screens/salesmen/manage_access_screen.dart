import 'package:flutter/material.dart';

import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/salesman_ui_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class ManageAccessScreen extends StatefulWidget {
  const ManageAccessScreen({super.key, required this.salesmanId});

  final String salesmanId;

  @override
  State<ManageAccessScreen> createState() => _ManageAccessScreenState();
}

class _ManageAccessScreenState extends State<ManageAccessScreen> {
  late Set<AppPermission> _selected;
  String _query = '';

  SalesmanProfile get _salesman =>
      SalesmanUiStore.instance.byId(widget.salesmanId);

  @override
  void initState() {
    super.initState();
    _selected = Set<AppPermission>.from(_salesman.permissions);
  }

  void _save() {
    SalesmanUiStore.instance.updatePermissions(widget.salesmanId, _selected);
    UiSession.instance.refreshSalesmanPermissions(widget.salesmanId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature access saved for local UI testing.'),
      ),
    );
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Manage Access',
        subtitle: '${_salesman.name} · ${_salesman.id}',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          _profileCard(),
          const SizedBox(height: 16),
          const AppSectionTitle(
            title: 'Feature Access',
            subtitle: 'Choose the tools available in the salesman workspace.',
          ),
          const SizedBox(height: 12),
          AppSearchField(
            hint: 'Search permissions',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _selected = AppPermission.values.toSet()),
                  child: const Text('Enable All'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(_selected.clear),
                  child: const Text('Disable All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final group in permissionGroups)
            if (query.isEmpty ||
                group.title.toLowerCase().contains(query) ||
                group.items.any(
                  (item) => item.label.toLowerCase().contains(query),
                ))
              _permissionGroup(group, query),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        label: 'SAVE ACCESS',
        onPressed: _save,
      ),
    );
  }

  Widget _profileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              child: Text(
                _initials(_salesman.name),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _salesman.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_salesman.id} · Salesman',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            StatusChip(
              label: '${_selected.length} enabled',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionGroup(PermissionGroup group, String query) {
    final items = query.isEmpty
        ? group.items
        : group.items
              .where(
                (item) =>
                    group.title.toLowerCase().contains(query) ||
                    item.label.toLowerCase().contains(query),
              )
              .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 4),
              for (final item in items)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _selected.contains(item.permission),
                  onChanged: (enabled) => setState(() {
                    enabled
                        ? _selected.add(item.permission)
                        : _selected.remove(item.permission);
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join();
}
