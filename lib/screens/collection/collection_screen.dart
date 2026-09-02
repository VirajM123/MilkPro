import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../allocation/allocation_screen.dart';
import '../routes/routes_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _searchController = TextEditingController();
  String _selectedRoute = 'Route A';
  String _selectedSalesman = 'Mahesh';
  DateTime _selectedDate = DateTime(2025, 8, 20);

  final List<_CustomerCollection> _customers = const [
    _CustomerCollection(
      name: 'Ramesh Patil',
      code: 'CUST001',
      amount: 2450,
      paymentMode: 'Cash',
      status: PaymentStatus.paid,
      avatarColor: Color(0xFFE1F7E9),
      avatarIconColor: Color(0xFF18A85B),
    ),
    _CustomerCollection(
      name: 'Suresh Jadhav',
      code: 'CUST002',
      amount: 1800,
      paymentMode: 'UPI',
      status: PaymentStatus.paid,
      avatarColor: Color(0xFFFFF2D9),
      avatarIconColor: Color(0xFFFFA000),
    ),
    _CustomerCollection(
      name: 'Anil Shinde',
      code: 'CUST003',
      amount: 0,
      paymentMode: 'Pending',
      status: PaymentStatus.due,
      avatarColor: Color(0xFFFFE4E8),
      avatarIconColor: Color(0xFFFF3547),
    ),
    _CustomerCollection(
      name: 'Vijay Kadam',
      code: 'CUST004',
      amount: 3150,
      paymentMode: 'PhonePe',
      status: PaymentStatus.paid,
      avatarColor: Color(0xFFF0E3FF),
      avatarIconColor: Color(0xFF8A31E8),
    ),
    _CustomerCollection(
      name: 'Maruti More',
      code: 'CUST005',
      amount: 2200,
      paymentMode: 'Online',
      status: PaymentStatus.partial,
      avatarColor: Color(0xFFE6F2FF),
      avatarIconColor: Color(0xFF1767D9),
    ),
  ];

  List<_CustomerCollection> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(query) ||
              customer.code.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  double get _totalCollected =>
      _customers.fold(0, (sum, customer) => sum + customer.amount);

  int get _pendingCount => _customers
      .where((customer) => customer.status != PaymentStatus.paid)
      .length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Collection',
        subtitle: 'Collect customer payments',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            const AppSectionTitle(
              title: "Today's Overview",
              subtitle: 'See pending customers and record their payment',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Collected',
                    '₹${_totalCollected.toStringAsFixed(0)}',
                    Icons.payments_outlined,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    'Need Attention',
                    '$_pendingCount customers',
                    Icons.schedule_rounded,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    controller: _searchController,
                    hint: 'Search customer or code',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _showFilters,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(_selectedDate)} • $_selectedRoute • '
              '$_selectedSalesman',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 18),
            AppSectionTitle(
              title: 'Customers',
              subtitle: '${_filteredCustomers.length} customers shown',
            ),
            const SizedBox(height: 10),
            if (_filteredCustomers.isEmpty)
              const AppEmptyState(
                icon: Icons.person_search_outlined,
                title: 'No customers found',
                message: 'Try another customer name or code.',
              )
            else
              ..._filteredCustomers.map(_customerCard),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        onDestinationSelected: _navigationTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Allocation',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            label: 'Collection',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _customerCard(_CustomerCollection customer) {
    final pending = customer.status != PaymentStatus.paid;
    final statusColor = switch (customer.status) {
      PaymentStatus.paid => AppColors.success,
      PaymentStatus.partial => AppColors.warning,
      PaymentStatus.due => AppColors.error,
    };
    final status = switch (customer.status) {
      PaymentStatus.paid => 'Paid',
      PaymentStatus.partial => 'Partly Paid',
      PaymentStatus.due => 'Payment Due',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: customer.avatarColor,
                  foregroundColor: customer.avatarIconColor,
                  child: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${customer.code} • ${customer.paymentMode}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${customer.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 9.5),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: pending
                  ? ElevatedButton.icon(
                      onPressed: () => _showCollectionEntry(customer),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('COLLECT PAYMENT'),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _customerAction(customer),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('VIEW RECEIPT'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _customerAction(_CustomerCollection customer) {
    if (customer.status == PaymentStatus.paid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt opened for ${customer.name}')),
      );
      return;
    }
    _showCollectionEntry(customer);
  }

  void _showCollectionEntry(_CustomerCollection customer) {
    final amountController = TextEditingController();
    String paymentMode = 'Cash';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collect Payment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${customer.name} • ${customer.code}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount Received',
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 11),
              DropdownButtonFormField<String>(
                initialValue: paymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                items:
                    const [
                          'Cash',
                          'UPI',
                          'PhonePe',
                          'Google Pay',
                          'Paytm',
                          'Bank Transfer',
                        ]
                        .map(
                          (mode) =>
                              DropdownMenuItem(value: mode, child: Text(mode)),
                        )
                        .toList(),
                onChanged: (value) =>
                    updateSheet(() => paymentMode = value ?? paymentMode),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Collection saved for ${customer.name}'),
                      ),
                    );
                  },
                  child: const Text('SAVE COLLECTION'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(amountController.dispose);
  }

  void _showFilters() {
    var route = _selectedRoute;
    var salesman = _selectedSalesman;
    var date = _selectedDate;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collection Filter',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2040),
                  );
                  if (picked != null) updateSheet(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(_formatDate(date)),
                ),
              ),
              const SizedBox(height: 11),
              DropdownButtonFormField<String>(
                initialValue: route,
                decoration: const InputDecoration(
                  labelText: 'Route',
                  prefixIcon: Icon(Icons.route_outlined),
                ),
                items: const ['Route A', 'Route B', 'Route C']
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) => updateSheet(() => route = value ?? route),
              ),
              const SizedBox(height: 11),
              DropdownButtonFormField<String>(
                initialValue: salesman,
                decoration: const InputDecoration(
                  labelText: 'Salesman',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const ['Mahesh', 'Ramesh', 'Suresh']
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) =>
                    updateSheet(() => salesman = value ?? salesman),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedRoute = route;
                      _selectedSalesman = salesman;
                    });
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('APPLY FILTER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigationTap(int index) {
    if (index == 0) {
      Navigator.maybePop(context);
    } else if (index == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const RoutesScreen()));
    } else if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AllocationScreen()));
    } else if (index == 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('More options are available from Home.')),
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

enum PaymentStatus { paid, due, partial }

class _CustomerCollection {
  const _CustomerCollection({
    required this.name,
    required this.code,
    required this.amount,
    required this.paymentMode,
    required this.status,
    required this.avatarColor,
    required this.avatarIconColor,
  });

  final String name;
  final String code;
  final double amount;
  final String paymentMode;
  final PaymentStatus status;
  final Color avatarColor;
  final Color avatarIconColor;
}
