import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../../models/report_model.dart';
import '../../providers/report_demo_provider.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _query = '';

  static const _groups = <_ReportGroup>[
    _ReportGroup(
      title: 'Stock Reports',
      icon: Icons.inventory_2_outlined,
      color: AppColors.primary,
      reports: [
        _ReportItem('Current Stock', 'Available quantity for every product'),
        _ReportItem('Low Stock', 'Products that need to be purchased soon'),
        _ReportItem(
          'Stock Movement',
          'Opening, inward, sales, returns and closing',
        ),
        _ReportItem(
          'Product-wise Stock',
          'Stock grouped by product and variant',
        ),
      ],
    ),
    _ReportGroup(
      title: 'Sales & Purchase Trends',
      icon: Icons.trending_up_rounded,
      color: AppColors.purple,
      reports: [
        _ReportItem(
          'Sales Trend',
          'Daily, weekly and monthly sales comparison',
        ),
        _ReportItem(
          'Purchase Trend',
          'Daily, weekly and monthly purchase comparison',
        ),
        _ReportItem(
          'Sales vs Purchase',
          'Compare sale and purchase value for a period',
        ),
        _ReportItem(
          'Product Trend',
          'See which products are growing or declining',
        ),
      ],
    ),
    _ReportGroup(
      title: 'Outstanding Reports',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.warning,
      reports: [
        _ReportItem(
          'Salesman-wise Outstanding',
          'Pending amount handled by each salesman',
        ),
        _ReportItem(
          'Customer / Outlet-wise Outstanding',
          'Pending amount for every customer or outlet',
        ),
        _ReportItem(
          'Route-wise Outstanding',
          'Pending amount grouped by route',
        ),
        _ReportItem(
          'Outstanding Ageing',
          'Current, 7-day, 15-day and 30-day pending amounts',
        ),
      ],
    ),
    _ReportGroup(
      title: 'Sales Reports',
      icon: Icons.receipt_long_outlined,
      color: AppColors.success,
      reports: [
        _ReportItem(
          'Salesman-wise Sales',
          'Sales quantity and value for each salesman',
        ),
        _ReportItem(
          'Customer-wise Sales',
          'Sales history for each customer or outlet',
        ),
        _ReportItem('Route-wise Sales', 'Sales grouped by delivery route'),
        _ReportItem(
          'Product-wise Sales',
          'Quantity and value sold for each product',
        ),
        _ReportItem(
          'Date-wise Sales',
          'Day-wise sale register and payment mode',
        ),
      ],
    ),
    _ReportGroup(
      title: 'Purchase Reports',
      icon: Icons.shopping_bag_outlined,
      color: AppColors.info,
      reports: [
        _ReportItem(
          'Purchase Register',
          'All purchase invoices for a selected period',
        ),
        _ReportItem('Supplier-wise Purchase', 'Purchases grouped by supplier'),
        _ReportItem(
          'Product-wise Purchase',
          'Purchased quantity and value by product',
        ),
        _ReportItem('Purchase Payment Due', 'Pending supplier payment report'),
      ],
    ),
    _ReportGroup(
      title: 'Operations Reports',
      icon: Icons.route_outlined,
      color: AppColors.error,
      reports: [
        _ReportItem(
          'Collection Report',
          'Cash, UPI, bank and credit collections',
        ),
        _ReportItem(
          'Allocation Report',
          'Product allocation by route and salesman',
        ),
        _ReportItem('Return Report', 'Good, damaged and pending returns'),
        _ReportItem(
          'Expense Report',
          'Distribution expenses by category and mode',
        ),
      ],
    ),
  ];

  List<_ReportGroup> get _visibleGroups {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _groups;
    return _groups
        .map(
          (group) => group.copyWith(
            reports: group.reports
                .where(
                  (report) =>
                      report.title.toLowerCase().contains(query) ||
                      report.description.toLowerCase().contains(query),
                )
                .toList(growable: false),
          ),
        )
        .where((group) => group.reports.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Reports',
        subtitle: 'Choose the report you want to view',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: AppSearchField(
                hint: 'Search reports',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: _visibleGroups.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No report found',
                      message: 'Try searching with another report name.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                      itemCount: _visibleGroups.length,
                      itemBuilder: (context, index) =>
                          _groupCard(_visibleGroups[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupCard(_ReportGroup group) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: group.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(group.icon, color: group.color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${group.reports.length}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final report in group.reports)
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 9,
              title: Text(
                report.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                report.description,
                style: const TextStyle(fontSize: 10.5),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openReport(group, report),
            ),
        ],
      ),
    ),
  );

  void _openReport(_ReportGroup group, _ReportItem report) {
    DateTime from = DateTime.now().subtract(const Duration(days: 30));
    DateTime to = DateTime.now();
    final sourceReport = ReportDemoProvider.forReport(
      report.title,
      report.description,
    );
    final reportFilter = _filterFor(sourceReport);
    String selectedFilter = _allFilterValue;
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .82,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(group.icon, color: group.color),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          report.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    report.description,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _dateButton('From', from, () async {
                          final value = await _pickReportDate(from);
                          if (value != null) updateSheet(() => from = value);
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dateButton('To', to, () async {
                          final value = await _pickReportDate(to);
                          if (value != null) updateSheet(() => to = value);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('report-filter-${report.title}'),
                    initialValue: selectedFilter,
                    decoration: InputDecoration(
                      labelText: reportFilter.label,
                      prefixIcon: Icon(reportFilter.icon),
                      helperText:
                          'Choose a ${reportFilter.label.toLowerCase()} or view all records',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: _allFilterValue,
                        child: Text('All ${reportFilter.label.toLowerCase()}'),
                      ),
                      ...reportFilter.options.map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (value) => updateSheet(
                      () => selectedFilter = value ?? _allFilterValue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (to.isBefore(from)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'The To date must be on or after the From date.',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        final filteredRows = selectedFilter == _allFilterValue
                            ? sourceReport.rows
                            : sourceReport.rows
                                  .where(
                                    (row) =>
                                        row[reportFilter.columnIndex]
                                            .toString() ==
                                        selectedFilter,
                                  )
                                  .toList(growable: false);
                        Navigator.pop(sheetContext);
                        Navigator.of(this.context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReportDetailScreen(
                              report: sourceReport.copyWith(rows: filteredRows),
                              from: from,
                              to: to,
                              icon: group.icon,
                              color: group.color,
                              filterLabel: reportFilter.label,
                              filterValue: selectedFilter == _allFilterValue
                                  ? 'All'
                                  : selectedFilter,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('VIEW REPORT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateButton(String label, DateTime date, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_month_outlined),
          ),
          child: Text(
            '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/${date.year}',
          ),
        ),
      );

  Future<DateTime?> _pickReportDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2040),
  );

  static const _allFilterValue = '__all__';

  _ReportFilter _filterFor(ReportData report) {
    final title = report.title.toLowerCase();
    final preferredHeaders = <String>[
      if (title.contains('salesman')) 'salesman',
      if (title.contains('customer') || title.contains('outlet')) 'customer',
      if (title.contains('route')) 'route',
      if (title.contains('product') || title.contains('stock')) 'product',
      if (title.contains('supplier') || title.contains('purchase')) 'supplier',
      if (title.contains('expense')) 'category',
      if (title.contains('collection')) 'mode',
      if (title.contains('allocation') || title.contains('return')) 'salesman',
      if (title.contains('ageing')) 'age bucket',
      if (title.contains('trend') || title.contains('sales vs')) 'period',
      if (title.contains('date-wise')) 'customer',
      'status',
      'category',
      'payment',
      'date',
    ];
    var columnIndex = -1;
    for (final preferred in preferredHeaders) {
      columnIndex = report.columns.indexWhere(
        (header) => header.toLowerCase() == preferred,
      );
      if (columnIndex >= 0) break;
    }
    if (columnIndex < 0) columnIndex = 0;

    final label = report.columns[columnIndex];
    final options =
        report.rows
            .map((row) => row[columnIndex].toString())
            .toSet()
            .toList(growable: false)
          ..sort();
    return _ReportFilter(
      label: label,
      columnIndex: columnIndex,
      options: options,
      icon: _filterIcon(label),
    );
  }

  IconData _filterIcon(String label) {
    final value = label.toLowerCase();
    if (value.contains('salesman')) return Icons.badge_outlined;
    if (value.contains('customer')) return Icons.storefront_outlined;
    if (value.contains('route')) return Icons.route_outlined;
    if (value.contains('product')) return Icons.inventory_2_outlined;
    if (value.contains('supplier')) return Icons.local_shipping_outlined;
    if (value.contains('date') || value.contains('period')) {
      return Icons.event_outlined;
    }
    return Icons.filter_alt_outlined;
  }
}

class _ReportFilter {
  const _ReportFilter({
    required this.label,
    required this.columnIndex,
    required this.options,
    required this.icon,
  });

  final String label;
  final int columnIndex;
  final List<String> options;
  final IconData icon;
}

class _ReportGroup {
  const _ReportGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.reports,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_ReportItem> reports;

  _ReportGroup copyWith({List<_ReportItem>? reports}) => _ReportGroup(
    title: title,
    icon: icon,
    color: color,
    reports: reports ?? this.reports,
  );
}

class _ReportItem {
  const _ReportItem(this.title, this.description);

  final String title;
  final String description;
}
