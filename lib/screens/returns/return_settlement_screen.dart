import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../common/access_denied_screen.dart';


class ReturnSettlementScreen extends StatefulWidget {
  const ReturnSettlementScreen({super.key, this.allocation});

  /// When opened from Allocation -> Take Return, this contains the selected
  /// allocation and the settlement form opens directly.
  ///
  /// When opened from the Return menu without an allocation, the screen first
  /// shows the current allocation list and lets the user select one.
  final Map<String, dynamic>? allocation;

  @override
  State<ReturnSettlementScreen> createState() => _ReturnSettlementScreenState();
}

class _ReturnSettlementScreenState extends State<ReturnSettlementScreen> {
  static const Color primaryBlue = AppColors.primary;
  static const Color darkBlue = AppColors.primaryDeep;
  static const Color pageBackground = AppColors.background;
  static const Color borderColor = AppColors.primaryBorder;
  static const Color textDark = AppColors.textPrimary;
  static const Color green = AppColors.success;
  static const Color orange = AppColors.warning;

Map<String, dynamic>? _selectedAllocation;

DateTime _listDate =
    DateTime.now();

bool _isSaving = false;

bool _isLoadingAllocations = false;

String _allocationLoadError = '';

final List<Map<String, dynamic>>
    _allocations = [];

  final TextEditingController reasonController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController soldController = TextEditingController();
  final TextEditingController goodReturnController = TextEditingController();
  final TextEditingController damageController = TextEditingController();
  final TextEditingController shortExcessController = TextEditingController();
  final TextEditingController cashReceivedController = TextEditingController();
  final TextEditingController onlineReceivedController =
      TextEditingController();
  final TextEditingController creditSalesController = TextEditingController();

  int selectedReturnType = 0;

  final List<Map<String, dynamic>> returnTypes = const [
    {'title': 'Good /\nResalable', 'icon': Icons.local_drink_outlined},
    {'title': 'Damaged /\nLeakage', 'icon': Icons.inventory_2_outlined},
    {'title': 'Expired /\nSpoiled', 'icon': Icons.delete_outline},
    {'title': 'Customer\nRejection', 'icon': Icons.change_circle_outlined},
    {'title': 'Other', 'icon': Icons.note_alt_outlined},
  ];

 @override
void initState() {
  super.initState();

  _selectedAllocation =
      widget.allocation;

  if (_selectedAllocation != null) {

    final rawDate =
        _selectedAllocation!['date'];

    if (rawDate is DateTime) {
      _listDate = rawDate;
    }

    _loadSettlement(
      _selectedAllocation!,
    );
  } else {

    _loadAllocations();
  }
}
Future<void> _loadAllocations() async {

  if (_isLoadingAllocations) {
    return;
  }

  setState(() {
    _isLoadingAllocations = true;
    _allocationLoadError = '';
  });


  try {

    final response =
        await http.get(

      Uri.parse(
        '${ApiConfig.baseUrl}/api/allocations',
      ),

      headers: {

        'Content-Type':
            'application/json',

        if (ApiConfig.token != null &&
            ApiConfig.token!.isNotEmpty)

          'Authorization':
              'Bearer ${ApiConfig.token}',
      },
    );


    final decoded =
        jsonDecode(response.body);


    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map ||
        decoded['success'] != true) {

      throw Exception(
        decoded is Map
            ? (decoded['message'] ??
                    'Unable to load allocations.')
                .toString()
            : 'Unable to load allocations.',
      );
    }


    final rawData =
        decoded['data'];


    final List<Map<String, dynamic>>
        loaded = [];


    if (rawData is List) {

      for (final rawAllocation in rawData) {

        if (rawAllocation is! Map) {
          continue;
        }


        final allocation =
            Map<String, dynamic>.from(
              rawAllocation,
            );


        final allocationId =
            (allocation['allocationId'] ?? '')
                .toString();


        final allocationNo =
            (allocation['allocationNo'] ?? '')
                .toString();


        final salesmanId =
            (allocation['salesmanId'] ?? '')
                .toString();


        final salesmanName =
            (allocation['salesmanName'] ?? '')
                .toString();


        final routeId =
            (allocation['routeId'] ?? '')
                .toString();


        final routeName =
            (allocation['routeName'] ?? '')
                .toString();


        DateTime allocationDate =
            DateTime.now();


        final rawDate =
            allocation['allocationDate'];


        if (rawDate != null) {

          allocationDate =
              DateTime.tryParse(
                rawDate.toString(),
              ) ??
              DateTime.now();
        }


        final products =
            allocation['products'];


        if (products is! List) {
          continue;
        }


        for (final rawProduct in products) {

          if (rawProduct is! Map) {
            continue;
          }


          final product =
              Map<String, dynamic>.from(
                rawProduct,
              );


          loaded.add({

            'allocationId':
                allocationId,

            'allocationNo':
                allocationNo,

            'date':
                allocationDate,

            'salesmanId':
                salesmanId,

            'salesman':
                salesmanName,

            'routeId':
                routeId,

            'route':
                routeName,

            'productId':
                (product['productId'] ?? '')
                    .toString(),

            'product':
                (product['productName'] ?? '')
                    .toString(),

            'variant':
                (product['variant'] ?? '')
                    .toString(),

            'unit':
                (product['unit'] ?? '')
                    .toString(),

            'qty':
                _asInt(
                  product['quantity'],
                ),

            'soldQty':
                _asInt(
                  product[
                    'soldQuantity'
                  ],
                ),

            'returnedQty':
                _asInt(
                  product[
                    'returnedQuantity'
                  ],
                ),

            'remainingQty':
                _asInt(
                  product[
                    'remainingQuantity'
                  ],
                ),
                'salesValue':
    _asDouble(
      product['salesValue'],
    ),

'cashSales':
    _asDouble(
      product['cashSales'],
    ),

'onlineSales':
    _asDouble(
      product['onlineSales'],
    ),

'creditSales':
    _asDouble(
      product['creditSales'],
    ),

            'allocationStatus':
                (allocation['status'] ?? '')
                    .toString(),
          });
        }
      }
    }


    if (!mounted) {
      return;
    }


    setState(() {

      _allocations
        ..clear()
        ..addAll(loaded);

      _isLoadingAllocations =
          false;
    });


  } catch (error) {

    if (!mounted) {
      return;
    }


    String message =
        error.toString();


    if (message.startsWith(
      'Exception: ',
    )) {

      message =
          message.substring(11);
    }


    setState(() {

      _isLoadingAllocations =
          false;

      _allocationLoadError =
          message;
    });
  }
}


  @override
  void dispose() {
    reasonController.dispose();
    remarksController.dispose();
    soldController.dispose();
    goodReturnController.dispose();
    damageController.dispose();
    shortExcessController.dispose();
    cashReceivedController.dispose();
    onlineReceivedController.dispose();
    creditSalesController.dispose();
    super.dispose();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic>? get _settlement {
    final raw = _selectedAllocation?['settlement'];
    return raw is Map<String, dynamic> ? raw : null;
  }

  bool get _isEditing => _settlement != null;

  int get _allocatedQty => _asInt(_selectedAllocation?['qty']);
  int get _soldQty => _asInt(soldController.text);
  int get _goodReturnQty => _asInt(goodReturnController.text);
  int get _damageQty => _asInt(damageController.text);
  int get _shortExcessQty => _asInt(shortExcessController.text);

  int get _newReturnQty => _goodReturnQty + _damageQty;

  int get _accountedQty =>
      _soldQty + _goodReturnQty + _damageQty + _shortExcessQty;

  int get _differenceQty => _allocatedQty - _accountedQty;

double get _salesValue =>
    _asDouble(
      _selectedAllocation?[
        'salesValue'
      ],
    );

  double get _cashReceived => _asDouble(cashReceivedController.text);
  double get _onlineReceived => _asDouble(onlineReceivedController.text);
  double get _creditSales => _asDouble(creditSalesController.text);

  double get _collectionDifference =>
      _salesValue - (_cashReceived + _onlineReceived + _creditSales);

  void _loadSettlement(Map<String, dynamic> allocation) {
    final rawSettlement = allocation['settlement'];
    final settlement = rawSettlement is Map<String, dynamic>
        ? rawSettlement
        : null;

    final qty = _asInt(allocation['qty']);
    final alreadyReturned = _asInt(allocation['returnedQty']);

    selectedReturnType = _asInt(settlement?['returnType']);
    if (selectedReturnType < 0 || selectedReturnType >= returnTypes.length) {
      selectedReturnType = 0;
    }

 final soldQty = _asInt(allocation['soldQty']);

soldController.text = '$soldQty';
goodReturnController.text = '0';

damageController.text = '0';
    shortExcessController.text = '${_asInt(settlement?['shortExcessQty'])}';

    reasonController.text = (settlement?['reason'] ?? '').toString();
    remarksController.text = (settlement?['remarks'] ?? '').toString();

 cashReceivedController.text =
    _asDouble(
      allocation['cashSales'],
    ).toStringAsFixed(2);

onlineReceivedController.text =
    _asDouble(
      allocation['onlineSales'],
    ).toStringAsFixed(2);

creditSalesController.text =
    _asDouble(
      allocation['creditSales'],
    ).toStringAsFixed(2);
  }

  void _selectAllocation(Map<String, dynamic> allocation) {
    setState(() {
      _selectedAllocation = allocation;
      _loadSettlement(allocation);
    });
  }

  void _backToAllocationList() {
    if (widget.allocation != null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _selectedAllocation = null;
    });
  }

List<Map<String, dynamic>>
    get _currentAllocations {

  final items =
      _allocations.where((item) {

    final rawDate =
        item['date'];

    if (rawDate is! DateTime) {
      return false;
    }


    return (
      rawDate.year ==
          _listDate.year &&
      rawDate.month ==
          _listDate.month &&
      rawDate.day ==
          _listDate.day
    );
  }).toList();


  items.sort((a, b) {

    final aRemaining =
        _asInt(
          a['remainingQty'],
        );

    final bRemaining =
        _asInt(
          b['remainingQty'],
        );


    // Pending returns first
    if (aRemaining > 0 &&
        bRemaining <= 0) {
      return -1;
    }

    if (aRemaining <= 0 &&
        bRemaining > 0) {
      return 1;
    }


    return 0;
  });


  return items;
}

  Future<void> _pickListDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _listDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() => _listDate = picked);
  }

  String _formatAllocationDate(dynamic rawDate) {
    if (rawDate is! DateTime) return '-';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${rawDate.day.toString().padLeft(2, '0')} '
        '${months[rawDate.month - 1]} ${rawDate.year} '
        '(${days[rawDate.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    if (!UiSession.instance.can(AppPermission.returnsManage)) {
      return const AccessDeniedScreen();
    }

    if (_selectedAllocation == null) {
      return _buildAllocationSelectionScreen();
    }

    return _buildSettlementScreen();
  }

  // ===========================================================================
  // RETURN MENU -> ALLOCATION SELECTION
  // ===========================================================================

  Widget _buildAllocationSelectionScreen() {
    final items = _currentAllocations;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildReturnListHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 14),
                  _buildReturnListSummary(items),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      'Current Allotment Entries',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  if (items.isEmpty)
                    _buildEmptyAllocationState()
                  else
                    ...items.map(_buildSelectableAllocationCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnListHeader() {
    return SizedBox(
      height: 130,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0647C8), Color(0xFF1371E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/img/ReturnHeader.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF063FBE).withOpacity(0.94),
                  const Color(0xFF064BCB).withOpacity(0.65),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 12,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 31,
                color: Colors.white,
              ),
            ),
          ),
          const Positioned(
            left: 62,
            top: 23,
            right: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Returns',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Select an allotment to take or edit return',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _pickListDate,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatAllocationDate(_listDate),
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF667085),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnListSummary(List<Map<String, dynamic>> items) {
    int totalQty = 0;
    int returned = 0;
    int settled = 0;

    for (final item in items) {
      totalQty += _asInt(item['qty']);
      returned += _asInt(item['returnedQty']);
      if (item['settlement'] != null) settled++;
    }

    return Row(
      children: [
        Expanded(
          child: _summaryMiniCard(
            title: 'Entries',
            value: '${items.length}',
            background: const Color(0xFFE8F3FF),
            foreground: primaryBlue,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _summaryMiniCard(
            title: 'Allocated',
            value: '$totalQty L',
            background: const Color(0xFFF2F7FF),
            foreground: darkBlue,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _summaryMiniCard(
            title: 'Returned',
            value: '$returned L',
            background: const Color(0xFFE7FAF0),
            foreground: green,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _summaryMiniCard(
            title: 'Settled',
            value: '$settled',
            background: const Color(0xFFFFF4E6),
            foreground: const Color(0xFFB35A00),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableAllocationCard(Map<String, dynamic> item) {
final qty =
    _asInt(item['qty']);

final sold =
    _asInt(item['soldQty']);

final returned =
    _asInt(item['returnedQty']);

final balance =
    _asInt(item['remainingQty']);

final String unit =
    (item['unit'] ?? '')
        .toString();
final hasSettlement =
    returned > 0;

final bool isCompleted =
    balance <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectAllocation(item),
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasSettlement
                      ? Icons.edit_note_rounded
                      : Icons.inventory_2_outlined,
                  color: primaryBlue,
                  size: 27,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['salesman']} • ${item['route']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item['product']}  |  $qty $unit allocated',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                   _statusPill(
  isCompleted
      ? 'Completed'
      : returned > 0
          ? 'Part Return'
          : 'Pending Return',

  isCompleted
      ? green
      : returned > 0
          ? primaryBlue
          : orange,
),
                        _statusPill(
                        'Balance $balance $unit',
                          balance <= 0 ? green : primaryBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Icon(
                    hasSettlement
                        ? Icons.edit_rounded
                        : Icons.arrow_forward_rounded,
                    color: primaryBlue,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasSettlement ? 'Edit' : 'Open',
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyAllocationState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: primaryBlue, size: 40),
          SizedBox(height: 10),
          Text(
            'No allotment entries for this date',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Choose another date or create an allocation first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF667085), fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SETTLEMENT SCREEN
  // ===========================================================================

  Widget _buildSettlementScreen() {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSettlementHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                child: Column(
                  children: [
                    _buildAllocationSummary(),
                    const SizedBox(height: 14),
                    _buildProductReconciliation(),
                    const SizedBox(height: 14),
                    _buildReturnClassification(),
                    const SizedBox(height: 14),
                    _buildFinancialSettlement(),
                    const SizedBox(height: 14),
                    _buildBottomSummary(),
                    const SizedBox(height: 14),
                    _buildRemarks(),
                    const SizedBox(height: 18),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementHeader() {
    return SizedBox(
      height: 145,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0647C8), Color(0xFF1371E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/img/ReturnHeader.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF063FBE).withOpacity(0.92),
                  const Color(0xFF064BCB).withOpacity(0.58),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 12,
            child: IconButton(
              onPressed: _backToAllocationList,
              icon: const Icon(Icons.arrow_back, size: 32, color: Colors.white),
            ),
          ),
          Positioned(
            left: 62,
            top: 23,
            right: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Edit Allocation Settlement'
                      : 'Allocation Settlement',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isEditing
                      ? 'Update saved return / settlement details'
                      : 'Return / Reconcile Milk Allocation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationSummary() {
    final allocation = _selectedAllocation!;
    final salesman = (allocation['salesman'] ?? '').toString();
    final route = (allocation['route'] ?? '').toString();
    final product = (allocation['product'] ?? '').toString();

    return _sectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.engineering,
                  color: primaryBlue,
                  size: 31,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$salesman – $route',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$product • ${_formatAllocationDate(allocation['date'])}',
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475467),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isEditing) _statusPill('EDIT MODE', primaryBlue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryMiniCard(
                  title: 'Allocated',
                  value: '$_allocatedQty L',
                  background: const Color(0xFFE8F3FF),
                  foreground: primaryBlue,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _summaryMiniCard(
                  title: 'Return',
                  value: '$_newReturnQty L',
                  background: const Color(0xFFE7FAF0),
                  foreground: green,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _summaryMiniCard(
                  title: 'Difference',
                  value: '${_differenceQty.abs()} L',
                  background: _differenceQty == 0
                      ? const Color(0xFFE7FAF0)
                      : const Color(0xFFFFEEEE),
                  foreground: _differenceQty == 0
                      ? green
                      : const Color(0xFFB42318),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMiniCard({
    required String title,
    required String value,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD5E5F8)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: foreground,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductReconciliation() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.inventory_2_outlined,
            title: 'Product Reconciliation',
            trailing: 'Editable',
          ),
          const SizedBox(height: 10),
          Text(
            (_selectedAllocation?['product'] ?? '').toString(),
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _qtyBox(
                  label: 'Issued',
                  valueText: '$_allocatedQty',
                  enabled: false,
                ),
              ),
              const SizedBox(width: 7),
            Expanded(
  child: _qtyBox(
    label: 'Sold',
    controller: soldController,
    enabled: false,
  ),
),
              const SizedBox(width: 7),
              Expanded(
                child: _qtyBox(
                  label: 'Good Return',
                  controller: goodReturnController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _qtyBox(label: 'Damage', controller: damageController),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _qtyBox(
                  label: 'Short / Excess',
                  controller: shortExcessController,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Container(
                  height: 66,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: _differenceQty == 0
                        ? const Color(0xFFE7FAF0)
                        : const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _differenceQty == 0
                          ? const Color(0xFFB6EFD3)
                          : const Color(0xFFFFB4AB),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Balance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_differenceQty.abs()} L',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _differenceQty == 0
                              ? green
                              : const Color(0xFFB42318),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: _differenceQty == 0
                  ? const Color(0xFFE4FBF0)
                  : const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Icon(
                  _differenceQty == 0
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: _differenceQty == 0 ? green : orange,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _differenceQty == 0
                        ? 'Allocation quantity is fully reconciled.'
                        : '$_differenceQty L is still unreconciled. You can save a draft, but complete only when balanced.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBox({
    required String label,
    TextEditingController? controller,
    String? valueText,
    bool enabled = true,
  }) {
    return SizedBox(
      height: 66,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: valueText,
          floatingLabelAlignment: FloatingLabelAlignment.center,
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF4F7FB),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
        ),
        style: const TextStyle(
          color: textDark,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildReturnClassification() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.keyboard_return,
            title: 'Return Classification',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 91,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: returnTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final item = returnTypes[index];
                final selected = selectedReturnType == index;

                return InkWell(
                  onTap: () => setState(() => selectedReturnType = index),
                  borderRadius: BorderRadius.circular(13),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 112,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE0EEFF) : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: selected ? const Color(0xFF4194FF) : borderColor,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: primaryBlue,
                          size: 21,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item['title'].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Reason for Return / Damage / Shortage',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 26),
                child: Icon(Icons.chat_bubble_outline, color: primaryBlue),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: primaryBlue, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSettlement() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.currency_rupee,
            title: 'Financial Settlement',
          ),
          const SizedBox(height: 12),
          _financialInfoRow(
            'Sales Value',
            '₹ ${_salesValue.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _moneyField(
  label: 'Cash',
  controller:
      cashReceivedController,
  enabled: false,
),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _moneyField(
  label: 'Online',
  controller:
      onlineReceivedController,
  enabled: false,
),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _moneyField(
  label: 'Credit',
  controller:
      creditSalesController,
  enabled: false,
),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: _collectionDifference.abs() < 0.001
                  ? const Color(0xFFE5F9EC)
                  : const Color(0xFFFFE9E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _collectionDifference.abs() < 0.001
                    ? const Color(0xFFB5EBC7)
                    : const Color(0xFFFFB2B2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _collectionDifference.abs() < 0.001
                      ? Icons.check_circle_outline
                      : Icons.balance,
                  color: _collectionDifference.abs() < 0.001
                      ? green
                      : const Color(0xFFA61B1B),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Collection Difference',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '₹ ${_collectionDifference.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _collectionDifference.abs() < 0.001
                        ? green
                        : const Color(0xFFCA0909),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7E3F2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

Widget _moneyField({
  required String label,
  required TextEditingController controller,
  bool enabled = true,
}) {
 return TextField(
  controller: controller,
  enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: primaryBlue, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildBottomSummary() {
    final data = [
      ['Issued', '$_allocatedQty L', Icons.inventory_2_outlined, darkBlue],
      ['Sold', '$_soldQty L', Icons.shopping_cart_outlined, primaryBlue],
      ['Good Return', '$_goodReturnQty L', Icons.keyboard_return, green],
      ['Damage', '$_damageQty L', Icons.warning_amber_outlined, orange],
      [
        'Balance',
        '${_differenceQty.abs()} L',
        _differenceQty == 0 ? Icons.check_circle : Icons.warning,
        _differenceQty == 0 ? green : const Color(0xFFB10606),
      ],
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE5FAEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8EBCB)),
      ),
      child: Row(
        children: List.generate(data.length, (index) {
          final item = data[index];
          return Expanded(
            child: Column(
              children: [
                Icon(item[2] as IconData, size: 18, color: item[3] as Color),
                const SizedBox(height: 4),
                Text(
                  item[0] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item[1] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRemarks() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(icon: Icons.chat_outlined, title: 'Remarks'),
          const SizedBox(height: 11),
          TextField(
            controller: remarksController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Enter settlement remarks...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: primaryBlue, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton.icon(
             onPressed: _isSaving
    ? null
    : () async {
        await _saveSettlement(
          completed: false,
        );
      },
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _isEditing ? 'Update Return' : 'Save Return',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
             onPressed:
    _isSaving
        ? null
        : _completeSettlement,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Complete Settlement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    String? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: primaryBlue, size: 23),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Map<String, dynamic> _buildSettlementResult(String status) {
    return {
      'status': status,
      'returnType': selectedReturnType,
      'soldQty': _soldQty,
      'goodReturnQty': _goodReturnQty,
      'damageQty': _damageQty,
      'shortExcessQty': _shortExcessQty,
      'returnedQty': _newReturnQty,
      'reason': reasonController.text.trim(),
      'remarks': remarksController.text.trim(),
      'cashReceived': _cashReceived,
      'onlineReceived': _onlineReceived,
      'creditSales': _creditSales,
      'salesValue': _salesValue,
      'updatedAt': DateTime.now(),
    };
  }

Future<void> _saveSettlement({
  required bool completed,
}) async {
  final allocation = _selectedAllocation;

  if (allocation == null) return;
  if (_isSaving) return;

  // =========================================================
  // BASIC VALIDATION
  // =========================================================

  if (_goodReturnQty < 0 ||
      _damageQty < 0 ||
      _shortExcessQty < 0) {
    _showMessage('Quantity cannot be negative.');
    return;
  }

  final allocationId =
      (allocation['allocationId'] ?? '').toString().trim();

  final productId =
      (allocation['productId'] ?? '').toString().trim();

  if (allocationId.isEmpty) {
    _showMessage('Allocation ID not found.');
    return;
  }

  if (productId.isEmpty) {
    _showMessage('Product ID not found.');
    return;
  }

  final returnQty = _goodReturnQty + _damageQty;

  final availableQty =
      _asInt(allocation['remainingQty']);

  if (returnQty <= 0) {
    _showMessage('Please enter return quantity.');
    return;
  }

  if (returnQty > availableQty) {
    _showMessage(
      'Return quantity cannot exceed available quantity $availableQty.',
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/allocations/$allocationId/return',
    );

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (ApiConfig.token != null &&
            ApiConfig.token!.isNotEmpty)
          'Authorization': 'Bearer ${ApiConfig.token}',
      },
      body: jsonEncode({
        'productId': productId,
        'goodReturnQty': _goodReturnQty,
        'damageQty': _damageQty,
        'shortExcessQty': _shortExcessQty,
        'returnType': selectedReturnType,
        'reason': reasonController.text.trim(),
        'remarks': remarksController.text.trim(),
      }),
    );

    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Unable to save return.').toString(),
      );
    }

    final rawData = body['data'];

    if (rawData is! Map) {
      throw Exception(
        'Invalid return response from server.',
      );
    }

    final data =
        Map<String, dynamic>.from(rawData);

    // =========================================================
    // USE VALUES RETURNED BY BACKEND
    // =========================================================

    final returnedQty =
        _asInt(data['returnedQuantity']);

    final soldQty =
        _asInt(data['soldQuantity']);

    final remainingQty =
        _asInt(data['remainingQuantity']);

    final result = <String, dynamic>{
      'status':
          completed ? 'completed' : 'saved',

      'returnType':
          selectedReturnType,

      'soldQty':
          soldQty,

      'goodReturnQty':
          _asInt(data['goodReturnQuantity']),

      'damageQty':
          _asInt(data['damageQuantity']),

      'shortExcessQty':
          _asInt(data['shortExcessQuantity']),

      'returnedQty':
          returnedQty,

      'remainingQty':
          remainingQty,

      'reason':
          reasonController.text.trim(),

      'remarks':
          remarksController.text.trim(),

      'cashReceived':
          _cashReceived,

      'onlineReceived':
          _onlineReceived,

      'creditSales':
          _creditSales,

      'salesValue':
          _salesValue,

      'updatedAt':
          DateTime.now(),
    };

    if (!mounted) return;

    setState(() {
      allocation['soldQty'] =
          soldQty;

      allocation['returnedQty'] =
          returnedQty;

      allocation['remainingQty'] =
          remainingQty;

      allocation['settlement'] =
          result;
    });

    // Opened from Allocation screen
    if (widget.allocation != null) {
      Navigator.pop<Map<String, dynamic>>(
        context,
        result,
      );

      return;
    }

    _showMessage(
      completed
          ? 'Allocation settlement completed successfully.'
          : 'Return saved successfully.',
    );

    setState(() {
      _selectedAllocation = null;
    });
  } catch (error) {
    if (!mounted) return;

    String message = error.toString();

    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }

    _showMessage(message);
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}

  void _completeSettlement() {
    if (_differenceQty != 0) {
      _showMessage(
        'Allocation is not balanced. Difference is ${_differenceQty.abs()} L. '
        'Correct Sold / Return / Damage / Short-Excess before completing.',
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: green),
              SizedBox(width: 8),
              Expanded(child: Text('Complete Settlement')),
            ],
          ),
          content: const Text(
            'Are you sure you want to complete this allocation settlement? '
            'You can still open it later using Edit Settlement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
          onPressed: () async {
  Navigator.pop(dialogContext);

  await _saveSettlement(
    completed: true,
  );
},
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
