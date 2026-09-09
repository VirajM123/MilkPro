import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/customer_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  final CustomerModel customer;

  @override
  State<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState
    extends State<CustomerDetailScreen> {
  bool _loadingOrders = true;
  bool _loadingPayments = true;
  bool _loadingLedger = true;

  String _ordersError = '';
  String _paymentsError = '';
  String _ledgerError = '';

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _ledgerTransactions = [];

  double _ledgerDebit = 0;
  double _ledgerCredit = 0;
  double _ledgerBalance = 0;

  CustomerModel get customer => widget.customer;

  @override
  void initState() {
    super.initState();

    _loadAll();
  }

  Future<void> _loadAll() async {
    if (customer.customerId.trim().isEmpty) {
      setState(() {
        _loadingOrders = false;
        _loadingPayments = false;
        _loadingLedger = false;

        _ordersError =
            'Customer ID is missing.';
        _paymentsError =
            'Customer ID is missing.';
        _ledgerError =
            'Customer ID is missing.';
      });

      return;
    }

    await Future.wait([
      _loadOrders(),
      _loadPayments(),
      _loadLedger(),
    ]);
  }

  Map<String, String> get _headers => {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer ${ApiConfig.token}',
      };

  // =====================================================
  // ORDERS / SALES
  // =====================================================

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _loadingOrders = true;
        _ordersError = '';
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.customerSales(
            customer.customerId,
          ),
        ),
        headers: _headers,
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        final records =
            data['data'] as List<dynamic>? ??
                [];

        setState(() {
          _orders = records
              .whereType<Map<String, dynamic>>()
              .toList();

          _loadingOrders = false;
        });
      } else {
        setState(() {
          _ordersError =
              data['message']?.toString() ??
                  'Unable to load customer orders.';

          _loadingOrders = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _ordersError =
            'Unable to connect to backend.';

        _loadingOrders = false;
      });
    }
  }

  // =====================================================
  // PAYMENTS / COLLECTIONS
  // =====================================================

  Future<void> _loadPayments() async {
    if (mounted) {
      setState(() {
        _loadingPayments = true;
        _paymentsError = '';
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.customerCollections(
            customer.customerId,
          ),
        ),
        headers: _headers,
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        final records =
            data['data'] as List<dynamic>? ??
                [];

        setState(() {
          _payments = records
              .whereType<Map<String, dynamic>>()
              .toList();

          _loadingPayments = false;
        });
      } else {
        setState(() {
          _paymentsError =
              data['message']?.toString() ??
                  'Unable to load customer payments.';

          _loadingPayments = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _paymentsError =
            'Unable to connect to backend.';

        _loadingPayments = false;
      });
    }
  }

  // =====================================================
  // LEDGER
  // =====================================================

  Future<void> _loadLedger() async {
    if (mounted) {
      setState(() {
        _loadingLedger = true;
        _ledgerError = '';
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.customerLedger(
            customer.customerId,
          ),
        ),
        headers: _headers,
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        final ledgerData =
            data['data'];

        if (ledgerData
            is Map<String, dynamic>) {
          final records =
              ledgerData['transactions']
                      as List<dynamic>? ??
                  [];

          setState(() {
            _ledgerDebit =
                _number(
              ledgerData['totalDebit'],
            );

            _ledgerCredit =
                _number(
              ledgerData['totalCredit'],
            );

            _ledgerBalance =
                _number(
              ledgerData['balance'],
            );

            _ledgerTransactions = records
                .whereType<
                    Map<String, dynamic>>()
                .toList();

            _loadingLedger = false;
          });
        } else {
          setState(() {
            _ledgerError =
                'Invalid ledger response.';

            _loadingLedger = false;
          });
        }
      } else {
        setState(() {
          _ledgerError =
              data['message']?.toString() ??
                  'Unable to load customer ledger.';

          _loadingLedger = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _ledgerError =
            'Unable to connect to backend.';

        _loadingLedger = false;
      });
    }
  }

  double _number(dynamic value) {
    return double.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: PremiumAppBar(
          title: customer.name,
          subtitle:
              '${customer.route} • ${customer.mobile}',
        ),
        body: Column(
          children: [
            Material(
              color: AppColors.surface,
              child: TabBar(
                isScrollable: true,
                tabAlignment:
                    TabAlignment.start,
                tabs: const [
                  Tab(
                    text: 'Overview',
                  ),
                  Tab(
                    text: 'Orders',
                  ),
                  Tab(
                    text: 'Payments',
                  ),
                  Tab(
                    text: 'Ledger',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _overview(),
                  _ordersTab(),
                  _paymentsTab(),
                  _ledgerTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // OVERVIEW
  // =====================================================

  Widget _overview() {
    final initial =
        customer.name.trim().isNotEmpty
            ? customer.name
                .trim()[0]
                .toUpperCase()
            : '?';

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor:
                        AppColors.primarySoft,
                    foregroundColor:
                        AppColors.primary,
                    child: Text(
                      initial,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
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
                        Text(
                          customer.name,
                          style:
                              Theme.of(
                            context,
                          )
                                  .textTheme
                                  .titleMedium,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        StatusChip(
                          label:
                              customer.isActive
                                  ? 'Active'
                                  : 'Inactive',
                          color:
                              customer.isActive
                                  ? AppColors
                                      .success
                                  : AppColors
                                      .textSecondary,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .end,
                    children: [
                      Text(
                        '₹${customer.balance.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          color: AppColors
                              .warning,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Opening Balance',
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const AppSectionTitle(
            title:
                'Customer Information',
          ),

          const SizedBox(
            height: 10,
          ),

          Card(
            child: Column(
              children: [
                if (customer
                    .customerId.isNotEmpty)
                  _info(
                    Icons
                        .badge_outlined,
                    'Customer ID',
                    customer
                        .customerId,
                  ),
                if (customer
                    .customerId.isNotEmpty)
                  const Divider(),

                _info(
                  Icons
                      .phone_outlined,
                  'Mobile',
                  customer.mobile,
                ),

                const Divider(),

                _info(
                  Icons
                      .route_outlined,
                  'Route',
                  customer.route,
                ),

                const Divider(),

                _info(
                  Icons
                      .account_balance_wallet_outlined,
                  'Opening Balance',
                  '₹${customer.balance.toStringAsFixed(2)}',
                ),

                const Divider(),

                _info(
                  Icons
                      .receipt_long_outlined,
                  'Current Ledger Balance',
                  _loadingLedger
                      ? 'Loading...'
                      : '₹${_ledgerBalance.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: () =>
                      _message(
                    'Calling ${customer.mobile}',
                  ),
                  icon: const Icon(
                    Icons
                        .phone_outlined,
                  ),
                  label:
                      const Text(
                    'Call',
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed: () =>
                      _message(
                    'Open collection screen for ${customer.name}.',
                  ),
                  icon: const Icon(
                    Icons
                        .payments_outlined,
                  ),
                  label:
                      const Text(
                    'Collection',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ORDERS
  // =====================================================

  Widget _ordersTab() {
    if (_loadingOrders) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_ordersError.isNotEmpty) {
      return _errorState(
        message: _ordersError,
        onRetry: _loadOrders,
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon:
              Icons.shopping_bag_outlined,
          title:
              'No orders available',
          message:
              'No sales have been recorded for this customer.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding:
            const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          height: 10,
        ),
        itemBuilder:
            (context, index) {
          final sale =
              _orders[index];

          final products =
              sale['products']
                      as List<dynamic>? ??
                  [];

          final total =
              _number(
            sale['grandTotal'],
          );

          final quantity =
              _number(
            sale['totalQuantity'],
          );

          final status =
              sale['status']
                      ?.toString() ??
                  '';

          return Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sale['saleNo']
                                  ?.toString() ??
                              'Sale',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      StatusChip(
                        label:
                            status.isEmpty
                                ? 'POSTED'
                                : status,
                        color:
                            status ==
                                    'CANCELLED'
                                ? AppColors
                                    .error
                                : AppColors
                                    .success,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    _formatDate(
                      sale['saleDate'],
                    ),
                    style:
                        const TextStyle(
                      color: AppColors
                          .textSecondary,
                      fontSize: 11,
                    ),
                  ),

                  const Divider(
                    height: 22,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _smallInfo(
                          'Items',
                          '${products.length}',
                        ),
                      ),
                      Expanded(
                        child:
                            _smallInfo(
                          'Qty',
                          quantity
                              .toStringAsFixed(
                            quantity ==
                                    quantity
                                        .roundToDouble()
                                ? 0
                                : 2,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            _smallInfo(
                          'Mode',
                          sale['paymentMode']
                                  ?.toString() ??
                              '-',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Align(
                    alignment:
                        Alignment
                            .centerRight,
                    child: Text(
                      '₹${total.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        color:
                            AppColors.primary,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // PAYMENTS
  // =====================================================

  Widget _paymentsTab() {
    if (_loadingPayments) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_paymentsError.isNotEmpty) {
      return _errorState(
        message: _paymentsError,
        onRetry: _loadPayments,
      );
    }

    if (_payments.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon:
              Icons.payments_outlined,
          title:
              'No payment history',
          message:
              'No collections have been recorded for this customer.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView.separated(
        padding:
            const EdgeInsets.all(16),
        itemCount:
            _payments.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          height: 10,
        ),
        itemBuilder:
            (context, index) {
          final payment =
              _payments[index];

          final amount =
              _number(
            payment['amount'],
          );

          final status =
              payment['status']
                      ?.toString() ??
                  'POSTED';

          return Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          payment['receiptNo']
                                  ?.toString() ??
                              payment[
                                      'collectionId']
                                  ?.toString() ??
                              'Receipt',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                          color: AppColors
                              .success,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    _formatDate(
                      payment[
                          'collectionDate'],
                    ),
                    style:
                        const TextStyle(
                      color: AppColors
                          .textSecondary,
                      fontSize: 11,
                    ),
                  ),

                  const Divider(
                    height: 20,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _smallInfo(
                          'Mode',
                          payment['paymentMode']
                                  ?.toString() ??
                              '-',
                        ),
                      ),
                      Expanded(
                        child:
                            _smallInfo(
                          'Reference',
                          payment['referenceNo']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? payment[
                                      'referenceNo']
                                  .toString()
                              : '-',
                        ),
                      ),
                      Expanded(
                        child:
                            _smallInfo(
                          'Status',
                          status,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // LEDGER
  // =====================================================

  Widget _ledgerTab() {
    if (_loadingLedger) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_ledgerError.isNotEmpty) {
      return _errorState(
        message: _ledgerError,
        onRetry: _loadLedger,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLedger,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child:
                    _ledgerSummary(
                  'Debit',
                  _ledgerDebit,
                  AppColors.warning,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child:
                    _ledgerSummary(
                  'Credit',
                  _ledgerCredit,
                  AppColors.success,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child:
                    _ledgerSummary(
                  'Balance',
                  _ledgerBalance,
                  AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          if (_ledgerTransactions
              .isEmpty)
            const Padding(
              padding:
                  EdgeInsets.only(
                top: 80,
              ),
              child: AppEmptyState(
                icon:
                    Icons.menu_book_outlined,
                title:
                    'No ledger entries',
                message:
                    'Sales and collections will appear here.',
              ),
            )
          else
            ..._ledgerTransactions
                .map(
              (entry) =>
                  _ledgerEntry(
                entry,
              ),
            ),
        ],
      ),
    );
  }

  Widget _ledgerEntry(
    Map<String, dynamic> entry,
  ) {
    final debit =
        _number(
      entry['debit'],
    );

    final credit =
        _number(
      entry['credit'],
    );

    final balance =
        _number(
      entry['balance'],
    );

    final isSale =
        entry['type']
                ?.toString()
                .toUpperCase() ==
            'SALE';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor:
                  isSale
                      ? AppColors
                          .primarySoft
                      : const Color(
                          0xFFE8F8EE,
                        ),
              foregroundColor:
                  isSale
                      ? AppColors.primary
                      : AppColors.success,
              child: Icon(
                isSale
                    ? Icons
                        .receipt_long_outlined
                    : Icons
                        .payments_outlined,
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
                  Text(
                    entry['title']
                            ?.toString() ??
                        entry['type']
                            ?.toString() ??
                        'Transaction',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    '${entry['referenceNo'] ?? ''} • ${_formatDate(entry['date'])}',
                    style:
                        const TextStyle(
                      color: AppColors
                          .textSecondary,
                      fontSize: 10.5,
                    ),
                  ),

                  if (entry['paymentMode']
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true) ...[
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      entry[
                              'paymentMode']
                          .toString(),
                      style:
                          const TextStyle(
                        color: AppColors
                            .textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
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
                if (debit > 0)
                  Text(
                    'Dr ₹${debit.toStringAsFixed(2)}',
                    style:
                        const TextStyle(
                      color: AppColors
                          .warning,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                if (credit > 0)
                  Text(
                    'Cr ₹${credit.toStringAsFixed(2)}',
                    style:
                        const TextStyle(
                      color: AppColors
                          .success,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Bal ₹${balance.toStringAsFixed(2)}',
                  style:
                      const TextStyle(
                    color: AppColors
                        .textSecondary,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // COMMON WIDGETS
  // =====================================================

  Widget _ledgerSummary(
    String label,
    double amount,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: .08,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: .18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              color: AppColors
                  .textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color:
                AppColors.textSecondary,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color:
                AppColors.textPrimary,
            fontSize: 11,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _info(
    IconData icon,
    String label,
    String value,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            AppColors.primary,
      ),
      title: Text(
        label,
        style:
            const TextStyle(
          color:
              AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
      subtitle: Text(
        value.trim().isEmpty
            ? '-'
            : value,
        style:
            const TextStyle(
          color:
              AppColors.textPrimary,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Widget _errorState({
    required String message,
    required Future<void>
        Function() onRetry,
  }) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 42,
              color:
                  AppColors.error,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 14,
            ),
            OutlinedButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(
                Icons
                    .refresh_rounded,
              ),
              label:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    final date =
        DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  void _message(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }
}