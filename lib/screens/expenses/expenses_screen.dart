import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../common/access_denied_screen.dart';
import '../common/simple_screen_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() =>
      _ExpensesScreenState();
}

class _ExpensesScreenState
    extends State<ExpensesScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _amountController =
      TextEditingController();

  final _noteController =
      TextEditingController();

  final List<_ExpenseEntry>
      _expenses =
      <_ExpenseEntry>[];

  String _category = 'Fuel';
  String _mode = 'Cash';

  bool _isLoading = true;
  bool _isSaving = false;

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _loadExpenses();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  // =====================================================
  // AUTH HEADERS
  // =====================================================

  Map<String, String>
      get _headers {
    return <String, String>{
      'Content-Type':
          'application/json',

      if (ApiConfig.token.isNotEmpty)
        'Authorization':
            'Bearer ${ApiConfig.token}',
    };
  }

  // =====================================================
  // LOAD EXPENSES
  // GET /api/expenses
  // =====================================================

  Future<void>
      _loadExpenses() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response =
          await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/expenses',
        ),
        headers: _headers,
      );

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (response.statusCode !=
          200) {
        String message =
            'Unable to load expenses.';

        if (decoded is Map) {
          message =
              decoded['message']
                      ?.toString() ??
                  message;
        }

        throw Exception(
          message,
        );
      }

      final List<dynamic>
          expenseList =
          decoded is Map &&
                  decoded['data']
                      is List
              ? decoded['data']
                  as List<dynamic>
              : <dynamic>[];

      final List<_ExpenseEntry>
          loadedExpenses =
          expenseList
              .whereType<Map>()
              .map(
                (item) =>
                    _ExpenseEntry
                        .fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              )
              .toList();

      if (!mounted) return;

      setState(() {
        _expenses
          ..clear()
          ..addAll(
            loadedExpenses,
          );

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage =
            _cleanError(
          error,
        );
      });
    }
  }

  // =====================================================
  // SAVE EXPENSE
  // POST /api/expenses
  // =====================================================

  Future<void> _save() async {
    if (_isSaving) return;

    if (!(_formKey
            .currentState
            ?.validate() ??
        false)) {
      return;
    }

    final double? amount =
        double.tryParse(
      _amountController.text
          .trim(),
    );

    if (amount == null ||
        amount <= 0) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response =
          await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/expenses',
        ),
        headers: _headers,
        body: jsonEncode(
          <String, dynamic>{
            'expenseDate':
                DateTime.now()
                    .toIso8601String(),

            'category':
                _category,

            'amount':
                amount,

            'paymentMode':
                _mode,

            'note':
                _noteController
                    .text
                    .trim(),
          },
        ),
      );

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (response.statusCode !=
          201) {
        String message =
            'Unable to save expense.';

        if (decoded is Map) {
          message =
              decoded['message']
                      ?.toString() ??
                  message;
        }

        throw Exception(
          message,
        );
      }

      if (!mounted) return;

      _amountController.clear();
      _noteController.clear();

      FocusScope.of(context)
          .unfocus();

      showSavedMessage(
        context,
        decoded is Map
            ? decoded['message']
                    ?.toString() ??
                'Expense added successfully.'
            : 'Expense added successfully.',
      );

      await _loadExpenses();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(
              error,
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

  // =====================================================
  // TOTALS
  // ONLY POSTED EXPENSES
  // =====================================================

  double get _todayTotal {
    final now =
        DateTime.now();

    return _expenses
        .where(
          (item) =>
              item.status ==
                  'POSTED' &&
              _sameDate(
                item.expenseDate,
                now,
              ),
        )
        .fold<double>(
          0,
          (
            sum,
            item,
          ) =>
              sum +
              item.amount,
        );
  }

  double get _monthTotal {
    final now =
        DateTime.now();

    return _expenses
        .where(
          (item) =>
              item.status ==
                  'POSTED' &&
              item.expenseDate
                      .year ==
                  now.year &&
              item.expenseDate
                      .month ==
                  now.month,
        )
        .fold<double>(
          0,
          (
            sum,
            item,
          ) =>
              sum +
              item.amount,
        );
  }

  bool _sameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  String _cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (!UiSession.instance.can(AppPermission.expensesView)) {
      return const AccessDeniedScreen();
    }
    return SimpleModuleScaffold(
      title: 'Expenses',

      subtitle:
          'Record daily distribution expenses in a few quick fields.',

      children: <Widget>[
        // =================================================
        // TOTAL CARDS
        // =================================================

        Row(
          children: <Widget>[
            SimpleStat(
              label: 'Today',

              value:
                  '₹${_todayTotal.toStringAsFixed(0)}',

              icon:
                  Icons.account_balance_wallet_outlined,

              color:
                  moduleOrange,
            ),

            const SizedBox(
              width: 10,
            ),

            SimpleStat(
              label:
                  'This Month',

              value:
                  '₹${_monthTotal.toStringAsFixed(0)}',

              icon:
                  Icons.calendar_month_outlined,

              color:
                  modulePrimary,
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        // =================================================
        // ADD EXPENSE
        // =================================================

        SimpleSection(
          title:
              'Add expense',

          child: Form(
            key:
                _formKey,

            child: Column(
              children:
                  <Widget>[
                DropdownButtonFormField<
                    String>(
                  initialValue:
                      _category,

                  decoration:
                      simpleInput(
                    'Category',
                    Icons.category_outlined,
                  ),

                  items:
                      const <String>[
                    'Fuel',
                    'Vehicle',
                    'Loading',
                    'Food',
                    'Other',
                  ]
                          .map(
                            (
                              item,
                            ) =>
                                DropdownMenuItem<
                                    String>(
                              value:
                                  item,

                              child:
                                  Text(
                                item,
                              ),
                            ),
                          )
                          .toList(),

                  onChanged:
                      _isSaving
                          ? null
                          : (
                              value,
                            ) {
                              if (value ==
                                  null) {
                                return;
                              }

                              setState(
                                () {
                                  _category =
                                      value;
                                },
                              );
                            },
                ),

                const SizedBox(
                  height: 11,
                ),

                TextFormField(
                  controller:
                      _amountController,

                  enabled:
                      !_isSaving,

                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal:
                        true,
                  ),

                  inputFormatters:
                      <TextInputFormatter>[
                    FilteringTextInputFormatter
                        .allow(
                      RegExp(
                        r'^\d*\.?\d{0,2}',
                      ),
                    ),
                  ],

                  decoration:
                      simpleInput(
                    'Amount',
                    Icons.currency_rupee_rounded,
                  ),

                  validator:
                      (
                        value,
                      ) {
                    final amount =
                        double.tryParse(
                      value ??
                          '',
                    );

                    return amount ==
                                null ||
                            amount <=
                                0
                        ? 'Enter amount'
                        : null;
                  },
                ),

                const SizedBox(
                  height: 11,
                ),

                DropdownButtonFormField<
                    String>(
                  initialValue:
                      _mode,

                  decoration:
                      simpleInput(
                    'Paid by',
                    Icons.payments_outlined,
                  ),

                  items:
                      const <String>[
                    'Cash',
                    'UPI',
                    'Bank',
                  ]
                          .map(
                            (
                              item,
                            ) =>
                                DropdownMenuItem<
                                    String>(
                              value:
                                  item,

                              child:
                                  Text(
                                item,
                              ),
                            ),
                          )
                          .toList(),

                  onChanged:
                      _isSaving
                          ? null
                          : (
                              value,
                            ) {
                              if (value ==
                                  null) {
                                return;
                              }

                              setState(
                                () {
                                  _mode =
                                      value;
                                },
                              );
                            },
                ),

                const SizedBox(
                  height: 11,
                ),

                TextFormField(
                  controller:
                      _noteController,

                  enabled:
                      !_isSaving,

                  maxLines:
                      2,

                  decoration:
                      simpleInput(
                    'Note (optional)',
                    Icons.notes_rounded,
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
                                width:
                                    20,
                                height:
                                    20,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Text(
                                'Save Expense',
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

        // =================================================
        // RECENT EXPENSES
        // =================================================

        const Text(
          'Recent expenses',

          style:
              TextStyle(
            color:
                moduleDark,

            fontSize:
                15,

            fontWeight:
                FontWeight.w900,
          ),
        ),

        const SizedBox(
          height: 9,
        ),

        if (_isLoading)

          const Padding(
            padding:
                EdgeInsets.all(
              24,
            ),

            child:
                Center(
              child:
                  CircularProgressIndicator(),
            ),
          )

        else if (_errorMessage
            .isNotEmpty)

          Card(
            child:
                Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),

              child:
                  Column(
                children:
                    <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    color:
                        moduleOrange,
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  Text(
                    _errorMessage,

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      color:
                          moduleMuted,
                    ),
                  ),

                  const SizedBox(
                    height:
                        10,
                  ),

                  TextButton.icon(
                    onPressed:
                        _loadExpenses,

                    icon:
                        const Icon(
                      Icons.refresh_rounded,
                    ),

                    label:
                        const Text(
                      'Retry',
                    ),
                  ),
                ],
              ),
            ),
          )

        else if (_expenses
            .isEmpty)

          const Card(
            child:
                AppEmptyState(
              icon:
                  Icons.receipt_long_outlined,

              title:
                  'No Expenses',

              message:
                  'New expense entries will appear here.',
            ),
          )

        else

          ..._expenses.map(
            (
              item,
            ) =>
                Padding(
              padding:
                  const EdgeInsets.only(
                bottom:
                    8,
              ),

              child:
                  SimpleSection(
                padding:
                    const EdgeInsets.all(
                  12,
                ),

                child:
                    Row(
                  children:
                      <Widget>[
                    Icon(
                      item.status ==
                              'CANCELLED'
                          ? Icons
                              .cancel_outlined
                          : Icons
                              .receipt_long_outlined,

                      color:
                          item.status ==
                                  'CANCELLED'
                              ? moduleMuted
                              : moduleOrange,
                    ),

                    const SizedBox(
                      width:
                          10,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children:
                            <Widget>[
                          Row(
                            children:
                                <Widget>[
                              Flexible(
                                child:
                                    Text(
                                  item.category,

                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      TextStyle(
                                    color:
                                        item.status ==
                                                'CANCELLED'
                                            ? moduleMuted
                                            : moduleDark,

                                    fontWeight:
                                        FontWeight
                                            .w800,

                                    decoration:
                                        item.status ==
                                                'CANCELLED'
                                            ? TextDecoration
                                                .lineThrough
                                            : null,
                                  ),
                                ),
                              ),

                              if (item.status ==
                                  'CANCELLED') ...[
                                const SizedBox(
                                  width:
                                      6,
                                ),

                                const Text(
                                  'CANCELLED',

                                  style:
                                      TextStyle(
                                    color:
                                        moduleMuted,

                                    fontSize:
                                        9,

                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          Text(
                            item.note
                                    .isEmpty
                                ? item.mode
                                : '${item.mode} • ${item.note}',

                            overflow:
                                TextOverflow
                                    .ellipsis,

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

                    Text(
                      '₹${item.amount.toStringAsFixed(0)}',

                      style:
                          TextStyle(
                        color:
                            item.status ==
                                    'CANCELLED'
                                ? moduleMuted
                                : moduleOrange,

                        fontWeight:
                            FontWeight
                                .w900,

                        decoration:
                            item.status ==
                                    'CANCELLED'
                                ? TextDecoration
                                    .lineThrough
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}


// =======================================================
// EXPENSE MODEL
// =======================================================

class _ExpenseEntry {
  const _ExpenseEntry({
    required this.expenseId,
    required this.expenseNo,
    required this.expenseDate,
    required this.category,
    required this.amount,
    required this.mode,
    required this.note,
    required this.status,
  });

  final String expenseId;
  final String expenseNo;

  final DateTime expenseDate;

  final String category;
  final double amount;
  final String mode;
  final String note;
  final String status;


  factory _ExpenseEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return _ExpenseEntry(
      expenseId:
          json['expenseId']
                  ?.toString() ??
              '',

      expenseNo:
          json['expenseNo']
                  ?.toString() ??
              '',

      expenseDate:
          DateTime.tryParse(
            json['expenseDate']
                    ?.toString() ??
                '',
          ) ??
          DateTime.now(),

      category:
          json['category']
                  ?.toString() ??
              'Other',

      amount:
          double.tryParse(
            json['amount']
                    ?.toString() ??
                '0',
          ) ??
          0,

      mode:
          json['paymentMode']
                  ?.toString() ??
              'Cash',

      note:
          json['note']
                  ?.toString() ??
              '',

      status:
          json['status']
                  ?.toString()
                  .toUpperCase() ??
              'POSTED',
    );
  }
}