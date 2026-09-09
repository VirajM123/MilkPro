import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../widgets/app_widgets.dart';
import '../common/simple_screen_widgets.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController =
      TextEditingController();

  final _referenceController =
      TextEditingController();

  final _remarksController =
      TextEditingController();

  final List<_SupplierOutstanding>
      _suppliers = [];

  final List<_PaymentEntry>
      _payments = [];

  String? _selectedSupplierId;

  String _mode = 'Cash';

  bool _isLoading = false;

  bool _isSaving = false;

  String _loadError = '';

  @override
  void initState() {
    super.initState();

    _loadPaymentData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();

    super.dispose();
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',

      if (
        ApiConfig.token != null &&
        ApiConfig.token!.isNotEmpty
      )
        'Authorization':
            'Bearer ${ApiConfig.token}',
    };
  }

  double _asDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  _SupplierOutstanding?
      get _selectedSupplier {
    if (_selectedSupplierId == null) {
      return null;
    }

    for (final supplier in _suppliers) {
      if (
        supplier.supplierId ==
        _selectedSupplierId
      ) {
        return supplier;
      }
    }

    return null;
  }

  double get _totalPaidToday {
    double total = 0;

    for (final payment in _payments) {
      if (
        payment.status.toUpperCase() ==
        'POSTED'
      ) {
        total += payment.amount;
      }
    }

    return total;
  }

  int get _pendingSuppliers {
    return _suppliers
        .where(
          (supplier) =>
              supplier.outstanding > 0,
        )
        .length;
  }

  Future<void> _loadPaymentData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = '';
    });

    try {
      final outstandingResponse =
          await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}'
          '/api/payments/outstanding',
        ),
        headers: _headers,
      );

      final historyResponse =
          await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}'
          '/api/payments'
          '?date=${_apiDate(DateTime.now())}',
        ),
        headers: _headers,
      );

      final outstandingDecoded =
          jsonDecode(
        outstandingResponse.body,
      );

      final historyDecoded =
          jsonDecode(
        historyResponse.body,
      );

      if (
        outstandingResponse.statusCode <
                200 ||
            outstandingResponse.statusCode >=
                300 ||
            outstandingDecoded is! Map ||
            outstandingDecoded[
                    'success'] !=
                true
      ) {
        throw Exception(
          outstandingDecoded is Map
              ? (
                  outstandingDecoded[
                        'message'
                      ] ??
                      'Unable to load supplier outstanding.'
                ).toString()
              : 'Unable to load supplier outstanding.',
        );
      }

      if (
        historyResponse.statusCode < 200 ||
        historyResponse.statusCode >= 300 ||
        historyDecoded is! Map ||
        historyDecoded['success'] != true
      ) {
        throw Exception(
          historyDecoded is Map
              ? (
                  historyDecoded[
                        'message'
                      ] ??
                      'Unable to load payment history.'
                ).toString()
              : 'Unable to load payment history.',
        );
      }

      final rawOutstanding =
          outstandingDecoded['data'];

      final rawPayments =
          historyDecoded['data'];

      final List<_SupplierOutstanding>
          loadedSuppliers = [];

      if (rawOutstanding is List) {
        for (final item
            in rawOutstanding) {
          if (item is! Map) {
            continue;
          }

          final map =
              Map<String, dynamic>.from(
            item,
          );

          loadedSuppliers.add(
            _SupplierOutstanding(
              supplierId:
                  (
                    map['supplierId'] ??
                    ''
                  ).toString(),

              supplierName:
                  (
                    map['supplierName'] ??
                    ''
                  ).toString(),

              totalCreditPurchases:
                  _asDouble(
                map[
                    'totalCreditPurchases'],
              ),

              totalPaid:
                  _asDouble(
                map['totalPaid'],
              ),

              outstanding:
                  _asDouble(
                map['outstanding'],
              ),

              purchaseCount:
                  int.tryParse(
                    (
                      map['purchaseCount'] ??
                      0
                    ).toString(),
                  ) ??
                  0,

              status:
                  (
                    map['status'] ??
                    'DUE'
                  ).toString(),

              lastPaymentMode:
                  (
                    map[
                          'lastPaymentMode'
                        ] ??
                        ''
                  ).toString(),
            ),
          );
        }
      }

      final List<_PaymentEntry>
          loadedPayments = [];

      if (rawPayments is List) {
        for (final item in rawPayments) {
          if (item is! Map) {
            continue;
          }

          final map =
              Map<String, dynamic>.from(
            item,
          );

          loadedPayments.add(
            _PaymentEntry(
              paymentId:
                  (
                    map['paymentId'] ??
                    ''
                  ).toString(),

              paymentNo:
                  (
                    map['paymentNo'] ??
                    ''
                  ).toString(),

              supplierId:
                  (
                    map['supplierId'] ??
                    ''
                  ).toString(),

              supplier:
                  (
                    map['supplierName'] ??
                    ''
                  ).toString(),

              amount:
                  _asDouble(
                map['amount'],
              ),

              mode:
                  (
                    map['paymentMode'] ??
                    ''
                  ).toString(),

              reference:
                  (
                    map['referenceNo'] ??
                    ''
                  ).toString(),

              remarks:
                  (
                    map['remarks'] ??
                    ''
                  ).toString(),

              status:
                  (
                    map['status'] ??
                    ''
                  ).toString(),

              paymentDate:
                  DateTime.tryParse(
                (
                  map['paymentDate'] ??
                  ''
                ).toString(),
              ),
            ),
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _suppliers
          ..clear()
          ..addAll(
            loadedSuppliers,
          );

        _payments
          ..clear()
          ..addAll(
            loadedPayments,
          );

        if (
          _selectedSupplierId == null ||
          !_suppliers.any(
            (supplier) =>
                supplier.supplierId ==
                _selectedSupplierId,
          )
        ) {
          final payableSuppliers =
              _suppliers
                  .where(
                    (supplier) =>
                        supplier.outstanding >
                        0,
                  )
                  .toList();

          _selectedSupplierId =
              payableSuppliers.isNotEmpty
                  ? payableSuppliers
                      .first
                      .supplierId
                  : null;
        }

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

  String _apiDate(
    DateTime date,
  ) {
    final year =
        date.year.toString();

    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    if (
      !(
        _formKey.currentState?.validate() ??
        false
      )
    ) {
      return;
    }

    final supplier =
        _selectedSupplier;

    if (supplier == null) {
      showSavedMessage(
        context,
        'Please select supplier.',
      );

      return;
    }

    final amount =
        double.tryParse(
          _amountController.text.trim(),
        ) ??
        0;

    if (
      amount >
      supplier.outstanding
    ) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Payment cannot exceed outstanding '
            '₹${supplier.outstanding.toStringAsFixed(2)}.',
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
          '/api/payments',
        ),
        headers: _headers,
        body: jsonEncode({
          'supplierId':
              supplier.supplierId,

          'amount':
              amount,

          'paymentMode':
              _mode,

          'referenceNo':
              _referenceController
                  .text
                  .trim(),

          'remarks':
              _remarksController
                  .text
                  .trim(),

          'paymentDate':
              DateTime.now()
                  .toIso8601String(),
        }),
      );

      final decoded =
          jsonDecode(
        response.body,
      );

      if (
        response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map ||
        decoded['success'] != true
      ) {
        throw Exception(
          decoded is Map
              ? (
                  decoded['message'] ??
                  'Unable to save payment.'
                ).toString()
              : 'Unable to save payment.',
        );
      }

      final data =
          decoded['data'];

      final paymentNo =
          data is Map
              ? (
                  data['paymentNo'] ??
                  ''
                ).toString()
              : '';

      _amountController.clear();
      _referenceController.clear();
      _remarksController.clear();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            paymentNo.isEmpty
                ? 'Supplier payment saved successfully.'
                : 'Payment saved • $paymentNo',
          ),
        ),
      );

      await _loadPaymentData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
  }

Future<void> _cancelPayment(_PaymentEntry payment) async {
  if (payment.status.toUpperCase() == 'CANCELLED') {
    return;
  }

  final paymentIdentifier = payment.paymentId.trim().isNotEmpty
      ? payment.paymentId.trim()
      : payment.paymentNo.trim();

  if (paymentIdentifier.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment identifier not found.'),
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cancel Payment?'),
        content: Text(
          'Are you sure you want to cancel payment '
          '${payment.paymentNo} of '
          '₹${payment.amount.toStringAsFixed(2)} '
          'for ${payment.supplier}?\n\n'
          'The payment will not be deleted. '
          'It will be marked as cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Cancel Payment'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !mounted) {
    return;
  }

  try {
    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}'
        '/api/payments/'
        '$paymentIdentifier/cancel',
      ),
      headers: _headers,
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map ||
        decoded['success'] != true) {
      throw Exception(
        decoded is Map
            ? (decoded['message'] ?? 'Unable to cancel payment.')
                .toString()
            : 'Unable to cancel payment.',
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          decoded['message']?.toString() ??
              'Payment cancelled successfully.',
        ),
      ),
    );

    await _loadPaymentData();
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error
              .toString()
              .replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }
}

  @override
  Widget build(
    BuildContext context,
  ) {
    final payableSuppliers =
        _suppliers
            .where(
              (supplier) =>
                  supplier.outstanding > 0,
            )
            .toList();

    return SimpleModuleScaffold(
      title: 'Payments',
      subtitle:
          'Record supplier payments and manage outstanding payables.',
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SimpleStat(
                label: 'Paid today',
                value:
                    '₹${_totalPaidToday.toStringAsFixed(0)}',
                icon:
                    Icons.north_east_rounded,
                color: moduleGreen,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: SimpleStat(
                label: 'Pending Suppliers',
                value:
                    '$_pendingSuppliers',
                icon:
                    Icons
                        .account_balance_wallet_outlined,
                color: modulePrimary,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        if (_isLoading)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(
                28,
              ),
              child: Center(
                child:
                    CircularProgressIndicator(),
              ),
            ),
          )
        else if (_loadError.isNotEmpty)
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons
                        .error_outline_rounded,
                    size: 32,
                    color: Colors.red,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    _loadError,
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  ElevatedButton(
                    onPressed:
                        _loadPaymentData,
                    child:
                        const Text(
                      'Retry',
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          SimpleSection(
            title:
                'Pay Supplier',
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  DropdownButtonFormField<
                      String>(
                    value:
                        _selectedSupplierId,

                    decoration:
                        simpleInput(
                      'Supplier',
                      Icons
                          .local_shipping_outlined,
                    ),

                    items:
                        payableSuppliers
                            .map(
                      (supplier) {
                        return DropdownMenuItem<
                            String>(
                          value:
                              supplier
                                  .supplierId,
                          child: Text(
                            supplier
                                .supplierName,
                          ),
                        );
                      },
                    ).toList(),

                    onChanged: (value) {
                      setState(() {
                        _selectedSupplierId =
                            value;
                      });
                    },

                    validator: (value) {
                      if (
                        value == null ||
                        value.isEmpty
                      ) {
                        return 'Select supplier';
                      }

                      return null;
                    },
                  ),

                  if (
                    _selectedSupplier !=
                    null
                  ) ...[
                    const SizedBox(
                      height: 11,
                    ),

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            modulePrimary
                                .withValues(
                          alpha: .06,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        border:
                            Border.all(
                          color:
                              modulePrimary
                                  .withValues(
                            alpha: .12,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Supplier Outstanding',
                            style:
                                TextStyle(
                              color:
                                  moduleMuted,
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            '₹${_selectedSupplier!.outstanding.toStringAsFixed(2)}',
                            style:
                                const TextStyle(
                              color:
                                  moduleDark,
                              fontSize:
                                  22,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            'Credit Purchases ₹${_selectedSupplier!.totalCreditPurchases.toStringAsFixed(2)}'
                            '  •  Paid ₹${_selectedSupplier!.totalPaid.toStringAsFixed(2)}',
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
                  ],

                  const SizedBox(
                    height: 11,
                  ),

                  TextFormField(
                    controller:
                        _amountController,

                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),

                    inputFormatters: <
                        TextInputFormatter>[
                      FilteringTextInputFormatter
                          .allow(
                        RegExp(
                          r'^\d*\.?\d{0,2}',
                        ),
                      ),
                    ],

                    decoration:
                        simpleInput(
                      'Payment Amount',
                      Icons
                          .currency_rupee_rounded,
                    ),

                    validator: (value) {
                      final amount =
                          double.tryParse(
                        value ?? '',
                      );

                      if (
                        amount == null ||
                        amount <= 0
                      ) {
                        return 'Enter payment amount';
                      }

                      final supplier =
                          _selectedSupplier;

                      if (
                        supplier != null &&
                        amount >
                            supplier
                                .outstanding
                      ) {
                        return 'Maximum ₹${supplier.outstanding.toStringAsFixed(2)}';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 11,
                  ),

                  DropdownButtonFormField<
                      String>(
                    value:
                        _mode,

                    decoration:
                        simpleInput(
                      'Payment Mode',
                      Icons
                          .payments_outlined,
                    ),

                    items:
                        const <String>[
                      'Cash',
                      'UPI',
                      'Bank Transfer',
                      'Cheque',
                    ].map(
                      (mode) {
                        return DropdownMenuItem<
                            String>(
                          value:
                              mode,
                          child:
                              Text(
                            mode,
                          ),
                        );
                      },
                    ).toList(),

                    onChanged: (value) {
                      setState(() {
                        _mode =
                            value ??
                            _mode;
                      });
                    },
                  ),

                  const SizedBox(
                    height: 11,
                  ),

                  TextFormField(
                    controller:
                        _referenceController,

                    decoration:
                        simpleInput(
                      'Reference (optional)',
                      Icons
                          .tag_rounded,
                    ),
                  ),

                  const SizedBox(
                    height: 11,
                  ),

                  TextFormField(
                    controller:
                        _remarksController,

                    maxLines: 2,

                    decoration:
                        simpleInput(
                      'Remarks (optional)',
                      Icons
                          .notes_rounded,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : _save,

                      child:
                          _isSaving
                              ? const SizedBox(
                                  height:
                                      20,
                                  width:
                                      20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Text(
                                  'Save Payment',
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'Recent supplier payments',
            style: TextStyle(
              color: moduleDark,
              fontSize: 15,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          if (_payments.isEmpty)
            const Card(
              child: AppEmptyState(
                icon:
                    Icons
                        .payments_outlined,
                title:
                    'No Payments',
                message:
                    'Supplier payments made today will appear here.',
              ),
            )
          else
            ..._payments.map(
              (item) =>
                  Padding(
                padding:
                    const EdgeInsets
                        .only(
                  bottom: 8,
                ),
                child:
                    SimpleSection(
                  padding:
                      const EdgeInsets
                          .all(
                    12,
                  ),
                  child: Row(
                    children:
                        <Widget>[
                      Icon(
                        item.status
                                    .toUpperCase() ==
                                'CANCELLED'
                            ? Icons
                                .cancel_outlined
                            : Icons
                                .check_circle_rounded,
                        color:
                            item.status
                                        .toUpperCase() ==
                                    'CANCELLED'
                                ? Colors
                                    .red
                                : moduleGreen,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: <
                              Widget>[
                            Text(
                              item.supplier,
                              style:
                                  const TextStyle(
                                color:
                                    moduleDark,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),

                            Text(
                              item.paymentNo,
                              style:
                                  const TextStyle(
                                color:
                                    moduleMuted,
                                fontSize:
                                    10,
                              ),
                            ),

                            Text(
                              item.reference
                                      .isEmpty
                                  ? item.mode
                                  : '${item.mode} • ${item.reference}',
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

                   Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(
      '₹${item.amount.toStringAsFixed(0)}',
      style: TextStyle(
        color: item.status.toUpperCase() == 'CANCELLED'
            ? Colors.red
            : moduleGreen,
        fontWeight: FontWeight.w900,
      ),
    ),

    Text(
      item.status.toUpperCase() == 'CANCELLED'
          ? 'Cancelled'
          : 'Paid',
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: item.status.toUpperCase() == 'CANCELLED'
            ? Colors.red
            : moduleGreen,
      ),
    ),

    if (item.status.toUpperCase() != 'CANCELLED')
      PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 20,
        tooltip: 'Payment options',
        onSelected: (value) {
          if (value == 'cancel') {
            _cancelPayment(item);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem<String>(
            value: 'cancel',
            child: Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Cancel Payment',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
  ],
),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SupplierOutstanding {
  const _SupplierOutstanding({
    required this.supplierId,
    required this.supplierName,
    required this.totalCreditPurchases,
    required this.totalPaid,
    required this.outstanding,
    required this.purchaseCount,
    required this.status,
    required this.lastPaymentMode,
  });

  final String supplierId;
  final String supplierName;

  final double totalCreditPurchases;
  final double totalPaid;
  final double outstanding;

  final int purchaseCount;

  final String status;
  final String lastPaymentMode;
}

class _PaymentEntry {
  const _PaymentEntry({
    required this.paymentId,
    required this.paymentNo,
    required this.supplierId,
    required this.supplier,
    required this.amount,
    required this.mode,
    required this.reference,
    required this.remarks,
    required this.status,
    required this.paymentDate,
  });

  final String paymentId;
  final String paymentNo;

  final String supplierId;
  final String supplier;

  final double amount;

  final String mode;
  final String reference;
  final String remarks;

  final String status;

  final DateTime? paymentDate;
}