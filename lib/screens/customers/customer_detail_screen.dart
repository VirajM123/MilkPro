import 'package:flutter/material.dart';

import '../../models/customer_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: PremiumAppBar(
          title: customer.name,
          subtitle: '${customer.route} • ${customer.mobile}',
        ),
        body: Column(
          children: [
            Material(
              color: AppColors.surface,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Payments'),
                  Tab(text: 'Ledger'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _overview(context),
                  const _CustomerEmptyTab(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No orders available',
                    message: 'Order history will appear when it is connected.',
                  ),
                  const _CustomerEmptyTab(
                    icon: Icons.payments_outlined,
                    title: 'No payment history available',
                    message: 'Recorded customer payments will appear here.',
                  ),
                  const _CustomerEmptyTab(
                    icon: Icons.menu_book_outlined,
                    title: 'Ledger integration pending',
                    message:
                        'No customer-specific ledger entries are stored yet.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overview(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primary,
                child: Text(
                  customer.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    StatusChip(
                      label: customer.isActive ? 'Active' : 'Inactive',
                      color: customer.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${customer.balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Outstanding',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const AppSectionTitle(title: 'Customer Information'),
      const SizedBox(height: 10),
      Card(
        child: Column(
          children: [
            _info(Icons.phone_outlined, 'Mobile', customer.mobile),
            const Divider(),
            _info(Icons.route_outlined, 'Route', customer.route),
            const Divider(),
            _info(
              Icons.account_balance_wallet_outlined,
              'Opening / current balance',
              '₹${customer.balance.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _message(context, 'Calling ${customer.mobile}'),
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Call'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _message(
                context,
                'Collection entry can be connected to this customer.',
              ),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Collection'),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _info(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
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

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CustomerEmptyTab extends StatelessWidget {
  const _CustomerEmptyTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: AppEmptyState(icon: icon, title: title, message: message),
  );
}
