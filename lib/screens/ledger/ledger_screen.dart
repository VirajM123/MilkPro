import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../widgets/app_widgets.dart';
import '../common/simple_screen_widgets.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() =>
      _LedgerScreenState();
}

class _LedgerScreenState
    extends State<LedgerScreen> {

  String _ledgerType =
      'customer';

  String? _partyId;

  final List<_LedgerParty>
      _parties = [];

  final List<_LedgerEntry>
      _entries = [];

  bool _isLoading =
      false;

  String _loadError =
      '';

  double _totalDebit =
      0;

  double _totalCredit =
      0;

  double _balance =
      0;

  String _partyName =
      '';

  @override
  void initState() {
    super.initState();

    _loadParties();
  }

  Map<String, String> get _headers {
    return {
      'Content-Type':
          'application/json',

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

  Future<void> _loadParties() async {

    setState(() {
      _isLoading =
          true;

      _loadError =
          '';

      _partyId =
          null;

      _entries.clear();
    });

    try {

      final endpoint =
          _ledgerType ==
                  'customer'
              ? '/api/customers'
              : '/api/suppliers';

      final response =
          await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}$endpoint',
        ),
        headers:
            _headers,
      );

      final decoded =
          jsonDecode(
        response.body,
      );

      if (
        response.statusCode <
                200 ||
            response.statusCode >=
                300 ||
            decoded is! Map ||
            decoded['success'] !=
                true
      ) {
        throw Exception(
          decoded is Map
              ? (
                  decoded['message'] ??
                  'Unable to load parties.'
                ).toString()
              : 'Unable to load parties.',
        );
      }

      final rawData =
          decoded['data'];

      final List<_LedgerParty>
          loaded = [];

      if (rawData is List) {

        for (
          final item
          in rawData
        ) {

          if (
            item is! Map
          ) {
            continue;
          }

          final map =
              Map<String, dynamic>.from(
            item,
          );

          if (
            _ledgerType ==
            'customer'
          ) {

            final id =
                (
                  map['customerId'] ??
                  ''
                ).toString();

            final name =
                (
                  map['name'] ??
                  ''
                ).toString();

            if (
              id.isNotEmpty
            ) {
              loaded.add(
                _LedgerParty(
                  id:
                      id,
                  name:
                      name,
                ),
              );
            }
          } else {

            final id =
                (
                  map['supplierId'] ??
                  ''
                ).toString();

            final name =
                (
                  map['supplierName'] ??
                  ''
                ).toString();

            if (
              id.isNotEmpty
            ) {
              loaded.add(
                _LedgerParty(
                  id:
                      id,
                  name:
                      name,
                ),
              );
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
          ..addAll(
            loaded,
          );

        _partyId =
            loaded.isNotEmpty
                ? loaded.first.id
                : null;
      });

      if (
        _partyId != null
      ) {
        await _loadLedger();
      } else {

        setState(() {
          _isLoading =
              false;
        });
      }

    } catch (error) {

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading =
            false;

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

  Future<void> _loadLedger() async {

    final partyId =
        _partyId;

    if (
      partyId == null
    ) {
      return;
    }

    setState(() {
      _isLoading =
          true;

      _loadError =
          '';
    });

    try {

      final uri =
          Uri.parse(
        '${ApiConfig.baseUrl}'
        '/api/ledger'
        '?type=$_ledgerType'
        '&partyId=$partyId',
      );

      final response =
          await http.get(
        uri,
        headers:
            _headers,
      );

      final decoded =
          jsonDecode(
        response.body,
      );

      if (
        response.statusCode <
                200 ||
            response.statusCode >=
                300 ||
            decoded is! Map ||
            decoded['success'] !=
                true
      ) {
        throw Exception(
          decoded is Map
              ? (
                  decoded['message'] ??
                  'Unable to load ledger.'
                ).toString()
              : 'Unable to load ledger.',
        );
      }

      final rawData =
          decoded['data'];

      if (
        rawData is! Map
      ) {
        throw Exception(
          'Invalid ledger response.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        rawData,
      );

      final rawTransactions =
          data['transactions'];

      final List<_LedgerEntry>
          loadedEntries = [];

      if (
        rawTransactions
        is List
      ) {

        for (
          final item
          in rawTransactions
        ) {

          if (
            item is! Map
          ) {
            continue;
          }

          final map =
              Map<String, dynamic>.from(
            item,
          );

          loadedEntries.add(
            _LedgerEntry(
              id:
                  (
                    map['id'] ??
                    ''
                  ).toString(),

              referenceNo:
                  (
                    map['referenceNo'] ??
                    ''
                  ).toString(),

              title:
                  (
                    map['title'] ??
                    ''
                  ).toString(),

              type:
                  (
                    map['type'] ??
                    ''
                  ).toString(),

              date:
                  DateTime.tryParse(
                (
                  map['date'] ??
                  ''
                ).toString(),
              ),

amount:
    _asDouble(
  map['amount'],
),
              debit:
                  _asDouble(
                map['debit'],
              ),

              credit:
                  _asDouble(
                map['credit'],
              ),

              balance:
                  _asDouble(
                map['balance'],
              ),

              paymentMode:
                  (
                    map['paymentMode'] ??
                    ''
                  ).toString(),

              reference:
                  (
                    map['reference'] ??
                    ''
                  ).toString(),
            ),
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {

        _partyName =
            (
              data['partyName'] ??
              ''
            ).toString();

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

        _entries
          ..clear()
          ..addAll(
            loadedEntries,
          );

        _isLoading =
            false;
      });

    } catch (error) {

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading =
            false;

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

  String _formatDate(
    DateTime? date,
  ) {
    if (
      date == null
    ) {
      return '';
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

    return '$day-$month-${date.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    return SimpleModuleScaffold(
      title:
          'Ledger',

      subtitle:
          'View customer receivables and supplier payables.',

      children:
          <Widget>[

        Row(
          children: [

            Expanded(
              child:
                  ChoiceChip(
                label:
                    const Text(
                  'Customer',
                ),

                selected:
                    _ledgerType ==
                        'customer',

                onSelected:
                    (_) {

                  if (
                    _ledgerType ==
                    'customer'
                  ) {
                    return;
                  }

                  setState(() {
                    _ledgerType =
                        'customer';
                  });

                  _loadParties();
                },
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child:
                  ChoiceChip(
                label:
                    const Text(
                  'Supplier',
                ),

                selected:
                    _ledgerType ==
                        'supplier',

                onSelected:
                    (_) {

                  if (
                    _ledgerType ==
                    'supplier'
                  ) {
                    return;
                  }

                  setState(() {
                    _ledgerType =
                        'supplier';
                  });

                  _loadParties();
                },
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        DropdownButtonFormField<
            String>(
          value:
              _partyId,

          decoration:
              simpleInput(
            _ledgerType ==
                    'customer'
                ? 'Customer'
                : 'Supplier',

            _ledgerType ==
                    'customer'
                ? Icons
                    .person_outline
                : Icons
                    .local_shipping_outlined,
          ),

          items:
              _parties
                  .map(
                    (
                      party,
                    ) =>
                        DropdownMenuItem<
                            String>(
                      value:
                          party.id,

                      child:
                          Text(
                        party.name,
                      ),
                    ),
                  )
                  .toList(),

          onChanged:
              (value) {

            setState(() {
              _partyId =
                  value;
            });

            _loadLedger();
          },
        ),

        const SizedBox(
          height: 14,
        ),

        if (_isLoading)
          const Card(
            child:
                Padding(
              padding:
                  EdgeInsets.all(
                28,
              ),

              child:
                  Center(
                child:
                    CircularProgressIndicator(),
              ),
            ),
          )

        else if (
          _loadError
              .isNotEmpty
        )
          Card(
            child:
                Padding(
              padding:
                  const EdgeInsets
                      .all(
                16,
              ),

              child:
                  Column(
                children: [

                  Text(
                    _loadError,

                    textAlign:
                        TextAlign
                            .center,
                  ),

                  const SizedBox(
                    height:
                        10,
                  ),

                  ElevatedButton(
                    onPressed:
                        _loadLedger,

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

          Row(
            children:
                <Widget>[

              Expanded(
                child:
                    SimpleStat(
                  label:
                      _ledgerType ==
                              'customer'
                          ? 'Credit Sales'
                          : 'Credit Purchases',

                  value:
                      '₹${(_ledgerType == 'customer' ? _totalDebit : _totalCredit).toStringAsFixed(0)}',

                  icon:
                      _ledgerType ==
                              'customer'
                          ? Icons
                              .shopping_cart_outlined
                          : Icons
                              .inventory_2_outlined,

                  color:
                      modulePrimary,
                ),
              ),

              const SizedBox(
                width:
                    10,
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

          const SizedBox(
            height:
                16,
          ),

          Text(
            _partyName
                    .isEmpty
                ? 'Transactions'
                : '$_partyName Transactions',

            style:
                const TextStyle(
              color:
                  moduleDark,

              fontSize:
                  15,

              fontWeight:
                  FontWeight
                      .w900,
            ),
          ),

          const SizedBox(
            height:
                9,
          ),

          if (
            _entries.isEmpty
          )
            const Card(
              child:
                  AppEmptyState(
                icon:
                    Icons
                        .receipt_long_outlined,

                title:
                    'No Transactions',

                message:
                    'Ledger transactions will appear here.',
              ),
            )

          else
            ..._entries.map(
              _entry,
            ),
        ],
      ],
    );
  }

  Widget _entry(
    _LedgerEntry item,
  ) {

    final bool incoming;

    if (
      _ledgerType ==
      'customer'
    ) {
      incoming =
          item.credit >
          0;
    } else {
      incoming =
          item.debit >
          0;
    }
final amount =
    item.amount > 0
        ? item.amount
        : item.debit > 0
            ? item.debit
            : item.credit;

    return Padding(
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

            Container(
              height:
                  38,

              width:
                  38,

              decoration:
                  BoxDecoration(
                color:
                    incoming
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

              child:
                  Icon(
                incoming
                    ? Icons
                        .south_west_rounded
                    : Icons
                        .north_east_rounded,

                color:
                    incoming
                        ? moduleGreen
                        : moduleOrange,
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
                    CrossAxisAlignment
                        .start,

                children:
                    <Widget>[

                  Text(
                    item.title,

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
                    '${item.referenceNo}'
                    '${item.reference.isEmpty ? '' : ' • ${item.reference}'}',

                    style:
                        const TextStyle(
                      color:
                          moduleMuted,

                      fontSize:
                          10,
                    ),
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
                          10,
                    ),
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
                  '${incoming ? '-' : '+'} ₹${amount.toStringAsFixed(0)}',

                  style:
                      TextStyle(
                    color:
                        incoming
                            ? moduleGreen
                            : moduleOrange,

                    fontWeight:
                        FontWeight
                            .w900,
                  ),
                ),

                Text(
                  'Bal ₹${item.balance.toStringAsFixed(0)}',

                  style:
                      const TextStyle(
                    color:
                        moduleMuted,

                    fontSize:
                        9,

                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerParty {
  const _LedgerParty({
    required this.id,
    required this.name,
  });

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
    required this.paymentMode,
    required this.reference,
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

  final String paymentMode;
  final String reference;
}