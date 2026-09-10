import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../common/access_denied_screen.dart';
import '../common/simple_screen_widgets.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  String _ledgerType = 'customer';

  String? _partyId;

  final List<_LedgerParty> _parties = [];

  final List<_LedgerEntry> _entries = [];

  bool _isLoading = false;

  String _loadError = '';

  double _totalDebit = 0;
  double _totalCredit = 0;
  double _balance = 0;

  // ============================================================
  // CUSTOMER LEDGER SUMMARY
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

  String _partyName = '';
  String _partyMobile = '';
  String _partyRoute = '';

  @override
  void initState() {
    super.initState();

    _loadParties();
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',

      if (ApiConfig.token != null && ApiConfig.token!.isNotEmpty)
        'Authorization': 'Bearer ${ApiConfig.token}',
    };
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
  List<Map<String, dynamic>> _mapList(
  dynamic value,
) {
  if (value is! List) {
    return <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map(
        (item) =>
            Map<String, dynamic>.from(
          item,
        ),
      )
      .toList();
}

  Future<void> _loadParties() async {
    setState(() {
      _isLoading = true;

      _loadError = '';

      _partyId = null;

      _entries.clear();
    });

    try {
      final endpoint = _ledgerType == 'customer'
          ? '/api/customers'
          : '/api/suppliers';

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _headers,
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded is! Map ||
          decoded['success'] != true) {
        throw Exception(
          decoded is Map
              ? (decoded['message'] ?? 'Unable to load parties.').toString()
              : 'Unable to load parties.',
        );
      }

      final rawData = decoded['data'];

      final List<_LedgerParty> loaded = [];

      if (rawData is List) {
        for (final item in rawData) {
          if (item is! Map) {
            continue;
          }

          final map = Map<String, dynamic>.from(item);

          if (_ledgerType == 'customer') {
            final id = (map['customerId'] ?? '').toString();

            final name = (map['name'] ?? '').toString();

            if (id.isNotEmpty) {
              loaded.add(_LedgerParty(id: id, name: name));
            }
          } else {
            final id = (map['supplierId'] ?? '').toString();

            final name = (map['supplierName'] ?? '').toString();

            if (id.isNotEmpty) {
              loaded.add(_LedgerParty(id: id, name: name));
            }
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _parties
          ..clear()
          ..addAll(loaded);

        _partyId = loaded.isNotEmpty ? loaded.first.id : null;
      });

      if (_partyId != null) {
        await _loadLedger();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<void> _loadLedger() async {
    final partyId = _partyId;

    if (partyId == null) {
      return;
    }

    setState(() {
      _isLoading = true;

      _loadError = '';
    });

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}'
        '/api/ledger'
        '?type=$_ledgerType'
        '&partyId=$partyId',
      );

      final response = await http.get(uri, headers: _headers);

      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded is! Map ||
          decoded['success'] != true) {
        throw Exception(
          decoded is Map
              ? (decoded['message'] ?? 'Unable to load ledger.').toString()
              : 'Unable to load ledger.',
        );
      }

      final rawData = decoded['data'];

      if (rawData is! Map) {
        throw Exception('Invalid ledger response.');
      }

      final data = Map<String, dynamic>.from(rawData);

      final rawTransactions = data['transactions'];

      final List<_LedgerEntry> loadedEntries = [];

      if (rawTransactions is List) {
        for (final item in rawTransactions) {
          if (item is! Map) {
            continue;
          }

          final map = Map<String, dynamic>.from(item);

          loadedEntries.add(
  _LedgerEntry(
  id: (map['id'] ?? '').toString(),

  referenceNo:
      (map['referenceNo'] ?? '').toString(),

  title:
      (map['title'] ?? '').toString(),

  type:
      (map['type'] ?? '').toString(),

  date: DateTime.tryParse(
    (map['date'] ?? '').toString(),
  ),

  amount:
      _asDouble(map['amount']),

  debit:
      _asDouble(map['debit']),

  credit:
      _asDouble(map['credit']),

  balance:
      _asDouble(map['balance']),

  billAmount:
      _asDouble(map['billAmount']),

  paidAmount:
      _asDouble(map['paidAmount']),

  outstandingAmount:
      _asDouble(
    map['outstandingAmount'],
  ),

  totalQuantity:
      _asDouble(
    map['totalQuantity'],
  ),

  paymentMode:
      (map['paymentMode'] ?? '')
          .toString(),

  paymentStatus:
      (map['paymentStatus'] ?? '')
          .toString(),

  reference:
      (map['reference'] ?? '')
          .toString(),

  salesmanId:
      (map['salesmanId'] ?? '')
          .toString(),

  salesmanName:
      (map['salesmanName'] ?? '')
          .toString(),

  products:
      _mapList(
    map['products'],
  ),

  payments:
      _mapList(
    map['payments'],
  ),

  allocations:
      _mapList(
    map['allocations'],
  ),
)
          );
        }
      }

      if (!mounted) {
        return;
      }

     setState(() {
  // ============================================================
  // PARTY
  // ============================================================

  _partyName =
      (data['partyName'] ?? '')
          .toString();

  _partyMobile =
      (data['mobile'] ?? '')
          .toString();

  _partyRoute =
      (data['route'] ?? '')
          .toString();

  // ============================================================
  // OLD / COMPATIBILITY VALUES
  // ============================================================

  _totalDebit =
      _asDouble(
    data['totalDebit'],
  );

  _totalCredit =
      _asDouble(
    data['totalCredit'],
  );

  _balance =
      _asDouble(
    data['balance'],
  );

  // ============================================================
  // CUSTOMER SALES SUMMARY
  // ============================================================

  _totalSales =
      _asDouble(
    data['totalSales'],
  );

  _totalPaidAtBilling =
      _asDouble(
    data['totalPaidAtBilling'],
  );

  _totalCollections =
      _asDouble(
    data['totalCollections'],
  );

  _totalReceived =
      _asDouble(
    data['totalReceived'],
  );

  // ============================================================
  // PAYMENT BREAKUP
  // ============================================================

  final dynamic rawBreakup =
      data['paymentBreakup'];

  if (rawBreakup is Map) {
    final breakup =
        Map<String, dynamic>.from(
      rawBreakup,
    );

    _cashReceived =
        _asDouble(
      breakup['cash'],
    );

    _onlineReceived =
        _asDouble(
      breakup['online'] ??
          breakup['upi'],
    );

    _bankReceived =
        _asDouble(
      breakup['bank'],
    );

    _otherReceived =
        _asDouble(
      breakup['other'],
    );
  } else {
    _cashReceived = 0;
    _onlineReceived = 0;
    _bankReceived = 0;
    _otherReceived = 0;
  }

  _entries
    ..clear()
    ..addAll(
      loadedEntries,
    );

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

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!UiSession.instance.can(AppPermission.ledgerView)) {
      return const AccessDeniedScreen();
    }

    final isAdmin = UiSession.instance.role == UserRole.admin;

    return SimpleModuleScaffold(
      title: 'Ledger',

      subtitle: 'View customer receivables and supplier payables.',

      children: <Widget>[
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Customer'),

                selected: _ledgerType == 'customer',

                onSelected: (_) {
                  if (_ledgerType == 'customer') {
                    return;
                  }

                  setState(() {
                    _ledgerType = 'customer';
                  });

                  _loadParties();
                },
              ),
            ),

            if (isAdmin) ...[
              const SizedBox(width: 10),

              Expanded(
                child: ChoiceChip(
                  label: const Text('Supplier'),

                  selected: _ledgerType == 'supplier',

                  onSelected: (_) {
                    if (_ledgerType == 'supplier') {
                      return;
                    }

                    setState(() {
                      _ledgerType = 'supplier';
                    });

                    _loadParties();
                  },
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<String>(
          value: _partyId,

          decoration: simpleInput(
            _ledgerType == 'customer' ? 'Customer' : 'Supplier',

            _ledgerType == 'customer'
                ? Icons.person_outline
                : Icons.local_shipping_outlined,
          ),

          items: _parties
              .map(
                (party) => DropdownMenuItem<String>(
                  value: party.id,

                  child: Text(party.name),
                ),
              )
              .toList(),

          onChanged: (value) {
            setState(() {
              _partyId = value;
            });

            _loadLedger();
          },
        ),

        const SizedBox(height: 14),

        if (_isLoading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),

              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_loadError.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  Text(_loadError, textAlign: TextAlign.center),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _loadLedger,

                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else ...[
        if (_ledgerType == 'customer')
  Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      // =====================================================
      // CUSTOMER SUMMARY
      // =====================================================

      LayoutBuilder(
        builder:
            (context, constraints) {
          final cardWidth =
              (constraints.maxWidth - 10) /
                  2;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: cardWidth,
                child: _summaryCard(
                  label:
                      'Total Sales',
                  value:
                      _totalSales,
                  icon:
                      Icons
                          .receipt_long_outlined,
                  color:
                      modulePrimary,
                ),
              ),

              SizedBox(
                width: cardWidth,
                child: _summaryCard(
                  label:
                      'Total Received',
                  value:
                      _totalReceived,
                  icon:
                      Icons
                          .payments_outlined,
                  color:
                      moduleGreen,
                ),
              ),

              SizedBox(
                width: cardWidth,
                child: _summaryCard(
                  label:
                      'Outstanding',
                  value:
                      _balance,
                  icon:
                      Icons
                          .account_balance_wallet_outlined,
                  color:
                      moduleOrange,
                ),
              ),

              SizedBox(
                width: cardWidth,
                child: _summaryCard(
                  label:
                      'Collections',
                  value:
                      _totalCollections,
                  icon:
                      Icons
                          .south_west_rounded,
                  color:
                      moduleGreen,
                ),
              ),
            ],
          );
        },
      ),

      const SizedBox(
        height: 14,
      ),

      _paymentBreakupCard(),
    ],
  )
else
  Row(
    children: [
      Expanded(
        child:
            SimpleStat(
          label:
              'Credit Purchases',

          value:
              '₹${_totalCredit.toStringAsFixed(0)}',

          icon:
              Icons
                  .inventory_2_outlined,

          color:
              modulePrimary,
        ),
      ),

      const SizedBox(
        width: 10,
      ),

      Expanded(
        child:
            SimpleStat(
          label:
              'Balance Due',

          value:
              '₹${_balance.toStringAsFixed(0)}',

          icon:
              Icons
                  .schedule_rounded,

          color:
              moduleOrange,
        ),
      ),
    ],
  ),

          const SizedBox(height: 16),

          Text(
            _partyName.isEmpty ? 'Transactions' : '$_partyName Transactions',

            style: const TextStyle(
              color: moduleDark,

              fontSize: 15,

              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 9),

          if (_entries.isEmpty)
            const Card(
              child: AppEmptyState(
                icon: Icons.receipt_long_outlined,

                title: 'No Transactions',

                message: 'Ledger transactions will appear here.',
              ),
            )
          else
            ..._entries.map(_entry),
        ],
      ],
    );
  }
  Widget _summaryCard({
  required String label,
  required double value,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding:
        const EdgeInsets.all(14),

    decoration:
        BoxDecoration(
      color:
          Colors.white,

      borderRadius:
          BorderRadius.circular(16),

      border:
          Border.all(
        color:
            const Color(
          0xFFE7ECF3,
        ),
      ),

      boxShadow: const [
        BoxShadow(
          color:
              Color(
            0x0A000000,
          ),
          blurRadius:
              10,
          offset:
              Offset(
            0,
            4,
          ),
        ),
      ],
    ),

    child:
        Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          height:
              38,

          width:
              38,

          decoration:
              BoxDecoration(
            color:
                color.withValues(
              alpha:
                  .10,
            ),

            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),

          child:
              Icon(
            icon,
            color:
                color,
            size:
                20,
          ),
        ),

        const SizedBox(
          height:
              12,
        ),

        Text(
          label,

          maxLines:
              1,

          overflow:
              TextOverflow.ellipsis,

          style:
              const TextStyle(
            color:
                moduleMuted,

            fontSize:
                11,

            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height:
              4,
        ),

        Text(
          '₹${value.toStringAsFixed(2)}',

          maxLines:
              1,

          overflow:
              TextOverflow.ellipsis,

          style:
              TextStyle(
            color:
                color,

            fontSize:
                18,

            fontWeight:
                FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
Widget _paymentBreakupCard() {
  return Container(
    width:
        double.infinity,

    padding:
        const EdgeInsets.all(14),

    decoration:
        BoxDecoration(
      color:
          Colors.white,

      borderRadius:
          BorderRadius.circular(16),

      border:
          Border.all(
        color:
            const Color(
          0xFFE7ECF3,
        ),
      ),
    ),

    child:
        Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Row(
          children: [
            Icon(
              Icons
                  .account_balance_wallet_outlined,
              size:
                  18,
              color:
                  modulePrimary,
            ),

            SizedBox(
              width:
                  7,
            ),

            Text(
              'Payment Breakup',
              style:
                  TextStyle(
                color:
                    moduleDark,

                fontSize:
                    13,

                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(
          height:
              13,
        ),

        Row(
          children: [
            Expanded(
              child:
                  _paymentModeItem(
                'Cash',
                _cashReceived,
                Icons
                    .payments_outlined,
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            Expanded(
              child:
                  _paymentModeItem(
                'Online',
                _onlineReceived,
                Icons
                    .qr_code_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(
          height:
              8,
        ),

        Row(
          children: [
            Expanded(
              child:
                  _paymentModeItem(
                'Bank',
                _bankReceived,
                Icons
                    .account_balance_outlined,
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            Expanded(
              child:
                  _paymentModeItem(
                'Other',
                _otherReceived,
                Icons
                    .more_horiz_rounded,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
Widget _paymentModeItem(
  String label,
  double amount,
  IconData icon,
) {
  return Container(
    padding:
        const EdgeInsets.symmetric(
      horizontal:
          11,
      vertical:
          10,
    ),

    decoration:
        BoxDecoration(
      color:
          const Color(
        0xFFF7F9FC,
      ),

      borderRadius:
          BorderRadius.circular(
        12,
      ),
    ),

    child:
        Row(
      children: [
        Icon(
          icon,
          size:
              17,
          color:
              modulePrimary,
        ),

        const SizedBox(
          width:
              7,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style:
                    const TextStyle(
                  color:
                      moduleMuted,

                  fontSize:
                      9.5,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height:
                    2,
              ),

              Text(
                '₹${amount.toStringAsFixed(2)}',

                maxLines:
                    1,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  color:
                      moduleDark,

                  fontSize:
                      12,

                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

 Widget _entry(
  _LedgerEntry item,
) {
  if (
    _ledgerType ==
        'customer'
  ) {
    if (
      item.isSale
    ) {
      return _customerSaleCard(
        item,
      );
    }

    if (
      item.isCollection
    ) {
      return _customerCollectionCard(
        item,
      );
    }
  }

  return _basicLedgerEntry(
    item,
  );
}
Widget _customerSaleCard(
  _LedgerEntry item,
) {
  return Padding(
    padding:
        const EdgeInsets.only(
      bottom:
          12,
    ),

    child:
        Container(
      width:
          double.infinity,

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE5EAF1,
          ),
        ),

        boxShadow:
            const [
          BoxShadow(
            color:
                Color(
              0x08000000,
            ),

            blurRadius:
                10,

            offset:
                Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ===================================================
          // HEADER
          // ===================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              12,
            ),

            child:
                Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Container(
                  height:
                      40,

                  width:
                      40,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFEAF2FF,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),

                  child:
                      const Icon(
                    Icons
                        .receipt_long_outlined,

                    color:
                        modulePrimary,

                    size:
                        21,
                  ),
                ),

                const SizedBox(
                  width:
                      10,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        item.referenceNo
                                .trim()
                                .isEmpty
                            ? 'Sale'
                            : item.referenceNo,

                        maxLines:
                            1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          color:
                              moduleDark,

                          fontSize:
                              14,

                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(
                        height:
                            3,
                      ),

                      Text(
                        _formatDate(
                          item.date,
                        ),

                        style:
                            const TextStyle(
                          color:
                              moduleMuted,

                          fontSize:
                              10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width:
                      6,
                ),

                _statusBadge(
                  item.paymentStatus,
                ),
              ],
            ),
          ),

          // ===================================================
          // SALESMAN
          // ===================================================

          if (
            item.salesmanName
                .trim()
                .isNotEmpty
          )
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    14,
              ),

              child:
                  Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      11,
                  vertical:
                      9,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF7F9FC,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child:
                    Row(
                  children: [
                    const Icon(
                      Icons
                          .person_outline_rounded,

                      size:
                          17,

                      color:
                          modulePrimary,
                    ),

                    const SizedBox(
                      width:
                          7,
                    ),

                    const Text(
                      'Salesman',

                      style:
                          TextStyle(
                        color:
                            moduleMuted,

                        fontSize:
                            10,
                      ),
                    ),

                    const Spacer(),

                    Flexible(
                      child:
                          Text(
                        item.salesmanName,

                        maxLines:
                            1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          color:
                              moduleDark,

                          fontSize:
                              11,

                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (
            item.salesmanName
                .trim()
                .isNotEmpty
          )
            const SizedBox(
              height:
                  12,
            ),

          // ===================================================
          // PRODUCTS
          // ===================================================

          if (
            item.products
                .isNotEmpty
          )
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    14,
              ),

              child:
                  Column(
                children:
                    item.products.map(
                  (product) {
                    final name =
                        (
                          product['productName'] ??
                          'Product'
                        ).toString();

                    final variant =
                        (
                          product['variant'] ??
                          ''
                        ).toString();

                    final unit =
                        (
                          product['unit'] ??
                          ''
                        ).toString();

                    final qty =
                        _asDouble(
                      product[
                          'quantity'],
                    );

                    final rate =
                        _asDouble(
                      product[
                          'rate'],
                    );

                    final amount =
                        _asDouble(
                      product[
                          'amount'],
                    );

                    final productTitle =
                        variant.trim().isEmpty
                            ? name
                            : '$name • $variant';

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom:
                            10,
                      ),

                      child:
                          Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                Text(
                                  productTitle,

                                  maxLines:
                                      2,

                                  overflow:
                                      TextOverflow.ellipsis,

                                  style:
                                      const TextStyle(
                                    color:
                                        moduleDark,

                                    fontSize:
                                        11.5,

                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                      3,
                                ),

                                Text(
                                  '${_qtyText(qty)}'
                                  '${unit.trim().isEmpty ? '' : ' $unit'}'
                                  ' × ₹${rate.toStringAsFixed(2)}',

                                  style:
                                      const TextStyle(
                                    color:
                                        moduleMuted,

                                    fontSize:
                                        10,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            width:
                                10,
                          ),

                          Text(
                            '₹${amount.toStringAsFixed(2)}',

                            style:
                                const TextStyle(
                              color:
                                  moduleDark,

                              fontSize:
                                  11.5,

                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),
              ),
            ),

          const Divider(
            height:
                1,
          ),

          // ===================================================
          // TOTALS
          // ===================================================

          Padding(
            padding:
                const EdgeInsets.all(
              14,
            ),

            child:
                Column(
              children: [
                _amountRow(
                  'Bill Total',
                  item.billAmount > 0
                      ? item.billAmount
                      : item.amount,
                  strong:
                      true,
                ),

                if (
                  item.payments
                      .isNotEmpty
                ) ...[
                  const SizedBox(
                    height:
                        8,
                  ),

                  ...item.payments.map(
                    (payment) {
                      final mode =
                          (
                            payment['mode'] ??
                            payment[
                                'paymentMode'] ??
                            'Payment'
                          ).toString();

                      final amount =
                          _asDouble(
                        payment[
                            'amount'],
                      );

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom:
                              5,
                        ),

                        child:
                            _amountRow(
                          mode,
                          amount,
                          valueColor:
                              moduleGreen,
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(
                  height:
                      4,
                ),

                _amountRow(
                  'Total Received',
                  item.paidAmount,
                  valueColor:
                      moduleGreen,
                ),

                const SizedBox(
                  height:
                      5,
                ),

                _amountRow(
                  'Bill Outstanding',
                  item.outstandingAmount,
                  valueColor:
                      item.outstandingAmount >
                              0
                          ? moduleOrange
                          : moduleGreen,
                  strong:
                      true,
                ),

                const Divider(
                  height:
                      20,
                ),

                _amountRow(
                  'Running Outstanding',
                  item.balance,
                  valueColor:
                      item.balance >
                              0
                          ? moduleOrange
                          : moduleGreen,
                  strong:
                      true,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _customerCollectionCard(
  _LedgerEntry item,
) {
  return Padding(
    padding:
        const EdgeInsets.only(
      bottom:
          12,
    ),

    child:
        Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFDDEEE4,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                height:
                    40,

                width:
                    40,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEAF8F0,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),

                child:
                    const Icon(
                  Icons
                      .south_west_rounded,

                  color:
                      moduleGreen,

                  size:
                      21,
                ),
              ),

              const SizedBox(
                width:
                    10,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Payment Received',

                      style:
                          TextStyle(
                        color:
                            moduleDark,

                        fontSize:
                            13,

                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height:
                          2,
                    ),

                    Text(
                      '${item.referenceNo} • ${_formatDate(item.date)}',

                      maxLines:
                          1,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            moduleMuted,

                        fontSize:
                            10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width:
                    8,
              ),

              Text(
                '₹${item.credit.toStringAsFixed(2)}',

                style:
                    const TextStyle(
                  color:
                      moduleGreen,

                  fontSize:
                      16,

                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                13,
          ),

          _detailRow(
            'Mode',
            item.paymentMode
                    .trim()
                    .isEmpty
                ? '-'
                : item.paymentMode,
          ),

          if (
            item.salesmanName
                .trim()
                .isNotEmpty
          )
            _detailRow(
              'Collected By',
              item.salesmanName,
            ),

          if (
            item.reference
                .trim()
                .isNotEmpty
          )
            _detailRow(
              'Reference',
              item.reference,
            ),

          if (
            item.allocations
                .isNotEmpty
          ) ...[
            const Divider(
              height:
                  22,
            ),

            const Text(
              'Applied Bills',

              style:
                  TextStyle(
                color:
                    moduleDark,

                fontSize:
                    11,

                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height:
                  8,
            ),

            ...item.allocations.map(
              (allocation) {
                final saleNo =
                    (
                      allocation['saleNo'] ??
                      allocation['saleId'] ??
                      '-'
                    ).toString();

                final applied =
                    _asDouble(
                  allocation[
                      'amountApplied'],
                );

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom:
                        5,
                  ),

                  child:
                      _amountRow(
                    saleNo,
                    applied,
                    valueColor:
                        moduleGreen,
                  ),
                );
              },
            ),
          ],

          const Divider(
            height:
                22,
          ),

          _amountRow(
            'Outstanding After Payment',
            item.balance,
            valueColor:
                item.balance >
                        0
                    ? moduleOrange
                    : moduleGreen,
            strong:
                true,
          ),
        ],
      ),
    ),
  );
}

Widget _amountRow(
  String label,
  double amount, {
  bool strong = false,
  Color? valueColor,
}) {
  return Row(
    children: [
      Expanded(
        child:
            Text(
          label,

          style:
              TextStyle(
            color:
                strong
                    ? moduleDark
                    : moduleMuted,

            fontSize:
                strong
                    ? 11.5
                    : 10.5,

            fontWeight:
                strong
                    ? FontWeight.w800
                    : FontWeight.w600,
          ),
        ),
      ),

      const SizedBox(
        width:
            10,
      ),

      Text(
        '₹${amount.toStringAsFixed(2)}',

        style:
            TextStyle(
          color:
              valueColor ??
                  moduleDark,

          fontSize:
              strong
                  ? 12
                  : 11,

          fontWeight:
              strong
                  ? FontWeight.w900
                  : FontWeight.w700,
        ),
      ),
    ],
  );
}
Widget _detailRow(
  String label,
  String value,
) {
  return Padding(
    padding:
        const EdgeInsets.only(
      bottom:
          7,
    ),

    child:
        Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        SizedBox(
          width:
              90,

          child:
              Text(
            label,

            style:
                const TextStyle(
              color:
                  moduleMuted,

              fontSize:
                  10,
            ),
          ),
        ),

        Expanded(
          child:
              Text(
            value,

            textAlign:
                TextAlign.right,

            style:
                const TextStyle(
              color:
                  moduleDark,

              fontSize:
                  10.5,

              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
Widget _statusBadge(
  String value,
) {
  final status =
      value
          .trim()
          .toUpperCase();

  Color color;

  switch (status) {
    case 'PAID':
      color =
          moduleGreen;
      break;

    case 'PARTIAL':
      color =
          moduleOrange;
      break;

    case 'CREDIT':
      color =
          moduleOrange;
      break;

    default:
      color =
          modulePrimary;
  }

  return Container(
    padding:
        const EdgeInsets.symmetric(
      horizontal:
          8,
      vertical:
          5,
    ),

    decoration:
        BoxDecoration(
      color:
          color.withValues(
        alpha:
            .10,
      ),

      borderRadius:
          BorderRadius.circular(
        20,
      ),
    ),

    child:
        Text(
      status.isEmpty
          ? 'SALE'
          : status,

      style:
          TextStyle(
        color:
            color,

        fontSize:
            8.5,

        fontWeight:
            FontWeight.w800,
      ),
    ),
  );
}
String _qtyText(
  double value,
) {
  if (
    value ==
        value.roundToDouble()
  ) {
    return value
        .toStringAsFixed(
      0,
    );
  }

  return value
      .toStringAsFixed(
    2,
  );
}
Widget _basicLedgerEntry(
  _LedgerEntry item,
) {
  final bool incoming;

  if (_ledgerType == 'customer') {
    incoming = item.credit > 0;
  } else {
    incoming = item.debit > 0;
  }

  final double amount =
      item.amount > 0
          ? item.amount
          : item.debit > 0
              ? item.debit
              : item.credit;

  return Padding(
    padding: const EdgeInsets.only(
      bottom: 8,
    ),
    child: SimpleSection(
      padding: const EdgeInsets.all(
        12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          // ====================================================
          // ICON
          // ====================================================

          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: incoming
                  ? const Color(
                      0xFFEAF8F0,
                    )
                  : const Color(
                      0xFFFFF3E8,
                    ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              incoming
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: incoming
                  ? moduleGreen
                  : moduleOrange,
              size: 19,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          // ====================================================
          // TRANSACTION DETAILS
          // ====================================================

          Expanded(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.trim().isEmpty
                      ? item.type
                      : item.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: moduleDark,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                if (item.referenceNo
                    .trim()
                    .isNotEmpty)
                  Text(
                    item.referenceNo,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: moduleMuted,
                      fontSize: 9.5,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                if (item.reference
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    item.reference,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: moduleMuted,
                      fontSize: 9,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 2,
                ),

                Text(
                  _formatDate(
                    item.date,
                  ),
                  style:
                      const TextStyle(
                    color: moduleMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ====================================================
          // AMOUNT
          // Flexible width prevents mobile overflow
          // ====================================================

          ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 100,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '${incoming ? '-' : '+'} ₹${amount.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign:
                      TextAlign.right,
                  style: TextStyle(
                    color: incoming
                        ? moduleGreen
                        : moduleOrange,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  'Bal ₹${item.balance.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign:
                      TextAlign.right,
                  style:
                      const TextStyle(
                    color: moduleMuted,
                    fontSize: 8.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _LedgerParty {
  const _LedgerParty({required this.id, required this.name});

  final String id;
  final String name;
}

class _LedgerEntry {
  const _LedgerEntry({
    required this.id,
    required this.referenceNo,
    required this.title,
    required this.type,
    required this.date,

    required this.amount,
    required this.debit,
    required this.credit,
    required this.balance,

    required this.billAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.totalQuantity,

    required this.paymentMode,
    required this.paymentStatus,
    required this.reference,

    required this.salesmanId,
    required this.salesmanName,

    required this.products,
    required this.payments,
    required this.allocations,
  });

  final String id;
  final String referenceNo;

  final String title;
  final String type;

  final DateTime? date;

  final double amount;
  final double debit;
  final double credit;
  final double balance;

  final double billAmount;
  final double paidAmount;
  final double outstandingAmount;
  final double totalQuantity;

  final String paymentMode;
  final String paymentStatus;
  final String reference;

  final String salesmanId;
  final String salesmanName;

  final List<Map<String, dynamic>>
      products;

  final List<Map<String, dynamic>>
      payments;

  final List<Map<String, dynamic>>
      allocations;

  bool get isSale =>
      type.toUpperCase() ==
      'SALE';

  bool get isCollection =>
      type.toUpperCase() ==
      'COLLECTION';
}
