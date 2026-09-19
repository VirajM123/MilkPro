import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../models/collection_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../allocation/allocation_screen.dart';
import '../routes/routes_screen.dart';

class _SelectableBillItem {
  _SelectableBillItem({
    required this.sourceType,
    required this.referenceId,
    required this.referenceNo,
    required this.date,
    required this.originalAmount,
    required this.paidSoFar,
    required this.currentDue,
    required this.customerId,
    required this.customerName,
  }) : controller = TextEditingController();

  final String sourceType;
  final String referenceId;
  final String referenceNo;
  final DateTime? date;
  final double originalAmount;
  final double paidSoFar;
  final double currentDue;
  final String customerId;
  final String customerName;

  bool isSelected = false;
  int selectionOrder = 0;
  final TextEditingController controller;

  double get appliedAmount => double.tryParse(controller.text.trim()) ?? 0.0;
  double get dueAfter => math.max(0.0, currentDue - appliedAmount);
  bool get isOverApplied => appliedAmount > currentDue + 0.001;

  void dispose() {
    controller.dispose();
  }
}

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _searchController = TextEditingController();
  String _selectedRoute = 'All Routes';
  String _selectedSalesman = 'All Salesmen';

  DateTime _selectedDate = DateTime.now();

  final List<CustomerCollectionModel> _customers = [];
  final List<Map<String, dynamic>> _collections = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String _loadError = '';

  List<CustomerCollectionModel> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();

    return _customers.where((customer) {
      final mobileLower = customer.mobile.toLowerCase();
      final matchesSearch = query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          customer.code.toLowerCase().contains(query) ||
          mobileLower.contains(query);

      final matchesRoute =
          _selectedRoute == 'All Routes' || customer.route == _selectedRoute;

      final matchesSalesman = _selectedSalesman == 'All Salesmen' ||
          customer.salesmanName == _selectedSalesman;

      return matchesSearch && matchesRoute && matchesSalesman;
    }).toList(growable: false);
  }

  double get _totalCollected {
    double total = 0;
    for (final collection in _collections) {
      final status = (collection['status'] ?? '').toString().toUpperCase();
      if (status != 'POSTED') {
        continue;
      }
      total += _asDouble(collection['amount']);
    }
    return total;
  }

  int get _pendingCount => _customers
      .where((customer) => customer.collectibleOutstanding > 0.001)
      .length;

  List<String> get _routeOptions {
    final routes = _customers
        .map((customer) => customer.route.trim())
        .where((route) => route.isNotEmpty)
        .toSet()
        .toList();
    routes.sort();
    return ['All Routes', ...routes];
  }

  List<String> get _salesmanOptions {
    final salesmen = _customers
        .map((customer) => customer.salesmanName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    salesmen.sort();
    return ['All Salesmen', ...salesmen];
  }

  @override
  void initState() {
    super.initState();
    _loadCollectionData();
  }

  Future<void> _loadCollectionData() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = '';
    });

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (ApiConfig.token.isNotEmpty)
          'Authorization': 'Bearer ${ApiConfig.token}',
      };

      // ==========================================
      // OUTSTANDING CUSTOMERS (Single source of truth)
      // ==========================================
      final outstandingResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/collections/outstanding'),
        headers: headers,
      );

      final outstandingDecoded = jsonDecode(outstandingResponse.body);

      if (outstandingResponse.statusCode < 200 ||
          outstandingResponse.statusCode >= 300 ||
          outstandingDecoded is! Map ||
          outstandingDecoded['success'] != true) {
        throw Exception(
          outstandingDecoded is Map
              ? (outstandingDecoded['message'] ?? 'Unable to load outstanding.')
                  .toString()
              : 'Unable to load outstanding.',
        );
      }

      // ==========================================
      // COLLECTION RECEIPTS FOR SELECTED DATE
      // ==========================================
      final historyResponse = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/collections?date=${_apiDate(_selectedDate)}',
        ),
        headers: headers,
      );

      final historyDecoded = jsonDecode(historyResponse.body);

      if (historyResponse.statusCode < 200 ||
          historyResponse.statusCode >= 300 ||
          historyDecoded is! Map ||
          historyDecoded['success'] != true) {
        throw Exception(
          historyDecoded is Map
              ? (historyDecoded['message'] ?? 'Unable to load collections.')
                  .toString()
              : 'Unable to load collections.',
        );
      }

      // ==========================================
      // PARSE CUSTOMERS & RECEIPTS VIA MODEL
      // ==========================================
      final List<CustomerCollectionModel> loadedCustomers = [];
      final rawOutstanding = outstandingDecoded['data'];

      if (rawOutstanding is List) {
        for (final raw in rawOutstanding) {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          loadedCustomers.add(CustomerCollectionModel.fromJson(item));
        }
      }

      final List<Map<String, dynamic>> loadedCollections = [];
      final rawHistory = historyDecoded['data'];
      if (rawHistory is List) {
        for (final raw in rawHistory) {
          if (raw is Map) {
            loadedCollections.add(Map<String, dynamic>.from(raw));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _customers
          ..clear()
          ..addAll(loadedCustomers);
        _collections
          ..clear()
          ..addAll(loadedCollections);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

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
              '${_formatDate(_selectedDate)} • $_selectedRoute • $_selectedSalesman',
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError.isNotEmpty)
              AppEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Unable to load collection',
                message: _loadError,
              )
            else if (_filteredCustomers.isEmpty)
              const AppEmptyState(
                icon: Icons.person_search_outlined,
                title: 'No outstanding found',
                message: 'No pending customer collection found.',
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

  // ==========================================================================
  // CUSTOMER CARD
  // ==========================================================================
  Widget _customerCard(CustomerCollectionModel customer) {
    final status = customer.status.toUpperCase();
    final isAdvance = customer.isAdvance || status == 'ADVANCE';
    final isSettled = customer.isSettled || status == 'PAID';

    final Color statusColor;
    final String displayStatus;

    if (isAdvance) {
      statusColor = const Color(0xFF2563EB); // Blue
      displayStatus = 'ADVANCE';
    } else if (isSettled) {
      statusColor = AppColors.success; // Green
      displayStatus = 'SETTLED';
    } else if (status == 'PARTIAL') {
      statusColor = AppColors.warning; // Amber
      displayStatus = 'PARTIAL';
    } else {
      statusColor = AppColors.error; // Red
      displayStatus = 'DUE';
    }

    final double displayAmount = isAdvance
        ? (customer.advanceBalance > 0.001
            ? customer.advanceBalance
            : customer.netOutstanding.abs())
        : customer.collectibleOutstanding;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CUSTOMER HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: customer.avatarColor,
                  foregroundColor: customer.avatarIconColor,
                  child: const Icon(Icons.storefront_outlined),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          customer.code,
                          if (customer.route.trim().isNotEmpty) customer.route,
                          if (customer.salesmanName.trim().isNotEmpty)
                            customer.salesmanName,
                        ].join(' • '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${displayAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 13),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // CUSTOMER ACCOUNT BREAKDOWN
            _billAmountRow('Paid at Billing', customer.totalPaidAtBilling),
            _billAmountRow('Later Collections', customer.totalLaterCollections),
            _billAmountRow(
              'Total Received',
              customer.totalReceived,
              bold: true,
              valueColor: const Color(0xFF059669),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Divider(height: 1),
            ),
            _billAmountRow('Sales Outstanding', customer.grossBillOutstanding),
            _billAmountRow(
              'Manual / Opening Outstanding',
              customer.grossManualOutstanding,
            ),
            if (customer.advanceBalance > 0.001)
              _billAmountRow(
                'Available Advance',
                customer.advanceBalance,
                valueColor: const Color(0xFF2563EB),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1),
            ),
            _billAmountRow(
              isAdvance ? 'Net Advance Position' : 'Net Outstanding',
              isAdvance
                  ? customer.advanceBalance
                  : customer.collectibleOutstanding,
              bold: true,
              valueColor: isAdvance
                  ? const Color(0xFF2563EB)
                  : (customer.collectibleOutstanding > 0.001
                      ? AppColors.error
                      : AppColors.success),
            ),

            const SizedBox(height: 12),

            // ACTION BUTTONS
            Row(
              children: [
                if (customer.collectibleOutstanding > 0.001 &&
                    UiSession.instance.can(AppPermission.collectionCreate))
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCollectionEntry(customer),
                      icon: const Icon(Icons.payments_outlined, size: 17),
                      label: Text(
                        'COLLECT • ₹${customer.collectibleOutstanding.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (customer.collectibleOutstanding > 0.001 &&
                    customer.receiptHistory.isNotEmpty)
                  const SizedBox(width: 8),
                if (customer.receiptHistory.isNotEmpty)
                  Expanded(
                    flex: customer.collectibleOutstanding > 0.001 ? 2 : 1,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReceiptHistorySheet(customer),
                      icon: const Icon(Icons.receipt_long_outlined, size: 17),
                      label: Text(
                        customer.collectibleOutstanding <= 0.001
                            ? 'VIEW RECEIPTS (${customer.receiptHistory.length})'
                            : 'RECEIPTS (${customer.receiptHistory.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // MANUAL / OPENING OUTSTANDINGS
            if (customer.manualOutstandings.isNotEmpty) ...[
              const Text(
                'MANUAL / OPENING OUTSTANDING',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...customer.manualOutstandings.map(_manualOutstandingCard),
              const SizedBox(height: 4),
            ],

            // SALES BILLS
            if (customer.bills.isNotEmpty) ...[
              const Text(
                'SALES BILLS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...customer.bills.map((bill) => _collectionBillCard(customer, bill)),
            ],

            if (customer.bills.isEmpty && customer.manualOutstandings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No outstanding source details available.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // MANUAL OUTSTANDING CARD
  // ==========================================================================
  Widget _manualOutstandingCard(ManualOutstandingModel item) {
    final isPaid = item.isPaid;
    final isPartial = item.isPartial;

    final statusText = isPaid
        ? 'PAID'
        : isPartial
            ? 'PARTIAL'
            : 'OUTSTANDING';

    final statusColor = isPaid
        ? AppColors.success
        : isPartial
            ? AppColors.warning
            : AppColors.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.adjustmentNo.trim().isNotEmpty
                          ? item.adjustmentNo
                          : 'Manual Outstanding',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (item.adjustmentDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(item.adjustmentDate!.toLocal()),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _billAmountRow('Original Amount', item.amount, bold: true),
          if (item.collectionApplied > 0.001)
            _billAmountRow('Collection Applied', item.collectionApplied),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          _billAmountRow(
            'Outstanding',
            item.outstandingAmount,
            bold: true,
            valueColor: isPaid ? AppColors.success : AppColors.error,
          ),
          if (item.remarks.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.remarks,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // COLLECTION BILL CARD
  // ==========================================================================
  Widget _collectionBillCard(
    CustomerCollectionModel customer,
    CollectionBillModel bill,
  ) {
    final isPaid = bill.isPaid;
    final isPartial = bill.isPartial;

    final statusText = isPaid
        ? 'PAID'
        : isPartial
            ? 'PARTIAL'
            : 'DUE';

    final statusColor = isPaid
        ? AppColors.success
        : isPartial
            ? AppColors.warning
            : AppColors.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.saleNo.isEmpty ? 'Sale Bill' : bill.saleNo,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (bill.saleDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(bill.saleDate!.toLocal()),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _billAmountRow('Bill Amount', bill.billAmount, bold: true),
          if (bill.paidAtBilling > 0.001) ...[
            const SizedBox(height: 4),
            _billAmountRow('Paid at Billing', bill.paidAtBilling),
          ],
          if (bill.advanceUsed > 0.001) ...[
            const SizedBox(height: 4),
            _billAmountRow(
              'Advance Used',
              bill.advanceUsed,
              valueColor: const Color(0xFF2563EB),
            ),
          ],
          if (bill.collectionApplied > 0.001) ...[
            const SizedBox(height: 4),
            _billAmountRow('Later Collection Applied', bill.collectionApplied),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          _billAmountRow(
            'Total Applied to Bill',
            bill.totalAppliedToBill,
            bold: true,
          ),
          _billAmountRow(
            'Remaining Outstanding',
            bill.remainingOutstanding,
            bold: true,
            valueColor: isPaid ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showBillDetails(customer, bill),
              icon: const Icon(Icons.visibility_outlined, size: 17),
              label: const Text('BILL DETAILS'),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // COLLECT PAYMENT BOTTOM SHEET (Bill-Wise Dual Mode: MANUAL vs FIFO)
  // ==========================================================================
  void _showCollectionEntry(CustomerCollectionModel customer) {
    if (!UiSession.instance.can(AppPermission.collectionCreate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to record collections.'),
        ),
      );
      return;
    }

    if (customer.collectibleOutstanding <= 0.001) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            customer.advanceBalance > 0.001
                ? 'Customer has advance. There is no collectible outstanding.'
                : 'Customer has no outstanding to collect.',
          ),
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final remarksController = TextEditingController();
    String paymentMode = 'Cash';
    DateTime collectionDate = DateTime.now();

    final List<_SelectableBillItem> openItems = [];

    // Manual outstandings
    for (final manual in customer.manualOutstandings) {
      if (manual.currentDue > 0.001) {
        openItems.add(
          _SelectableBillItem(
            sourceType: 'MANUAL_OUTSTANDING',
            referenceId: manual.adjustmentId,
            referenceNo: manual.adjustmentNo,
            date: manual.adjustmentDate,
            originalAmount: manual.amount,
            paidSoFar: manual.collectionApplied,
            currentDue: manual.currentDue,
            customerId: manual.customerId.isNotEmpty
                ? manual.customerId
                : customer.customerId,
            customerName: manual.customerName.isNotEmpty
                ? manual.customerName
                : customer.name,
          ),
        );
      }
    }

    // Bills
    for (final bill in customer.bills) {
      if (bill.remainingOutstanding > 0.001) {
        openItems.add(
          _SelectableBillItem(
            sourceType: 'SALE',
            referenceId: bill.saleId,
            referenceNo: bill.saleNo,
            date: bill.saleDate,
            originalAmount: bill.billAmount,
            paidSoFar: bill.totalAppliedToBill,
            currentDue: bill.remainingOutstanding,
            customerId: bill.customerId.isNotEmpty
                ? bill.customerId
                : customer.customerId,
            customerName: bill.customerName.isNotEmpty
                ? bill.customerName
                : customer.name,
          ),
        );
      }
    }

    String allocationMode = openItems.isNotEmpty ? 'MANUAL' : 'FIFO';

    // Auto-select first bill if available
    if (openItems.isNotEmpty) {
      final first = openItems.first;
      first.isSelected = true;
      first.selectionOrder = 1;
      first.controller.text = first.currentDue.toStringAsFixed(2);
      amountController.text = first.currentDue.toStringAsFixed(2);
    } else {
      amountController.text =
          customer.collectibleOutstanding.toStringAsFixed(2);
    }

    String? clientRequestId;
    String generateNewRequestId() {
      final randomPart =
          math.Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
      return 'REQ-${DateTime.now().millisecondsSinceEpoch}-$randomPart-${customer.customerId}';
    }

    void reindexSelected() {
      final selected = openItems
          .where((_SelectableBillItem i) => i.isSelected)
          .toList()
        ..sort((a, b) => a.selectionOrder.compareTo(b.selectionOrder));
      for (int i = 0; i < selected.length; i++) {
        selected[i].selectionOrder = i + 1;
      }
    }

    void toggleItem(_SelectableBillItem item, StateSetter updateSheet) {
      if (item.isSelected) {
        item.isSelected = false;
        item.selectionOrder = 0;
        item.controller.text = '';
        reindexSelected();
      } else {
        item.isSelected = true;
        final maxOrder = openItems
            .where((_SelectableBillItem i) => i.isSelected)
            .fold(0, (max, i) => math.max(max, i.selectionOrder));
        item.selectionOrder = maxOrder + 1;
        item.controller.text = item.currentDue.toStringAsFixed(2);
      }
      clientRequestId = null;
      updateSheet(() {});
    }

    void selectAll(StateSetter updateSheet) {
      for (int i = 0; i < openItems.length; i++) {
        openItems[i].isSelected = true;
        openItems[i].selectionOrder = i + 1;
        openItems[i].controller.text =
            openItems[i].currentDue.toStringAsFixed(2);
      }
      final totalDue =
          openItems.fold<double>(0.0, (sum, i) => sum + i.currentDue);
      amountController.text = totalDue.toStringAsFixed(2);
      clientRequestId = null;
      updateSheet(() {});
    }

    void clearAll(StateSetter updateSheet) {
      for (final item in openItems) {
        item.isSelected = false;
        item.selectionOrder = 0;
        item.controller.text = '';
      }
      amountController.text = '';
      clientRequestId = null;
      updateSheet(() {});
    }

    void autoFillSelected(double targetAmount, StateSetter updateSheet) {
      double remaining = targetAmount;
      final selected = openItems
          .where((_SelectableBillItem i) => i.isSelected)
          .toList()
        ..sort((a, b) => a.selectionOrder.compareTo(b.selectionOrder));
      for (final item in selected) {
        final toApply =
            math.min(item.currentDue, math.max(0.0, remaining));
        item.controller.text = toApply.toStringAsFixed(2);
        remaining = math.max(0.0, remaining - toApply);
      }
      clientRequestId = null;
      updateSheet(() {});
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (dialogContext, updateSheet) {
          final maxCollectable = customer.collectibleOutstanding;
          final enteredAmount =
              double.tryParse(amountController.text.trim()) ?? 0.0;
          final isOver = enteredAmount > maxCollectable + 0.001;

          final List<_SelectableBillItem> selectedItems = openItems
              .where((_SelectableBillItem i) => i.isSelected)
              .toList()
            ..sort((a, b) => a.selectionOrder.compareTo(b.selectionOrder));
          final totalAllocated = selectedItems.fold<double>(
            0.0,
            (sum, i) => sum + i.appliedAmount,
          );
          final unallocated = enteredAmount - totalAllocated;
          final hasAllocationError = selectedItems.any(
            (_SelectableBillItem i) => i.appliedAmount <= 0.001 || i.isOverApplied,
          );
          final isManualValid = allocationMode == 'MANUAL' &&
              selectedItems.isNotEmpty &&
              !hasAllocationError &&
              (enteredAmount - totalAllocated).abs() <= 0.001 &&
              enteredAmount > 0.001 &&
              !isOver;

          final isFifoValid = allocationMode == 'FIFO' &&
              enteredAmount > 0.001 &&
              !isOver;

          final canSubmit = !_isSaving && (isManualValid || isFifoValid);

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.90,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.viewInsetsOf(dialogContext).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Collect Payment',
                              style: Theme.of(dialogContext).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${customer.name} • ${customer.code}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Segmented pill mode selector
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: openItems.isEmpty
                                ? null
                                : () => updateSheet(() => allocationMode = 'MANUAL'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: allocationMode == 'MANUAL'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.checklist_rounded,
                                      size: 16,
                                      color: allocationMode == 'MANUAL'
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Select Bills',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: allocationMode == 'MANUAL'
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => updateSheet(() => allocationMode = 'FIFO'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: allocationMode == 'FIFO'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                      color: allocationMode == 'FIFO'
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Auto FIFO',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: allocationMode == 'FIFO'
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // SCROLLABLE BODY
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ACCOUNT CONTEXT BOX
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                _billAmountRow(
                                  'Sales Outstanding',
                                  customer.grossBillOutstanding,
                                ),
                                _billAmountRow(
                                  'Manual / Opening',
                                  customer.grossManualOutstanding,
                                ),
                                if (customer.advanceBalance > 0.001)
                                  _billAmountRow(
                                    'Advance Balance',
                                    customer.advanceBalance,
                                    valueColor: const Color(0xFF2563EB),
                                  ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Divider(height: 1),
                                ),
                                _billAmountRow(
                                  'Maximum Collectable',
                                  maxCollectable,
                                  bold: true,
                                  valueColor: AppColors.error,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // RECEIPT AMOUNT FIELD
                          TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Receipt Amount Received',
                              prefixText: '₹ ',
                              prefixIcon:
                                  const Icon(Icons.currency_rupee_rounded),
                              errorText: isOver
                                  ? 'Cannot exceed outstanding ₹${maxCollectable.toStringAsFixed(2)}'
                                  : null,
                            ),
                            onChanged: (_) {
                              clientRequestId = null;
                              updateSheet(() {});
                            },
                          ),
                          const SizedBox(height: 10),

                          // PAYMENT MODE & DATE
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: paymentMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Mode',
                                    prefixIcon: Icon(Icons.payments_outlined),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                  ),
                                  items: const [
                                    'Cash',
                                    'UPI',
                                    'PhonePe',
                                    'Google Pay',
                                    'Paytm',
                                    'Bank Transfer',
                                  ]
                                      .map(
                                        (mode) => DropdownMenuItem(
                                          value: mode,
                                          child: Text(
                                            mode,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null && value != paymentMode) {
                                      clientRequestId = null;
                                      updateSheet(() => paymentMode = value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: dialogContext,
                                      initialDate: collectionDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      updateSheet(
                                        () => collectionDate = picked,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _formatDate(collectionDate),
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // REFERENCE & REMARKS
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: referenceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Reference No.',
                                    prefixIcon: Icon(Icons.tag_outlined),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                  ),
                                  onChanged: (_) {
                                    clientRequestId = null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: remarksController,
                                  decoration: const InputDecoration(
                                    labelText: 'Remarks',
                                    prefixIcon: Icon(Icons.comment_outlined),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ==========================================
                          // MANUAL BILL SELECTION SECTION
                          // ==========================================
                          if (allocationMode == 'MANUAL') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'OPEN BILLS (${openItems.length})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => selectAll(updateSheet),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Select All',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => clearAll(updateSheet),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                    if (enteredAmount > 0.001 &&
                                        selectedItems.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => autoFillSelected(
                                          enteredAmount,
                                          updateSheet,
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Auto-Fill',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // List of bills
                            if (openItems.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'No open bills found. Switch to Auto FIFO mode.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ...openItems.map((_SelectableBillItem item) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: item.isSelected
                                        ? const Color(0xFFF0FDF4)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: item.isSelected
                                          ? const Color(0xFF86EFAC)
                                          : AppColors.border,
                                      width: item.isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: item.isSelected,
                                              activeColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              onChanged: (_) =>
                                                  toggleItem(item, updateSheet),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (item.isSelected)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              margin: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '#${item.selectionOrder}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${item.sourceType == 'MANUAL_OUTSTANDING' ? 'Manual' : 'Bill'} • ${item.referenceNo}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                if (item.date != null)
                                                  Text(
                                                    _formatDate(item.date!),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₹${item.currentDue.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.error,
                                                ),
                                              ),
                                              const Text(
                                                'Current Due',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  color: AppColors
                                                      .textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (item.isSelected) ...[
                                        const Divider(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 38,
                                                child: TextField(
                                                  controller: item.controller,
                                                  keyboardType:
                                                      const TextInputType
                                                          .numberWithOptions(
                                                    decimal: true,
                                                  ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(
                                                      RegExp(
                                                        r'^\d*\.?\d{0,2}',
                                                      ),
                                                    ),
                                                  ],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText: 'Apply Now (₹)',
                                                    labelStyle: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                    errorText: item.isOverApplied
                                                        ? 'Max ₹${item.currentDue.toStringAsFixed(2)}'
                                                        : null,
                                                    isDense: true,
                                                  ),
                                                  onChanged: (_) {
                                                    clientRequestId = null;
                                                    updateSheet(() {});
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                item.controller.text = item
                                                    .currentDue
                                                    .toStringAsFixed(2);
                                                clientRequestId = null;
                                                updateSheet(() {});
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Full Due',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Original: ₹${item.originalAmount.toStringAsFixed(2)} • Paid: ₹${item.paidSoFar.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Due After: ₹${item.dueAfter.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: item.dueAfter <= 0.001
                                                    ? AppColors.success
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 8),

                            // LIVE ALLOCATION SUMMARY BAR
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (unallocated.abs() <= 0.001 &&
                                        enteredAmount > 0.001)
                                    ? const Color(0xFFE8F8EE)
                                    : (hasAllocationError || unallocated < -0.001
                                        ? const Color(0xFFFFECEE)
                                        : const Color(0xFFFFF7E8)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (unallocated.abs() <= 0.001 &&
                                          enteredAmount > 0.001)
                                      ? const Color(0xFF86EFAC)
                                      : (hasAllocationError ||
                                              unallocated < -0.001
                                          ? const Color(0xFFFCA5A5)
                                          : const Color(0xFFFDE68A)),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _summaryPill(
                                        'Receipt',
                                        '₹${enteredAmount.toStringAsFixed(2)}',
                                        AppColors.textPrimary,
                                      ),
                                      _summaryPill(
                                        'Allocated',
                                        '₹${totalAllocated.toStringAsFixed(2)}',
                                        isManualValid
                                            ? AppColors.success
                                            : AppColors.primary,
                                      ),
                                      _summaryPill(
                                        'Unallocated',
                                        '₹${unallocated.toStringAsFixed(2)}',
                                        unallocated.abs() <= 0.001
                                            ? AppColors.success
                                            : (unallocated > 0
                                                ? const Color(0xFFD97706)
                                                : AppColors.error),
                                      ),
                                    ],
                                  ),
                                  if (unallocated.abs() > 0.001 &&
                                      enteredAmount > 0) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            unallocated > 0
                                                ? '₹${unallocated.toStringAsFixed(2)} remaining to allocate to selected bills.'
                                                : 'Over-allocated by ₹${(-unallocated).toStringAsFixed(2)}.',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: unallocated > 0
                                                  ? const Color(0xFFD97706)
                                                  : AppColors.error,
                                            ),
                                          ),
                                        ),
                                        if (totalAllocated > 0.001)
                                          InkWell(
                                            onTap: () {
                                              amountController.text =
                                                  totalAllocated
                                                      .toStringAsFixed(2);
                                              clientRequestId = null;
                                              updateSheet(() {});
                                            },
                                            child: const Text(
                                              'Match Receipt',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  if (hasAllocationError) ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Please ensure each selected bill has an applied amount > 0 and <= current due.',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else ...[
                            // ==========================================
                            // AUTO FIFO PREVIEW SECTION
                            // ==========================================
                            if (enteredAmount > 0)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isOver
                                      ? const Color(0xFFFFECEE)
                                      : (enteredAmount >= maxCollectable - 0.001
                                          ? const Color(0xFFE8F8EE)
                                          : const Color(0xFFF0F4F8)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isOver
                                        ? const Color(0xFFFCA5A5)
                                        : (enteredAmount >= maxCollectable - 0.001
                                            ? const Color(0xFF86EFAC)
                                            : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isOver
                                              ? Icons.error_outline
                                              : (enteredAmount >=
                                                      maxCollectable - 0.001
                                                  ? Icons.check_circle_outline
                                                  : Icons.info_outline),
                                          size: 16,
                                          color: isOver
                                              ? AppColors.error
                                              : (enteredAmount >=
                                                      maxCollectable - 0.001
                                                  ? AppColors.success
                                                  : AppColors.textPrimary),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isOver
                                                ? 'Collection amount cannot exceed outstanding of ₹${maxCollectable.toStringAsFixed(2)}.'
                                                : (enteredAmount >=
                                                        maxCollectable - 0.001
                                                    ? 'Customer will be fully settled after this receipt (FIFO).'
                                                    : '₹${(maxCollectable - enteredAmount).toStringAsFixed(2)} will remain outstanding after this receipt.'),
                                            style: TextStyle(
                                              color: isOver
                                                  ? AppColors.error
                                                  : (enteredAmount >=
                                                          maxCollectable - 0.001
                                                      ? AppColors.success
                                                      : AppColors.textPrimary),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isOver) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Automatic FIFO: Oldest open balances will be settled first.',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: !canSubmit
                          ? null
                          : () async {
                              final amount = double.tryParse(
                                    amountController.text.trim(),
                                  ) ??
                                  0;
                              if (amount <= 0) return;
                              if (amount > maxCollectable + 0.001) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Collection amount cannot exceed current outstanding of ₹${maxCollectable.toStringAsFixed(2)}.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (allocationMode == 'MANUAL') {
                                if (selectedItems.isEmpty) {
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select at least one bill to allocate.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if ((amount - totalAllocated).abs() > 0.001) {
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Total allocated (₹${totalAllocated.toStringAsFixed(2)}) must equal receipt amount (₹${amount.toStringAsFixed(2)}).',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (hasAllocationError) {
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please ensure all selected bills have valid amounts (<= current due).',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }

                              clientRequestId ??= generateNewRequestId();

                              setState(() {
                                _isSaving = true;
                              });
                              updateSheet(() {});

                              try {
                                final Map<String, dynamic> requestPayload = {
                                  'customerId': customer.customerId,
                                  'amount': amount,
                                  'paymentMode': paymentMode,
                                  'collectionDate':
                                      collectionDate.toIso8601String(),
                                  'referenceNo':
                                      referenceController.text.trim(),
                                  'remarks': remarksController.text.trim(),
                                  'clientRequestId': clientRequestId,
                                  'allocationMode': allocationMode,
                                };

                                if (allocationMode == 'MANUAL') {
                                  requestPayload['selectedAllocations'] =
                                      selectedItems
                                          .map(
                                            (_SelectableBillItem i) => {
                                              'sourceType': i.sourceType,
                                              'referenceId': i.referenceId,
                                              'amountApplied': i.appliedAmount,
                                            },
                                          )
                                          .toList();
                                }

                                final response = await http.post(
                                  Uri.parse(
                                    '${ApiConfig.baseUrl}/api/collections',
                                  ),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    if (ApiConfig.token.isNotEmpty)
                                      'Authorization':
                                          'Bearer ${ApiConfig.token}',
                                  },
                                  body: jsonEncode(requestPayload),
                                );

                                final decoded = jsonDecode(response.body);

                                if (response.statusCode == 409) {
                                  throw Exception(
                                    decoded is Map &&
                                            decoded['message'] != null
                                        ? decoded['message'].toString()
                                        : 'Collection conflict: Customer balances have changed. Please refresh and retry.',
                                  );
                                }

                                if (response.statusCode < 200 ||
                                    response.statusCode >= 300 ||
                                    decoded is! Map ||
                                    decoded['success'] != true) {
                                  throw Exception(
                                    decoded is Map
                                        ? (decoded['message'] ??
                                                'Unable to save collection.')
                                            .toString()
                                        : 'Unable to save collection.',
                                  );
                                }

                                if (!mounted || !sheetContext.mounted) return;
                                Navigator.pop(sheetContext);

                                final data = decoded['data'];
                                final receiptNo = data is Map
                                    ? (data['receiptNo'] ?? '').toString()
                                    : '';

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      receiptNo.isEmpty
                                          ? 'Collection saved successfully.'
                                          : 'Collection saved • $receiptNo',
                                    ),
                                  ),
                                );

                                await _loadCollectionData();
                              } catch (error) {
                                if (!mounted || !sheetContext.mounted) return;
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.error,
                                    content: Text(
                                      error.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSaving = false;
                                  });
                                  updateSheet(() {});
                                }
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              allocationMode == 'MANUAL'
                                  ? 'COLLECT SELECTED BILLS'
                                  : 'SAVE AUTO FIFO COLLECTION',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      amountController.dispose();
      referenceController.dispose();
      remarksController.dispose();
      for (final item in openItems) {
        item.dispose();
      }
    });
  }

  Widget _summaryPill(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // RECEIPT DETAIL BOTTOM SHEET
  // ==========================================================================
  void _showReceiptSheet(CollectionReceiptModel receipt) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // RECEIPT HEADER
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: receipt.isBillPayment
                            ? const Color(0xFFEFF6FF)
                            : (receipt.isCancelled
                                ? const Color(0xFFFFECEE)
                                : const Color(0xFFE8F8EE)),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        receipt.isBillPayment
                            ? Icons.receipt_long_outlined
                            : Icons.payments_outlined,
                        color: receipt.isBillPayment
                            ? const Color(0xFF2563EB)
                            : (receipt.isCancelled
                                ? AppColors.error
                                : AppColors.success),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.isBillPayment
                                ? 'Sale Billing Receipt'
                                : 'Collection Receipt',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            receipt.receiptNo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (receipt.isCancelled
                                ? AppColors.error
                                : AppColors.success)
                            .withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        receipt.status,
                        style: TextStyle(
                          color: receipt.isCancelled
                              ? AppColors.error
                              : AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // HERO AMOUNT CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: receipt.isBillPayment
                        ? const Color(0xFFEFF6FF)
                        : (receipt.isCancelled
                            ? const Color(0xFFFFECEE)
                            : const Color(0xFFE8F8EE)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        receipt.isBillPayment
                            ? 'Amount Received at Billing'
                            : 'Amount Received',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${(receipt.isBillPayment ? receipt.paidAmount : receipt.amount).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: receipt.isBillPayment
                              ? const Color(0xFF2563EB)
                              : (receipt.isCancelled
                                  ? AppColors.error
                                  : AppColors.success),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        receipt.paymentMode,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _receiptRow('Customer', receipt.customerName),
                _receiptRow('Customer Code', receipt.customerId),
                _receiptRow(
                  receipt.isBillPayment ? 'Bill No.' : 'Receipt No.',
                  receipt.receiptNo,
                ),
                _receiptRow(
                  'Date',
                  receipt.displayDate == null
                      ? '-'
                      : _formatDate(receipt.displayDate!.toLocal()),
                ),
                _receiptRow('Payment Mode', receipt.paymentMode),
                if (!receipt.isBillPayment)
                  _receiptRow(
                    'Allocation Method',
                    receipt.isManualAllocation
                        ? 'Manual Bill Selection'
                        : (receipt.allocationMode == 'FIFO'
                            ? 'Auto FIFO'
                            : 'Legacy FIFO'),
                  ),
                if (receipt.route.trim().isNotEmpty)
                  _receiptRow('Route', receipt.route),
                if (receipt.salesmanName.trim().isNotEmpty)
                  _receiptRow('Collected By', receipt.salesmanName),
                if (receipt.referenceNo.trim().isNotEmpty)
                  _receiptRow('Reference No.', receipt.referenceNo),
                if (receipt.remarks.trim().isNotEmpty)
                  _receiptRow('Remarks', receipt.remarks),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),

                // FINANCIAL SNAPSHOTS
                if (receipt.isBillPayment) ...[
                  _receiptRow(
                    'Bill Amount',
                    '₹${receipt.billAmount.toStringAsFixed(2)}',
                  ),
                  _receiptRow(
                    'Paid at Billing',
                    '₹${receipt.paidAmount.toStringAsFixed(2)}',
                  ),
                  _receiptRow(
                    'Applied to Bill',
                    '₹${receipt.paymentApplied.toStringAsFixed(2)}',
                  ),
                  if (receipt.advanceUsed > 0.001)
                    _receiptRow(
                      'Advance Used',
                      '₹${receipt.advanceUsed.toStringAsFixed(2)}',
                    ),
                  if (receipt.advanceCreated > 0.001)
                    _receiptRow(
                      'Advance Created',
                      '₹${receipt.advanceCreated.toStringAsFixed(2)}',
                    ),
                  _receiptRow(
                    'Outstanding After',
                    '₹${receipt.remainingOutstanding.toStringAsFixed(2)}',
                  ),
                  if (receipt.payments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'PAYMENT BREAKUP',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...receipt.payments.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.mode, style: const TextStyle(fontSize: 11)),
                              Text(
                                '₹${p.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ] else ...[
                  // COLLECTION PERSISTENT SNAPSHOTS
                  _receiptRow(
                    'Previous Outstanding',
                    '₹${receipt.previousOutstanding.toStringAsFixed(2)}',
                  ),
                  _receiptRow(
                    'Amount Applied',
                    '₹${receipt.appliedAmount.toStringAsFixed(2)}',
                  ),
                  _receiptRow(
                    'Remaining Outstanding',
                    '₹${receipt.remainingOutstanding.toStringAsFixed(2)}',
                  ),
                  if (receipt.advanceAmount > 0.001)
                    _receiptRow(
                      'Advance Created',
                      '₹${receipt.advanceAmount.toStringAsFixed(2)}',
                    ),

                  const SizedBox(height: 12),

                  // ALLOCATIONS BREAKDOWN
                  const Text(
                    'SETTLEMENT ALLOCATIONS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (receipt.allocations.isNotEmpty)
                    ...receipt.allocations.map((alloc) {
                      if (alloc.hasAccountingSnapshot) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${alloc.allocationSequence}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${alloc.sourceType == 'MANUAL_OUTSTANDING' ? 'Manual' : 'Sale'} • ${alloc.referenceNo}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (alloc.customerName.isNotEmpty)
                                    Text(
                                      alloc.customerName,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Source Total: ₹${alloc.sourceAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Due Before: ₹${alloc.outstandingBefore!.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 10.5),
                                  ),
                                  Text(
                                    'Applied: ₹${alloc.amountApplied.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    'Due After: ₹${alloc.outstandingAfter!.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Historical allocation without before/after snapshots
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#${alloc.allocationSequence} • ${alloc.sourceType == 'MANUAL_OUTSTANDING' ? 'Manual' : 'Sale'} • ${alloc.referenceNo}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Applied: ₹${alloc.amountApplied.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Historical receipt — detailed allocation snapshot unavailable.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    })
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Historical receipt — detailed allocation snapshot unavailable.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 18),

                // CANCELLATION BUTTON (Only for POSTED collections)
                if (receipt.isCollection &&
                    !receipt.isCancelled &&
                    UiSession.instance.can(AppPermission.collectionCreate)) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: () =>
                          _confirmCancelReceipt(sheetContext, receipt),
                      icon: const Icon(Icons.cancel_outlined, size: 17),
                      label: const Text('CANCEL THIS RECEIPT'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('DONE'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmCancelReceipt(
    BuildContext sheetContext,
    CollectionReceiptModel receipt,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel receipt ${receipt.receiptNo} of ₹${receipt.amount.toStringAsFixed(2)}?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NO, KEEP'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/collections/${receipt.id}/cancel'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiConfig.token.isNotEmpty)
            'Authorization': 'Bearer ${ApiConfig.token}',
        },
        body: jsonEncode({
          'cancelReason': reasonController.text.trim(),
        }),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded is! Map ||
          decoded['success'] != true) {
        throw Exception(
          decoded is Map
              ? (decoded['message'] ?? 'Unable to cancel collection.').toString()
              : 'Unable to cancel collection.',
        );
      }

      if (!mounted || !sheetContext.mounted) return;
      Navigator.pop(sheetContext); // Close receipt sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt ${receipt.receiptNo} cancelled successfully.'),
        ),
      );

      await _loadCollectionData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // RECEIPT HISTORY SHEET
  // ==========================================================================
  void _showReceiptHistorySheet(CustomerCollectionModel customer) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Receipt History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${customer.name} • ${customer.receiptHistory.length} receipts',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (customer.receiptHistory.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No receipts recorded for this customer.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: customer.receiptHistory.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final receipt = customer.receiptHistory[idx];
                        final isBill = receipt.isBillPayment;
                        final amount =
                            isBill ? receipt.paidAmount : receipt.amount;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isBill
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFE8F8EE),
                              foregroundColor: isBill
                                  ? const Color(0xFF2563EB)
                                  : AppColors.success,
                              child: Icon(
                                isBill
                                    ? Icons.receipt_long_outlined
                                    : Icons.payments_outlined,
                                size: 19,
                              ),
                            ),
                            title: Text(
                              isBill
                                  ? 'Sale Payment • ${receipt.receiptNo}'
                                  : 'Collection • ${receipt.receiptNo}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${receipt.displayDate == null ? '-' : _formatDate(receipt.displayDate!.toLocal())} • ${receipt.paymentMode}${isBill ? '' : (receipt.isManualAllocation ? ' • Manual' : ' • Auto FIFO')}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: receipt.isCancelled
                                        ? AppColors.error
                                        : AppColors.success,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (receipt.isCancelled
                                            ? AppColors.error
                                            : AppColors.success)
                                        .withValues(alpha: .10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    receipt.status,
                                    style: TextStyle(
                                      color: receipt.isCancelled
                                          ? AppColors.error
                                          : AppColors.success,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _showReceiptSheet(receipt);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // BILL DETAILS SHEET
  // ==========================================================================
  void _showBillDetails(
    CustomerCollectionModel customer,
    CollectionBillModel bill,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bill Details',
                            style: Theme.of(sheetContext).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${customer.name} • ${bill.saleNo}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _receiptRow('Bill Status', bill.paymentStatus),
                _receiptRow('Bill Amount', '₹${bill.billAmount.toStringAsFixed(2)}'),
                _receiptRow('Paid at Billing', '₹${bill.paidAtBilling.toStringAsFixed(2)}'),
                _receiptRow(
                  'Payment Applied at Billing',
                  '₹${bill.paymentAppliedAtBilling.toStringAsFixed(2)}',
                ),
                if (bill.advanceUsed > 0.001)
                  _receiptRow(
                    'Advance Used',
                    '₹${bill.advanceUsed.toStringAsFixed(2)}',
                  ),
                if (bill.collectionApplied > 0.001)
                  _receiptRow(
                    'Later Collection Applied',
                    '₹${bill.collectionApplied.toStringAsFixed(2)}',
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(height: 1),
                ),
                _receiptRow(
                  'Total Applied to Bill',
                  '₹${bill.totalAppliedToBill.toStringAsFixed(2)}',
                ),
                _receiptRow(
                  'Remaining Outstanding',
                  '₹${bill.remainingOutstanding.toStringAsFixed(2)}',
                ),
                if (bill.saleDate != null)
                  _receiptRow(
                    'Bill Date',
                    _formatDate(bill.saleDate!.toLocal()),
                  ),
                if (bill.payments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'PAYMENT BREAKUP AT BILLING',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...bill.payments.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.mode, style: const TextStyle(fontSize: 11)),
                            Text(
                              '₹${p.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('DONE'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================
  Widget _billAmountRow(
    String label,
    double amount, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: bold ? 12 : 11,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: valueColor ??
                  (bold ? AppColors.textPrimary : AppColors.textSecondary),
              fontSize: bold ? 13 : 11.5,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
                items: _routeOptions
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
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
                items: _salesmanOptions
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
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
                    _loadCollectionData();
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

  String _apiDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
