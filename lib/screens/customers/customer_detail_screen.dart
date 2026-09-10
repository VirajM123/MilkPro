import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../common/access_denied_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final CustomerModel customer;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
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

  // ============================================================
  // CUSTOMER SALES SUMMARY
  // ============================================================

  double _totalSales = 0;
  double _totalPaidAtBilling = 0;
  double _totalCollections = 0;
  double _totalReceived = 0;

  // ============================================================
  // PAYMENT BREAKUP
  // ============================================================

  double _cashReceived = 0;
  double _onlineReceived = 0;
  double _bankReceived = 0;
  double _otherReceived = 0;

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

        _ordersError = 'Customer ID is missing.';
        _paymentsError = 'Customer ID is missing.';
        _ledgerError = 'Customer ID is missing.';
      });

      return;
    }

    await Future.wait([_loadOrders(), _loadPayments(), _loadLedger()]);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${ApiConfig.token}',
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
        Uri.parse(ApiConfig.customerSales(customer.customerId)),
        headers: _headers,
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final records = data['data'] as List<dynamic>? ?? [];

        setState(() {
          _orders = records.whereType<Map<String, dynamic>>().toList();

          _loadingOrders = false;
        });
      } else {
        setState(() {
          _ordersError =
              data['message']?.toString() ?? 'Unable to load customer orders.';

          _loadingOrders = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _ordersError = 'Unable to connect to backend.';

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
        Uri.parse(ApiConfig.customerCollections(customer.customerId)),
        headers: _headers,
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final records = data['data'] as List<dynamic>? ?? [];

        setState(() {
          _payments = records.whereType<Map<String, dynamic>>().toList();

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
        _paymentsError = 'Unable to connect to backend.';

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
        Uri.parse(ApiConfig.customerLedger(customer.customerId)),
        headers: _headers,
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final ledgerData = data['data'];

        if (ledgerData is Map<String, dynamic>) {
          final records = ledgerData['transactions'] as List<dynamic>? ?? [];

          setState(() {
            _ledgerDebit = _number(ledgerData['totalDebit']);

            _ledgerCredit = _number(ledgerData['totalCredit']);

            _ledgerBalance = _number(ledgerData['balance']);

            // ============================================================
            // CUSTOMER SALES SUMMARY
            // ============================================================

            _totalSales = _number(ledgerData['totalSales']);

            _totalPaidAtBilling = _number(ledgerData['totalPaidAtBilling']);

            _totalCollections = _number(ledgerData['totalCollections']);

            _totalReceived = _number(ledgerData['totalReceived']);

            // ============================================================
            // PAYMENT BREAKUP
            // ============================================================

            final dynamic rawBreakup = ledgerData['paymentBreakup'];

            if (rawBreakup is Map) {
              final breakup = Map<String, dynamic>.from(rawBreakup);

              _cashReceived = _number(breakup['cash']);

              _onlineReceived = _number(breakup['online'] ?? breakup['upi']);

              _bankReceived = _number(breakup['bank']);

              _otherReceived = _number(breakup['other']);
            } else {
              _cashReceived = 0;
              _onlineReceived = 0;
              _bankReceived = 0;
              _otherReceived = 0;
            }

            _ledgerTransactions = records
                .whereType<Map<String, dynamic>>()
                .toList();

            _loadingLedger = false;
          });
        } else {
          setState(() {
            _ledgerError = 'Invalid ledger response.';

            _loadingLedger = false;
          });
        }
      } else {
        setState(() {
          _ledgerError =
              data['message']?.toString() ?? 'Unable to load customer ledger.';

          _loadingLedger = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _ledgerError = 'Unable to connect to backend.';

        _loadingLedger = false;
      });
    }
  }

  double _number(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!UiSession.instance.can(AppPermission.customersView)) {
      return const AccessDeniedScreen();
    }

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
    final initial = customer.name.trim().isNotEmpty
        ? customer.name.trim()[0].toUpperCase()
        : '?';

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
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
                      initial,
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
                        'Opening Balance',
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
                if (customer.customerId.isNotEmpty)
                  _info(
                    Icons.badge_outlined,
                    'Customer ID',
                    customer.customerId,
                  ),
                if (customer.customerId.isNotEmpty) const Divider(),

                _info(Icons.phone_outlined, 'Mobile', customer.mobile),

                const Divider(),

                _info(Icons.route_outlined, 'Route', customer.route),

                const Divider(),

                _info(
                  Icons.account_balance_wallet_outlined,
                  'Opening Balance',
                  '₹${customer.balance.toStringAsFixed(2)}',
                ),

                const Divider(),

                _info(
                  Icons.receipt_long_outlined,
                  'Current Ledger Balance',
                  _loadingLedger
                      ? 'Loading...'
                      : '₹${_ledgerBalance.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ============================================================
          // ACCOUNT SUMMARY
          // ============================================================
          const AppSectionTitle(title: 'Account Summary'),

          const SizedBox(height: 10),

          if (_loadingLedger)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = (constraints.maxWidth - 10) / 2;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: width,
                      child: _accountSummaryCard(
                        label: 'Total Sales',
                        value: _totalSales,
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.primary,
                      ),
                    ),

                    SizedBox(
                      width: width,
                      child: _accountSummaryCard(
                        label: 'Total Received',
                        value: _totalReceived,
                        icon: Icons.payments_outlined,
                        color: AppColors.success,
                      ),
                    ),

                    SizedBox(
                      width: width,
                      child: _accountSummaryCard(
                        label: 'Outstanding',
                        value: _ledgerBalance,
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.warning,
                      ),
                    ),

                    SizedBox(
                      width: width,
                      child: _accountSummaryCard(
                        label: 'Collections',
                        value: _totalCollections,
                        icon: Icons.south_west_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 12),

          if (!_loadingLedger) _paymentSummaryCard(),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _message('Calling ${customer.mobile}'),
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _message('Open collection screen for ${customer.name}.'),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Collection'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountSummaryCard({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),

            const SizedBox(height: 10),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              '₹${value.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentSummaryCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),

                SizedBox(width: 7),

                Text(
                  'Payment Breakup',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _paymentSummaryItem('Cash', _cashReceived)),

                const SizedBox(width: 8),

                Expanded(child: _paymentSummaryItem('Online', _onlineReceived)),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(child: _paymentSummaryItem('Bank', _bankReceived)),

                const SizedBox(width: 8),

                Expanded(child: _paymentSummaryItem('Other', _otherReceived)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentSummaryItem(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9.5,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            '₹${value.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_ordersError.isNotEmpty) {
      return _errorState(message: _ordersError, onRetry: _loadOrders);
    }

    if (_orders.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'No orders available',
          message: 'No sales have been recorded for this customer.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _customerOrderCard(_orders[index]);
        },
      ),
    );
  }

  Widget _customerOrderCard(Map<String, dynamic> sale) {
    final List<Map<String, dynamic>> products = sale['products'] is List
        ? (sale['products'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    final List<Map<String, dynamic>> payments = sale['payments'] is List
        ? (sale['payments'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    final double total = _number(sale['grandTotal']);

    final double paid = _number(sale['paidAmount']);

    final double outstanding = _number(sale['outstandingAmount']);

    final String paymentStatus = (sale['paymentStatus'] ?? '').toString();

    final String salesmanName = (sale['salesmanName'] ?? '').toString();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // BILL HEADER
            // ==================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (sale['saleNo'] ?? 'Sale').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        _formatDate(sale['saleDate']),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                StatusChip(
                  label: paymentStatus.trim().isEmpty ? 'SALE' : paymentStatus,
                  color: paymentStatus.toUpperCase() == 'PAID'
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),

            // ==================================================
            // SALESMAN
            // ==================================================
            if (salesmanName.trim().isNotEmpty) ...[
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),

                    const SizedBox(width: 6),

                    const Text(
                      'Salesman',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),

                    const Spacer(),

                    Flexible(
                      child: Text(
                        salesmanName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================================================
            // PRODUCTS
            // ==================================================
            if (products.isNotEmpty) ...[
              const Divider(height: 22),

              ...products.map((product) {
                final String name = (product['productName'] ?? 'Product')
                    .toString();

                final String variant = (product['variant'] ?? '').toString();

                final String unit = (product['unit'] ?? '').toString();

                final double quantity = _number(product['quantity']);

                final double rate = _number(product['rate']);

                final double amount = _number(product['amount']);

                final String productName = variant.trim().isEmpty
                    ? name
                    : '$name • $variant';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              '${_qtyText(quantity)}'
                              '${unit.trim().isEmpty ? '' : ' $unit'}'
                              ' × ₹${rate.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const Divider(height: 18),

            _detailAmountRow('Bill Total', total, strong: true),

            if (payments.isNotEmpty) ...[
              const SizedBox(height: 6),

              ...payments.map((payment) {
                final String mode =
                    (payment['mode'] ?? payment['paymentMode'] ?? 'Payment')
                        .toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _detailAmountRow(
                    mode,
                    _number(payment['amount']),
                    valueColor: AppColors.success,
                  ),
                );
              }),
            ],

            const SizedBox(height: 5),

            _detailAmountRow('Received', paid, valueColor: AppColors.success),

            const SizedBox(height: 5),

            _detailAmountRow(
              'Outstanding',
              outstanding,
              strong: true,
              valueColor: outstanding > 0
                  ? AppColors.warning
                  : AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PAYMENTS
  // =====================================================

  Widget _paymentsTab() {
    if (_loadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentsError.isNotEmpty) {
      return _errorState(message: _paymentsError, onRetry: _loadPayments);
    }

    if (_payments.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.payments_outlined,
          title: 'No payment history',
          message: 'No collections have been recorded for this customer.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final payment = _payments[index];

          final double amount = _number(payment['amount']);

          final String status = payment['status']?.toString() ?? 'POSTED';

          final String salesmanName = (payment['salesmanName'] ?? '')
              .toString();

          final List<Map<String, dynamic>> allocations =
              payment['allocations'] is List
              ? (payment['allocations'] as List)
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList()
              : <Map<String, dynamic>>[];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          payment['receiptNo']?.toString() ??
                              payment['collectionId']?.toString() ??
                              'Receipt',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _formatDate(payment['collectionDate']),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),

                  const Divider(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _smallInfo(
                          'Mode',
                          payment['paymentMode']?.toString() ?? '-',
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(child: _smallInfo('Status', status)),
                    ],
                  ),

                  if (salesmanName.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),

                    _paymentDetailRow('Collected By', salesmanName),
                  ],

                  if ((payment['referenceNo'] ?? '')
                      .toString()
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 6),

                    _paymentDetailRow(
                      'Reference',
                      payment['referenceNo'].toString(),
                    ),
                  ],

                  if (allocations.isNotEmpty) ...[
                    const Divider(height: 22),

                    const Text(
                      'Applied Bills',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ...allocations.map((allocation) {
                      final String saleNo =
                          (allocation['saleNo'] ?? allocation['saleId'] ?? '-')
                              .toString();

                      final double applied = _number(
                        allocation['amountApplied'],
                      );

                      return _detailAmountRow(
                        saleNo,
                        applied,
                        valueColor: AppColors.success,
                      );
                    }),
                  ],
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_ledgerError.isNotEmpty) {
      return _errorState(message: _ledgerError, onRetry: _loadLedger);
    }

    return RefreshIndicator(
      onRefresh: _loadLedger,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = (constraints.maxWidth - 10) / 2;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width,
                    child: _ledgerSummary(
                      'Total Sales',
                      _totalSales,
                      AppColors.primary,
                    ),
                  ),

                  SizedBox(
                    width: width,
                    child: _ledgerSummary(
                      'Total Received',
                      _totalReceived,
                      AppColors.success,
                    ),
                  ),

                  SizedBox(
                    width: width,
                    child: _ledgerSummary(
                      'Outstanding',
                      _ledgerBalance,
                      AppColors.warning,
                    ),
                  ),

                  SizedBox(
                    width: width,
                    child: _ledgerSummary(
                      'Collections',
                      _totalCollections,
                      AppColors.success,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          _paymentSummaryCard(),

          const SizedBox(height: 16),

          if (_ledgerTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: AppEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No ledger entries',
                message: 'Sales and collections will appear here.',
              ),
            )
          else
            ..._ledgerTransactions.map((entry) => _ledgerEntry(entry)),
        ],
      ),
    );
  }

 Widget _ledgerEntry(
  Map<String, dynamic> entry,
) {
  final String type =
      (entry['type'] ?? '')
          .toString()
          .toUpperCase();

  if (type == 'SALE') {
    return _customerLedgerSale(
      entry,
    );
  }

  if (type == 'COLLECTION') {
    return _customerLedgerCollection(
      entry,
    );
  }

  return const SizedBox.shrink();
}
Widget _customerLedgerSale(
  Map<String, dynamic> entry,
) {
  final List<Map<String, dynamic>> products =
      entry['products'] is List
          ? (entry['products'] as List)
              .whereType<Map>()
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList()
          : <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> payments =
      entry['payments'] is List
          ? (entry['payments'] as List)
              .whereType<Map>()
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList()
          : <Map<String, dynamic>>[];

  final String salesman =
      (entry['salesmanName'] ?? '')
          .toString();

  final double billAmount =
      _number(
    entry['billAmount'] ??
        entry['amount'],
  );

  final double paid =
      _number(
    entry['paidAmount'],
  );

  final double outstanding =
      _number(
    entry['outstandingAmount'],
  );

  final double running =
      _number(
    entry['balance'],
  );

  return Card(
    margin:
        const EdgeInsets.only(
      bottom: 12,
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
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primarySoft,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Icon(
                  Icons
                      .receipt_long_outlined,
                  color:
                      AppColors.primary,
                  size: 19,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      (entry['referenceNo'] ??
                              'Sale')
                          .toString(),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      _formatDate(
                        entry['date'],
                      ),
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textSecondary,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (salesman
              .trim()
              .isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            _paymentDetailRow(
              'Salesman',
              salesman,
            ),
          ],

          if (products.isNotEmpty) ...[
            const Divider(
              height: 22,
            ),

            ...products.map(
              (product) {
                final double quantity =
                    _number(
                  product['quantity'],
                );

                final double rate =
                    _number(
                  product['rate'],
                );

                final double amount =
                    _number(
                  product['amount'],
                );

                final String name =
                    (product['productName'] ??
                            'Product')
                        .toString();

                final String unit =
                    (product['unit'] ?? '')
                        .toString();

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 10.5,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            const SizedBox(
                              height: 2,
                            ),

                            Text(
                              '${_qtyText(quantity)}'
                              '${unit.trim().isEmpty ? '' : ' $unit'}'
                              ' × ₹${rate.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(
                                color:
                                    AppColors
                                        .textSecondary,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const Divider(
            height: 20,
          ),

          _detailAmountRow(
            'Bill Total',
            billAmount,
            strong: true,
          ),

          if (payments.isNotEmpty)
            ...payments.map(
              (payment) =>
                  _detailAmountRow(
                (payment['mode'] ??
                        payment[
                            'paymentMode'] ??
                        'Payment')
                    .toString(),
                _number(
                  payment['amount'],
                ),
                valueColor:
                    AppColors.success,
              ),
            ),

          _detailAmountRow(
            'Received',
            paid,
            valueColor:
                AppColors.success,
          ),

          _detailAmountRow(
            'Bill Outstanding',
            outstanding,
            strong: true,
            valueColor:
                outstanding > 0
                    ? AppColors.warning
                    : AppColors.success,
          ),

          const Divider(
            height: 20,
          ),

          _detailAmountRow(
            'Running Outstanding',
            running,
            strong: true,
            valueColor:
                running > 0
                    ? AppColors.warning
                    : AppColors.success,
          ),
        ],
      ),
    ),
  );
}
Widget _customerLedgerCollection(
  Map<String, dynamic> entry,
) {
  final List<Map<String, dynamic>> allocations =
      entry['allocations'] is List
          ? (entry['allocations'] as List)
              .whereType<Map>()
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList()
          : <Map<String, dynamic>>[];

  final double amount =
      _number(
    entry['credit'],
  );

  final double running =
      _number(
    entry['balance'],
  );

  final String salesman =
      (entry['salesmanName'] ?? '')
          .toString();

  return Card(
    margin:
        const EdgeInsets.only(
      bottom: 12,
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
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration:
                    BoxDecoration(
                  color: const Color(
                    0xFFE8F8EE,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Icon(
                  Icons
                      .payments_outlined,
                  color:
                      AppColors.success,
                  size: 19,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      (entry['referenceNo'] ??
                              'Payment Received')
                          .toString(),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),

                    Text(
                      _formatDate(
                        entry['date'],
                      ),
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textSecondary,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                '₹${amount.toStringAsFixed(2)}',
                style:
                    const TextStyle(
                  color:
                      AppColors.success,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          _paymentDetailRow(
            'Mode',
            (entry['paymentMode'] ??
                    '-')
                .toString(),
          ),

          if (salesman
              .trim()
              .isNotEmpty) ...[
            const SizedBox(
              height: 6,
            ),

            _paymentDetailRow(
              'Collected By',
              salesman,
            ),
          ],

          if (allocations.isNotEmpty) ...[
            const Divider(
              height: 22,
            ),

            const Text(
              'Applied Bills',
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            ...allocations.map(
              (allocation) {
                final String bill =
                    (
                      allocation['saleNo'] ??
                      allocation['saleId'] ??
                      '-'
                    ).toString();

                return _detailAmountRow(
                  bill,
                  _number(
                    allocation[
                        'amountApplied'],
                  ),
                  valueColor:
                      AppColors.success,
                );
              },
            ),
          ],

          const Divider(
            height: 20,
          ),

          _detailAmountRow(
            'Outstanding After Payment',
            running,
            strong: true,
            valueColor:
                running > 0
                    ? AppColors.warning
                    : AppColors.success,
          ),
        ],
      ),
    ),
  );
}

  Widget _detailAmountRow(
    String label,
    double amount, {
    bool strong = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: strong ? 11.5 : 10.5,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: strong ? 12 : 11,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _qtyText(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  Widget _paymentDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
  // =====================================================
  // COMMON WIDGETS
  // =====================================================

  Widget _ledgerSummary(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      subtitle: Text(
        value.trim().isEmpty ? '-' : value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _errorState({
    required String message,
    required Future<void> Function() onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.error,
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
