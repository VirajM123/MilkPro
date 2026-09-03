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

DateTime _selectedDate =
    DateTime.now();

final List<_CustomerCollection>
    _customers = [];

final List<Map<String, dynamic>>
    _collections = [];

bool _isLoading = false;
bool _isSaving = false;

String _loadError = '';
 List<_CustomerCollection> get _filteredCustomers {
  final query =
      _searchController.text.trim().toLowerCase();

  return _customers.where((customer) {
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

    return matchesSearch &&
        matchesRoute &&
        matchesSalesman;
  }).toList(growable: false);
}


double get _totalCollected {
  double total = 0;

  for (final collection in _collections) {
    final status =
        (collection['status'] ?? '')
            .toString()
            .toUpperCase();

    if (status != 'POSTED') {
      continue;
    }

    total +=
        _asDouble(
          collection['amount'],
        );
  }

  return total;
}

  int get _pendingCount => _customers
      .where((customer) => customer.status != PaymentStatus.paid)
      .length;

List<String> get _routeOptions {
  final routes =
      _customers
          .map(
            (customer) =>
                customer.route.trim(),
          )
          .where(
            (route) =>
                route.isNotEmpty,
          )
          .toSet()
          .toList();

  routes.sort();

  return [
    'All Routes',
    ...routes,
  ];
}


List<String> get _salesmanOptions {
  final salesmen =
      _customers
          .map(
            (customer) =>
                customer.salesmanName.trim(),
          )
          .where(
            (name) =>
                name.isNotEmpty,
          )
          .toSet()
          .toList();

  salesmen.sort();

  return [
    'All Salesmen',
    ...salesmen,
  ];
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
      'Content-Type':
          'application/json',

      if (ApiConfig.token != null &&
          ApiConfig.token!.isNotEmpty)
        'Authorization':
            'Bearer ${ApiConfig.token}',
    };

    // ==========================================
    // OUTSTANDING CUSTOMERS
    // ==========================================

    final outstandingResponse =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}'
        '/api/collections/outstanding',
      ),
      headers: headers,
    );

    final outstandingDecoded =
        jsonDecode(
      outstandingResponse.body,
    );

    if (outstandingResponse.statusCode < 200 ||
        outstandingResponse.statusCode >= 300 ||
        outstandingDecoded is! Map ||
        outstandingDecoded['success'] != true) {
      throw Exception(
        outstandingDecoded is Map
            ? (outstandingDecoded['message'] ??
                    'Unable to load outstanding.')
                .toString()
            : 'Unable to load outstanding.',
      );
    }

    // ==========================================
    // COLLECTION HISTORY FOR SELECTED DATE
    // ==========================================

    final historyResponse =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}'
        '/api/collections'
        '?date=${_apiDate(_selectedDate)}',
      ),
      headers: headers,
    );

    final historyDecoded =
        jsonDecode(
      historyResponse.body,
    );

    if (historyResponse.statusCode < 200 ||
        historyResponse.statusCode >= 300 ||
        historyDecoded is! Map ||
        historyDecoded['success'] != true) {
      throw Exception(
        historyDecoded is Map
            ? (historyDecoded['message'] ??
                    'Unable to load collections.')
                .toString()
            : 'Unable to load collections.',
      );
    }

    // ==========================================
    // BUILD CUSTOMER LIST
    // ==========================================

    final List<_CustomerCollection>
        loadedCustomers = [];

    final rawOutstanding =
        outstandingDecoded['data'];

    if (rawOutstanding is List) {
      for (final raw in rawOutstanding) {
        if (raw is! Map) {
          continue;
        }

        final item =
            Map<String, dynamic>.from(
          raw,
        );

        final statusText =
            (item['status'] ?? 'DUE')
                .toString()
                .toUpperCase();

        PaymentStatus status =
            PaymentStatus.due;

        if (statusText == 'PAID') {
          status =
              PaymentStatus.paid;
        } else if (
            statusText == 'PARTIAL') {
          status =
              PaymentStatus.partial;
        }

        loadedCustomers.add(
          _CustomerCollection(
            customerId:
                (item['customerId'] ?? '')
                    .toString(),

            name:
                (item['customerName'] ?? '')
                    .toString(),

            code:
                (item['customerId'] ?? '')
                    .toString(),

            mobile:
                (item['customerMobile'] ?? '')
                    .toString(),

            route:
                (item['route'] ?? '')
                    .toString(),

            salesmanId:
                (item['salesmanId'] ?? '')
                    .toString(),

            salesmanName:
                (item['salesmanName'] ?? '')
                    .toString(),

            amount:
                _asDouble(
                  item['outstanding'],
                ),

            totalCreditSales:
                _asDouble(
                  item[
                    'totalCreditSales'
                  ],
                ),

            totalCollected:
                _asDouble(
                  item[
                    'totalCollected'
                  ],
                ),

            paymentMode:
                (item['lastPaymentMode'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty
                    ? item[
                        'lastPaymentMode'
                      ].toString()
                    : 'Pending',

            status:
                status,

            avatarColor:
                const Color(
                  0xFFE6F2FF,
                ),

            avatarIconColor:
                const Color(
                  0xFF1767D9,
                ),
          ),
        );
      }
    }

    // ==========================================
    // COLLECTION HISTORY
    // ==========================================

    final List<Map<String, dynamic>>
        loadedCollections = [];

    final rawHistory =
        historyDecoded['data'];

    if (rawHistory is List) {
      for (final raw in rawHistory) {
        if (raw is Map) {
          loadedCollections.add(
            Map<String, dynamic>.from(
              raw,
            ),
          );
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _customers
        ..clear()
        ..addAll(
          loadedCustomers,
        );

      _collections
        ..clear()
        ..addAll(
          loadedCollections,
        );

      _isLoading = false;
    });
  } catch (error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;

      _loadError =
          error
              .toString()
              .replaceFirst(
                'Exception: ',
                '',
              );
    });
  }
}

double _asDouble(
  dynamic value,
) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value.toString(),
      ) ??
      0;
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
    padding:
        EdgeInsets.all(30),
    child: Center(
      child:
          CircularProgressIndicator(),
    ),
  )
else if (_loadError.isNotEmpty)
  AppEmptyState(
    icon:
        Icons.cloud_off_outlined,
    title:
        'Unable to load collection',
    message:
        _loadError,
  )
else if (_filteredCustomers.isEmpty)
  const AppEmptyState(
    icon:
        Icons.person_search_outlined,
    title:
        'No outstanding found',
    message:
        'No pending customer collection found.',
  )
else
  ..._filteredCustomers.map(
    _customerCard,
  ),
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
final status =
    switch (customer.status) {
  PaymentStatus.paid =>
    'Paid',

  PaymentStatus.partial =>
    '₹${customer.amount.toStringAsFixed(0)} Due',

  PaymentStatus.due =>
    '₹${customer.amount.toStringAsFixed(0)} Due',
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

 Future<void> _customerAction(
  _CustomerCollection customer,
) async {
  if (
    customer.status ==
    PaymentStatus.paid
  ) {
    await _openLatestReceipt(
      customer,
    );

    return;
  }

  _showCollectionEntry(
    customer,
  );
}
Future<void> _openLatestReceipt(
  _CustomerCollection customer,
) async {
  try {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(
        child:
            CircularProgressIndicator(),
      ),
    );

    final response =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}'
        '/api/collections'
        '?customerId=${Uri.encodeQueryComponent(customer.customerId)}',
      ),
      headers: {
        'Content-Type':
            'application/json',

        if (
          ApiConfig.token != null &&
          ApiConfig.token!.isNotEmpty
        )
          'Authorization':
              'Bearer ${ApiConfig.token}',
      },
    );

    final decoded =
        jsonDecode(
      response.body,
    );

    if (mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();
    }

    if (
      response.statusCode < 200 ||
      response.statusCode >= 300 ||
      decoded is! Map ||
      decoded['success'] != true
    ) {
      throw Exception(
        decoded is Map
            ? (
                decoded[
                      'message'
                    ] ??
                    'Unable to load receipt.'
              ).toString()
            : 'Unable to load receipt.',
      );
    }

    final rawData =
        decoded['data'];

    if (
      rawData is! List ||
      rawData.isEmpty
    ) {
      throw Exception(
        'No receipt found for this customer.',
      );
    }

    Map<String, dynamic>?
        latestReceipt;

    for (final item in rawData) {
      if (item is! Map) {
        continue;
      }

      final receipt =
          Map<String, dynamic>.from(
        item,
      );

      final status =
          (
            receipt['status'] ??
            ''
          )
              .toString()
              .toUpperCase();

      if (
        status != 'POSTED'
      ) {
        continue;
      }

      latestReceipt =
          receipt;

      // API already returns newest first.
      break;
    }

    if (
      latestReceipt == null
    ) {
      throw Exception(
        'No active receipt found for this customer.',
      );
    }

    if (!mounted) {
      return;
    }

    _showReceiptSheet(
      latestReceipt,
    );
  } catch (error) {
    if (!mounted) {
      return;
    }

    // Close loader if still open.
    if (
      Navigator.of(
        context,
        rootNavigator: true,
      ).canPop()
    ) {
      // Do not force-pop the screen itself.
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          error
              .toString()
              .replaceFirst(
                'Exception: ',
                '',
              ),
        ),
      ),
    );
  }
}
void _showReceiptSheet(
  Map<String, dynamic> receipt,
) {
  final receiptNo =
      (
        receipt['receiptNo'] ??
        ''
      ).toString();

  final customerName =
      (
        receipt['customerName'] ??
        ''
      ).toString();

  final customerId =
      (
        receipt['customerId'] ??
        ''
      ).toString();

  final paymentMode =
      (
        receipt['paymentMode'] ??
        ''
      ).toString();

  final route =
      (
        receipt['route'] ??
        ''
      ).toString();

  final salesmanName =
      (
        receipt['salesmanName'] ??
        ''
      ).toString();

  final referenceNo =
      (
        receipt['referenceNo'] ??
        ''
      ).toString();

  final remarks =
      (
        receipt['remarks'] ??
        ''
      ).toString();

  final amount =
      _asDouble(
        receipt['amount'],
      );

  final date =
      DateTime.tryParse(
        (
          receipt[
                'collectionDate'
              ] ??
              ''
        ).toString(),
      );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (
      sheetContext,
    ) {
      return SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.border,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.success
                              .withValues(
                        alpha: .10,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .receipt_long_outlined,
                      color:
                          AppColors.success,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          'Payment Receipt',
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .w900,
                            color:
                                AppColors
                                    .textPrimary,
                          ),
                        ),

                        Text(
                          receiptNo,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color:
                                AppColors
                                    .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.success
                              .withValues(
                        alpha: .10,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: const Text(
                      'PAID',
                      style:
                          TextStyle(
                        color:
                            AppColors.success,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.success
                          .withValues(
                    alpha: .07,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Amount Received',
                      style:
                          TextStyle(
                        color:
                            AppColors
                                .textSecondary,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        color:
                            AppColors.success,
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      paymentMode,
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textSecondary,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              _receiptRow(
                'Customer',
                customerName,
              ),

              _receiptRow(
                'Customer Code',
                customerId,
              ),

              _receiptRow(
                'Receipt No.',
                receiptNo,
              ),

              _receiptRow(
                'Date',
                date == null
                    ? '-'
                    : _formatDate(
                        date.toLocal(),
                      ),
              ),

              _receiptRow(
                'Payment Mode',
                paymentMode,
              ),

              if (
                route.trim().isNotEmpty
              )
                _receiptRow(
                  'Route',
                  route,
                ),

              if (
                salesmanName
                    .trim()
                    .isNotEmpty
              )
                _receiptRow(
                  'Collected By',
                  salesmanName,
                ),

              if (
                referenceNo
                    .trim()
                    .isNotEmpty
              )
                _receiptRow(
                  'Reference No.',
                  referenceNo,
                ),

              if (
                remarks
                    .trim()
                    .isNotEmpty
              )
                _receiptRow(
                  'Remarks',
                  remarks,
                ),

              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                  icon:
                      const Icon(
                    Icons
                        .check_circle_outline,
                  ),
                  label:
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
Widget _receiptRow(
  String label,
  String value,
) {
  return Padding(
    padding:
        const EdgeInsets.symmetric(
      vertical: 7,
    ),
    child: Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style:
                const TextStyle(
              color:
                  AppColors
                      .textSecondary,
              fontSize: 11,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value.isEmpty
                ? '-'
                : value,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              color:
                  AppColors
                      .textPrimary,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
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
  style: const TextStyle(
    color:
        AppColors.textSecondary,
  ),
),

const SizedBox(height: 10),

Container(
  width: double.infinity,
  padding:
      const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color:
        const Color(
          0xFFFFF7E8,
        ),
    borderRadius:
        BorderRadius.circular(
          12,
        ),
  ),
  child: Row(
    children: [
      const Expanded(
        child: Text(
          'Outstanding',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      Text(
        '₹${customer.amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight:
              FontWeight.w900,
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
            double.tryParse(
              amountController
                  .text
                  .trim(),
            ) ??
            0;

        if (amount <= 0) {
          ScaffoldMessenger.of(
            sheetContext,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Enter collection amount.',
              ),
            ),
          );

          return;
        }

        if (amount > customer.amount) {
          ScaffoldMessenger.of(
            sheetContext,
          ).showSnackBar(
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
          final response =
              await http.post(
            Uri.parse(
              '${ApiConfig.baseUrl}'
              '/api/collections',
            ),
            headers: {
              'Content-Type':
                  'application/json',

              if (ApiConfig.token !=
                      null &&
                  ApiConfig.token!
                      .isNotEmpty)
                'Authorization':
                    'Bearer ${ApiConfig.token}',
            },
            body: jsonEncode({
              'customerId':
                  customer.customerId,

              'amount':
                  amount,

              'paymentMode':
                  paymentMode,

              'collectionDate':
                  DateTime.now()
                      .toIso8601String(),

              'referenceNo':
                  '',

              'remarks':
                  '',
            }),
          );

          final decoded =
              jsonDecode(
            response.body,
          );

          if (response.statusCode <
                  200 ||
              response.statusCode >=
                  300 ||
              decoded is! Map ||
              decoded['success'] !=
                  true) {
            throw Exception(
              decoded is Map
                  ? (decoded[
                            'message'
                          ] ??
                          'Unable to save collection.')
                      .toString()
                  : 'Unable to save collection.',
            );
          }

          if (!mounted) {
            return;
          }

       Navigator.pop(
  sheetContext,
);


          final data =
              decoded['data'];

          final receiptNo =
              data is Map
                  ? (data[
                            'receiptNo'
                          ] ??
                          '')
                      .toString()
                  : '';

          ScaffoldMessenger.of(
            this.context,
          ).showSnackBar(
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

          ScaffoldMessenger.of(
            this.context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                error
                    .toString()
                    .replaceFirst(
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
             items:
    _routeOptions
        .map(
          (item) =>
              DropdownMenuItem<String>(
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
         items:
    _salesmanOptions
        .map(
          (item) =>
              DropdownMenuItem<String>(
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

String _apiDate(
  DateTime date,
) {
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

  // CURRENT OUTSTANDING
  final double amount;

  final double totalCreditSales;

  final double totalCollected;

  final String paymentMode;

  final PaymentStatus status;

  final Color avatarColor;

  final Color avatarIconColor;
}
