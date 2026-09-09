import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
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
  String _selectedRoute = 'All Routes';
  String _selectedSalesman = 'All Salesmen';

  DateTime _selectedDate = DateTime.now();

  final List<_CustomerCollection> _customers = [];

  final List<Map<String, dynamic>> _collections = [];

  bool _isLoading = false;
  bool _isSaving = false;

  String _loadError = '';
  List<_CustomerCollection> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();

    return _customers
        .where((customer) {
          final matchesSearch =
              query.isEmpty ||
              customer.name.toLowerCase().contains(query) ||
              customer.code.toLowerCase().contains(query) ||
              customer.mobile.contains(query);

          final matchesRoute =
              _selectedRoute == 'All Routes' ||
              customer.route == _selectedRoute;

          final matchesSalesman =
              _selectedSalesman == 'All Salesmen' ||
              customer.salesmanName == _selectedSalesman;

          return matchesSearch && matchesRoute && matchesSalesman;
        })
        .toList(growable: false);
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
      .where((customer) => customer.status != PaymentStatus.paid)
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

        if (ApiConfig.token != null && ApiConfig.token!.isNotEmpty)
          'Authorization': 'Bearer ${ApiConfig.token}',
      };

      // ==========================================
      // OUTSTANDING CUSTOMERS
      // ==========================================

      final outstandingResponse = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}'
          '/api/collections/outstanding',
        ),
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
      // COLLECTION HISTORY FOR SELECTED DATE
      // ==========================================

      final historyResponse = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}'
          '/api/collections'
          '?date=${_apiDate(_selectedDate)}',
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
      // BUILD CUSTOMER LIST
      // ==========================================

      final List<_CustomerCollection> loadedCustomers = [];

      final rawOutstanding = outstandingDecoded['data'];

      if (rawOutstanding is List) {
        for (final raw in rawOutstanding) {
          if (raw is! Map) {
            continue;
          }

          final item = Map<String, dynamic>.from(raw);

          final statusText = (item['status'] ?? 'DUE').toString().toUpperCase();

          PaymentStatus status = PaymentStatus.due;

          if (statusText == 'PAID') {
            status = PaymentStatus.paid;
          } else if (statusText == 'PARTIAL') {
            status = PaymentStatus.partial;
          }

          // ==========================================
          // BILL-WISE OUTSTANDING
          // ==========================================

          final List<_CollectionBill> bills = [];

          final rawBills = item['bills'];

          if (rawBills is List) {
            for (final rawBill in rawBills) {
              if (rawBill is! Map) {
                continue;
              }

              final bill = Map<String, dynamic>.from(rawBill);

              // ======================================
              // SALE PAYMENT BREAKUP
              // ======================================

              final List<_BillPayment> payments = [];

              final rawPayments = bill['payments'];

              if (rawPayments is List) {
                for (final rawPayment in rawPayments) {
                  if (rawPayment is! Map) {
                    continue;
                  }

                  final payment = Map<String, dynamic>.from(rawPayment);

                  payments.add(
                    _BillPayment(
                      mode: (payment['mode'] ?? '').toString(),

                      amount: _asDouble(payment['amount']),

                      referenceNo: (payment['referenceNo'] ?? '').toString(),
                    ),
                  );
                }
              }

              final saleDate = DateTime.tryParse(
                (bill['saleDate'] ?? '').toString(),
              );

              bills.add(
                _CollectionBill(
                  saleId: (bill['saleId'] ?? '').toString(),

                  saleNo: (bill['saleNo'] ?? '').toString(),

                  saleDate: saleDate,

                  billAmount: _asDouble(bill['billAmount']),

                  salePaidAmount: _asDouble(bill['salePaidAmount']),

                  collectionApplied: _asDouble(bill['collectionApplied']),

                  paidAmount: _asDouble(bill['paidAmount']),

                  outstandingAmount: _asDouble(bill['outstandingAmount']),

                  paymentMode: (bill['paymentMode'] ?? '').toString(),

                  paymentStatus: (bill['paymentStatus'] ?? 'CREDIT')
                      .toString()
                      .toUpperCase(),

                  payments: payments,
                ),
              );
            }
          }
          loadedCustomers.add(
            _CustomerCollection(
              customerId: (item['customerId'] ?? '').toString(),

              name: (item['customerName'] ?? '').toString(),

              code: (item['customerId'] ?? '').toString(),

              mobile: (item['customerMobile'] ?? '').toString(),

              route: (item['route'] ?? '').toString(),

              salesmanId: (item['salesmanId'] ?? '').toString(),

              salesmanName: (item['salesmanName'] ?? '').toString(),

              amount: _asDouble(item['outstanding']),

              totalCreditSales: _asDouble(item['totalCreditSales']),

              totalCollected: _asDouble(item['totalCollected']),

              paymentMode:
                  (item['lastPaymentMode'] ?? '').toString().trim().isNotEmpty
                  ? item['lastPaymentMode'].toString()
                  : 'Pending',

              status: status,

              bills: bills,

              avatarColor: const Color(0xFFE6F2FF),

              avatarIconColor: const Color(0xFF1767D9),
            ),
          );
        }
      }

      // ==========================================
      // COLLECTION HISTORY
      // ==========================================

      final List<Map<String, dynamic>> loadedCollections = [];

      final rawHistory = historyDecoded['data'];

      if (rawHistory is List) {
        for (final raw in rawHistory) {
          if (raw is Map) {
            loadedCollections.add(Map<String, dynamic>.from(raw));
          }
        }
      }

      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;

        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _asDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

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

  Widget _customerCard(
  _CustomerCollection customer,
) {
  final customerStatusColor =
      switch (customer.status) {
    PaymentStatus.paid =>
      AppColors.success,

    PaymentStatus.partial =>
      AppColors.warning,

    PaymentStatus.due =>
      AppColors.error,
  };

  return Card(
    margin:
        const EdgeInsets.only(
      bottom: 14,
    ),
    child: Padding(
      padding:
          const EdgeInsets.all(
        14,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ==========================================
          // CUSTOMER HEADER
          // ==========================================

          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    customer.avatarColor,
                foregroundColor:
                    customer.avatarIconColor,
                child: const Icon(
                  Icons
                      .storefront_outlined,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textPrimary,
                        fontSize: 15,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      [
                        customer.code,

                        if (customer
                            .route
                            .trim()
                            .isNotEmpty)
                          customer.route,
                      ].join(' • '),
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${customer.amount.toStringAsFixed(2)}',
                    style:
                        TextStyle(
                      color:
                          customerStatusColor,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    customer.amount <=
                            0.001
                        ? 'CLEAR'
                        : 'OUTSTANDING',
                    style:
                        TextStyle(
                      color:
                          customerStatusColor,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          const Divider(
            height: 1,
          ),

          const SizedBox(
            height: 12,
          ),

          // ==========================================
          // BILL LIST
          // ==========================================

          if (customer.bills.isEmpty)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Text(
                'No bill details available.',
                style: TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                  fontSize: 11,
                ),
              ),
            )
          else
            ...customer.bills.map(
              (bill) =>
                  _collectionBillCard(
                customer,
                bill,
              ),
            ),
        ],
      ),
    ),
  );
}
Widget _collectionBillCard(
  _CustomerCollection customer,
  _CollectionBill bill,
) {
  final isPaid =
      bill.outstandingAmount <=
      0.001;

  final isPartial =
      !isPaid &&
      bill.paidAmount > 0;

  final statusText =
      isPaid
          ? 'PAID'
          : isPartial
              ? 'PARTIAL'
              : 'OUTSTANDING';

  final statusColor =
      isPaid
          ? AppColors.success
          : isPartial
              ? AppColors.warning
              : AppColors.error;

  return Container(
    width: double.infinity,
    margin:
        const EdgeInsets.only(
      bottom: 10,
    ),
    padding:
        const EdgeInsets.all(
      12,
    ),
    decoration: BoxDecoration(
      border: Border.all(
        color:
            AppColors.border,
      ),
      borderRadius:
          BorderRadius.circular(
        12,
      ),
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ==========================================
        // BILL HEADER
        // ==========================================

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    bill.saleNo.isEmpty
                        ? 'Sale Bill'
                        : bill.saleNo,
                    style:
                        const TextStyle(
                      color:
                          AppColors
                              .textPrimary,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  if (bill.saleDate !=
                      null) ...[
                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      _formatDate(
                        bill.saleDate!
                            .toLocal(),
                      ),
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color:
                    statusColor
                        .withValues(
                  alpha: .10,
                ),
                borderRadius:
                    BorderRadius
                        .circular(
                  20,
                ),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color:
                      statusColor,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        // ==========================================
        // BILL AMOUNT
        // ==========================================

        _billAmountRow(
          'Bill Amount',
          bill.billAmount,
          bold: true,
        ),

        const SizedBox(
          height: 7,
        ),

        // ==========================================
        // PAYMENT AT BILLING
        // ==========================================

        if (bill.cashAmount >
            0)
          _billAmountRow(
            'Cash',
            bill.cashAmount,
          ),

        if (bill.upiAmount >
            0)
          _billAmountRow(
            'UPI / Online',
            bill.upiAmount,
          ),

        if (bill.bankAmount >
            0)
          _billAmountRow(
            'Bank',
            bill.bankAmount,
          ),

        if (bill.salePaidAmount >
            0) ...[
          const SizedBox(
            height: 4,
          ),

          _billAmountRow(
            'Paid at Sale',
            bill.salePaidAmount,
          ),
        ],

        if (bill.collectionApplied >
            0)
          _billAmountRow(
            'Collection Applied',
            bill.collectionApplied,
          ),

        const Padding(
          padding:
              EdgeInsets.symmetric(
            vertical: 7,
          ),
          child: Divider(
            height: 1,
          ),
        ),

        _billAmountRow(
          'Total Paid',
          bill.paidAmount,
          bold: true,
        ),

        _billAmountRow(
          'Outstanding',
          bill.outstandingAmount,
          bold: true,
          valueColor:
              isPaid
                  ? AppColors.success
                  : AppColors.error,
        ),

        const SizedBox(
          height: 12,
        ),

        // ==========================================
        // ACTIONS
        // ==========================================

        if (!isPaid)
          SizedBox(
            width:
                double.infinity,
            child:
                ElevatedButton.icon(
              onPressed: () =>
                  _showCollectionEntry(
                customer,
              ),
              icon:
                  const Icon(
                Icons
                    .payments_outlined,
                size: 18,
              ),
              label: Text(
                'COLLECT ₹${bill.outstandingAmount.toStringAsFixed(2)}',
              ),
            ),
          ),

        if (!isPaid)
          const SizedBox(
            height: 7,
          ),

        Row(
          children: [
            Expanded(
              child:
                  OutlinedButton.icon(
                onPressed: () =>
                    _showBillDetails(
                  customer,
                  bill,
                ),
                icon:
                    const Icon(
                  Icons
                      .visibility_outlined,
                  size: 17,
                ),
                label:
                    const Text(
                  'DETAILS',
                ),
              ),
            ),

            if (bill.collectionApplied >
                0) ...[
              const SizedBox(
                width: 7,
              ),

              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: () =>
                      _openLatestReceipt(
                    customer,
                  ),
                  icon:
                      const Icon(
                    Icons
                        .receipt_long_outlined,
                    size: 17,
                  ),
                  label:
                      const Text(
                    'RECEIPT',
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}
Widget _billAmountRow(
  String label,
  double amount, {
  bool bold = false,
  Color? valueColor,
}) {
  return Padding(
    padding:
        const EdgeInsets.symmetric(
      vertical: 3,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  AppColors
                      .textSecondary,
              fontSize: 11,
              fontWeight:
                  bold
                      ? FontWeight.w700
                      : FontWeight.w500,
            ),
          ),
        ),

        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color:
                valueColor ??
                AppColors
                    .textPrimary,
            fontSize: 11.5,
            fontWeight:
                bold
                    ? FontWeight.w900
                    : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

void _showBillDetails(
  _CustomerCollection customer,
  _CollectionBill bill,
) {
  final status =
      bill.outstandingAmount <=
              0.001
          ? 'PAID'
          : bill.paidAmount > 0
              ? 'PARTIAL'
              : 'OUTSTANDING';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (
      sheetContext,
    ) {
      return SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets
                  .fromLTRB(
            16,
            12,
            16,
            28,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                'Bill Details',
                style:
                    Theme.of(
                  sheetContext,
                )
                        .textTheme
                        .titleLarge,
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                '${customer.name} • ${bill.saleNo}',
                style:
                    const TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              _receiptRow(
                'Status',
                status,
              ),

              _receiptRow(
                'Bill Amount',
                '₹${bill.billAmount.toStringAsFixed(2)}',
              ),

              if (bill.cashAmount >
                  0)
                _receiptRow(
                  'Cash',
                  '₹${bill.cashAmount.toStringAsFixed(2)}',
                ),

              if (bill.upiAmount >
                  0)
                _receiptRow(
                  'UPI / Online',
                  '₹${bill.upiAmount.toStringAsFixed(2)}',
                ),

              if (bill.bankAmount >
                  0)
                _receiptRow(
                  'Bank',
                  '₹${bill.bankAmount.toStringAsFixed(2)}',
                ),

              _receiptRow(
                'Paid at Sale',
                '₹${bill.salePaidAmount.toStringAsFixed(2)}',
              ),

              _receiptRow(
                'Collection',
                '₹${bill.collectionApplied.toStringAsFixed(2)}',
              ),

              _receiptRow(
                'Total Paid',
                '₹${bill.paidAmount.toStringAsFixed(2)}',
              ),

              _receiptRow(
                'Outstanding',
                '₹${bill.outstandingAmount.toStringAsFixed(2)}',
              ),

              if (bill.saleDate !=
                  null)
                _receiptRow(
                  'Bill Date',
                  _formatDate(
                    bill.saleDate!
                        .toLocal(),
                  ),
                ),

              const SizedBox(
                height: 18,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                    sheetContext,
                  ),
                  child:
                      const Text(
                    'DONE',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Future<void> _customerAction(_CustomerCollection customer) async {
    if (customer.status == PaymentStatus.paid) {
      await _openLatestReceipt(customer);

      return;
    }

    _showCollectionEntry(customer);
  }

  Future<void> _openLatestReceipt(_CustomerCollection customer) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}'
          '/api/collections'
          '?customerId=${Uri.encodeQueryComponent(customer.customerId)}',
        ),
        headers: {
          'Content-Type': 'application/json',

          if (ApiConfig.token != null && ApiConfig.token!.isNotEmpty)
            'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final decoded = jsonDecode(response.body);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded is! Map ||
          decoded['success'] != true) {
        throw Exception(
          decoded is Map
              ? (decoded['message'] ?? 'Unable to load receipt.').toString()
              : 'Unable to load receipt.',
        );
      }

      final rawData = decoded['data'];

      if (rawData is! List || rawData.isEmpty) {
        throw Exception('No receipt found for this customer.');
      }

      Map<String, dynamic>? latestReceipt;

      for (final item in rawData) {
        if (item is! Map) {
          continue;
        }

        final receipt = Map<String, dynamic>.from(item);

        final status = (receipt['status'] ?? '').toString().toUpperCase();

        if (status != 'POSTED') {
          continue;
        }

        latestReceipt = receipt;

        // API already returns newest first.
        break;
      }

      if (latestReceipt == null) {
        throw Exception('No active receipt found for this customer.');
      }

      if (!mounted) {
        return;
      }

      _showReceiptSheet(latestReceipt);
    } catch (error) {
      if (!mounted) {
        return;
      }

      // Close loader if still open.
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        // Do not force-pop the screen itself.
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _showReceiptSheet(Map<String, dynamic> receipt) {
    final receiptNo = (receipt['receiptNo'] ?? '').toString();

    final customerName = (receipt['customerName'] ?? '').toString();

    final customerId = (receipt['customerId'] ?? '').toString();

    final paymentMode = (receipt['paymentMode'] ?? '').toString();

    final route = (receipt['route'] ?? '').toString();

    final salesmanName = (receipt['salesmanName'] ?? '').toString();

    final referenceNo = (receipt['referenceNo'] ?? '').toString();

    final remarks = (receipt['remarks'] ?? '').toString();

    final amount = _asDouble(receipt['amount']);

    final date = DateTime.tryParse(
      (receipt['collectionDate'] ?? '').toString(),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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

                const SizedBox(height: 18),

                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.success,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Receipt',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          Text(
                            receiptNo,
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
                        color: AppColors.success.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PAID',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Amount Received',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        paymentMode,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _receiptRow('Customer', customerName),

                _receiptRow('Customer Code', customerId),

                _receiptRow('Receipt No.', receiptNo),

                _receiptRow(
                  'Date',
                  date == null ? '-' : _formatDate(date.toLocal()),
                ),

                _receiptRow('Payment Mode', paymentMode),

                if (route.trim().isNotEmpty) _receiptRow('Route', route),

                if (salesmanName.trim().isNotEmpty)
                  _receiptRow('Collected By', salesmanName),

                if (referenceNo.trim().isNotEmpty)
                  _receiptRow('Reference No.', referenceNo),

                if (remarks.trim().isNotEmpty) _receiptRow('Remarks', remarks),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
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

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
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

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Outstanding',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '₹${customer.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
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
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final amount =
                              double.tryParse(amountController.text.trim()) ??
                              0;

                          if (amount <= 0) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text('Enter collection amount.'),
                              ),
                            );

                            return;
                          }

                          if (amount > customer.amount) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Amount cannot exceed outstanding '
                                  '₹${customer.amount.toStringAsFixed(2)}.',
                                ),
                              ),
                            );

                            return;
                          }

                          setState(() {
                            _isSaving = true;
                          });

                          try {
                            final response = await http.post(
                              Uri.parse(
                                '${ApiConfig.baseUrl}'
                                '/api/collections',
                              ),
                              headers: {
                                'Content-Type': 'application/json',

                                if (ApiConfig.token != null &&
                                    ApiConfig.token!.isNotEmpty)
                                  'Authorization': 'Bearer ${ApiConfig.token}',
                              },
                              body: jsonEncode({
                                'customerId': customer.customerId,

                                'amount': amount,

                                'paymentMode': paymentMode,

                                'collectionDate': DateTime.now()
                                    .toIso8601String(),

                                'referenceNo': '',

                                'remarks': '',
                              }),
                            );

                            final decoded = jsonDecode(response.body);

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

                            if (!mounted) {
                              return;
                            }

                            Navigator.pop(sheetContext);

                            final data = decoded['data'];

                            final receiptNo = data is Map
                                ? (data['receiptNo'] ?? '').toString()
                                : '';

                            ScaffoldMessenger.of(this.context).showSnackBar(
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
                            if (!mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
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
                            }
                          }
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

enum PaymentStatus { paid, due, partial }

class _CustomerCollection {
  const _CustomerCollection({
    required this.customerId,
    required this.name,
    required this.code,
    required this.mobile,
    required this.route,
    required this.salesmanId,
    required this.salesmanName,
    required this.amount,
    required this.totalCreditSales,
    required this.totalCollected,
    required this.paymentMode,
    required this.status,
    required this.bills,
    required this.avatarColor,
    required this.avatarIconColor,
  });

  final String customerId;

  final String name;

  final String code;

  final String mobile;

  final String route;

  final String salesmanId;

  final String salesmanName;

  // CURRENT CUSTOMER OUTSTANDING
  final double amount;

  final double totalCreditSales;

  final double totalCollected;

  final String paymentMode;

  final PaymentStatus status;

  // BILL-WISE OUTSTANDING
  final List<_CollectionBill> bills;

  final Color avatarColor;

  final Color avatarIconColor;
}

// ======================================================
// COLLECTION BILL
// ======================================================

class _CollectionBill {
  const _CollectionBill({
    required this.saleId,
    required this.saleNo,
    required this.saleDate,
    required this.billAmount,
    required this.salePaidAmount,
    required this.collectionApplied,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.paymentMode,
    required this.paymentStatus,
    required this.payments,
  });

  final String saleId;

  final String saleNo;

  final DateTime? saleDate;

  // FULL BILL VALUE
  final double billAmount;

  // PAYMENT RECEIVED DURING BILLING
  final double salePaidAmount;

  // PAYMENT RECEIVED LATER THROUGH COLLECTION
  final double collectionApplied;

  // TOTAL PAID = SALE PAYMENT + COLLECTION
  final double paidAmount;

  // CURRENT LIVE OUTSTANDING
  final double outstandingAmount;

  final String paymentMode;

  final String paymentStatus;

  // CASH / UPI / BANK ETC. RECEIVED DURING SALE
  final List<_BillPayment> payments;

  bool get isPaid => outstandingAmount <= 0.001;

  bool get isPartial => !isPaid && paidAmount > 0;

  bool get isDue => !isPaid && paidAmount <= 0;

  double paymentAmount(String mode) {
    double total = 0;

    for (final payment in payments) {
      if (payment.mode.trim().toLowerCase() == mode.trim().toLowerCase()) {
        total += payment.amount;
      }
    }

    return total;
  }

  double get cashAmount => paymentAmount('Cash');

  double get upiAmount {
    double total = 0;

    for (final payment in payments) {
      final mode = payment.mode.trim().toLowerCase();

      if (mode == 'upi' ||
          mode == 'phonepe' ||
          mode == 'google pay' ||
          mode == 'paytm') {
        total += payment.amount;
      }
    }

    return total;
  }

  double get bankAmount => paymentAmount('Bank Transfer');
}

// ======================================================
// BILL PAYMENT BREAKUP
// ======================================================

class _BillPayment {
  const _BillPayment({
    required this.mode,
    required this.amount,
    required this.referenceNo,
  });

  final String mode;

  final double amount;

  final String referenceNo;
}
