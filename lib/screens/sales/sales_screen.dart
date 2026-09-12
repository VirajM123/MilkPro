import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../theme/app_colors.dart';

import '../../models/access_models.dart';
import '../../models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_sync_service.dart';
import 'sales_bill_preview_screen.dart';
import 'sales_report_preview_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with WidgetsBindingObserver {
  static const Color _primary = AppColors.primary;
  static const Color _dark = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _green = AppColors.success;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  // ============================================================
  // SALE PAYMENT BREAKUP
  // ============================================================

  final TextEditingController _cashPaymentController = TextEditingController();

  final TextEditingController _upiPaymentController = TextEditingController();

  final TextEditingController _bankPaymentController = TextEditingController();

  late DateTime _selectedDate;
  Map<String, dynamic>? _selectedAllocation;
  String _paymentMode = 'Credit';
  final List<_SaleLineDraft> _cart = <_SaleLineDraft>[];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();
  bool _isCreatingSale = false;

  // ============================================================
  // EDIT SALE STATE
  // ============================================================

  bool _isEditingSale = false;

  String? _editingSaleId;
  String? _editingSaleNo;

  bool _showSearch = false;
  _SalesPeriod _selectedPeriod = _SalesPeriod.all;
  final List<Map<String, dynamic>> _customers = <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> _saleProducts = <Map<String, dynamic>>[];

  final List<SaleModel> _serverSales = <SaleModel>[];
  final Set<String> _cancelledSaleIds = <String>{};

  bool _cancellingSale = false;

  Map<String, dynamic>? _selectedCustomer;

  bool _loadingCustomers = false;
  bool _loadingProducts = false;
  bool _loadingSales = false;
  bool _savingSale = false;
  bool _syncing = false;
  Timer? _pollTimer;
  int _salesRequestToken = 0;
  // ============================================================
// CURRENT USER
// ============================================================

bool get _isSalesman =>
    UiSession.instance.currentUser.role ==
    UserRole.salesman;

  final List<String> _paymentModes = const <String>[
    'Cash',
    'UPI',
    'Credit',
    'Bank Transfer',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    DataSyncService.instance.addListener(_onDataSyncChanged);

    _selectedDate = DateTime.now();

    _quantityController.addListener(_refreshTotal);
    _rateController.addListener(_refreshTotal);
    _cashPaymentController.addListener(_refreshTotal);

    _upiPaymentController.addListener(_refreshTotal);

    _bankPaymentController.addListener(_refreshTotal);

    _loadCustomers();
    _loadSales();

    _pollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted && !_loadingSales && !_syncing) {
        _loadSalesSilent();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    DataSyncService.instance.removeListener(_onDataSyncChanged);

    _quantityController.removeListener(_refreshTotal);
    _rateController.removeListener(_refreshTotal);
    _customerController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _searchController.dispose();
    _productSearchController.dispose();
    _cashPaymentController.removeListener(_refreshTotal);

    _upiPaymentController.removeListener(_refreshTotal);

    _bankPaymentController.removeListener(_refreshTotal);

    _cashPaymentController.dispose();

    _upiPaymentController.dispose();

    _bankPaymentController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        !_loadingSales &&
        !_syncing) {
      _loadSalesSilent();
    }
  }

  void _onDataSyncChanged() {
    final event = DataSyncService.instance.lastEventType;
    if (event == SyncEventType.allocation ||
        event == SyncEventType.returnSettlement ||
        event == SyncEventType.sale ||
        event == SyncEventType.all) {
      if (mounted && !_loadingSales && !_syncing) {
        _loadSalesSilent();
        if (_selectedCustomer != null) {
          _loadCustomerProductsSilent();
        }
      }
    }
  }

  Future<void> _loadSalesSilent() async {
    if (_loadingSales || !mounted) return;
    try {
      await _loadSales();
    } catch (e) {
      debugPrint('Sales silent sync error: $e');
    }
  }

  Future<void> _loadCustomerProductsSilent() async {
    if (_loadingProducts || !mounted || _selectedCustomer == null) return;
    try {
      await _loadCustomerProducts();
    } catch (e) {
      debugPrint('Customer products silent sync error: $e');
    }
  }

  Future<void> _handleManualSync() async {
    if (_syncing || _loadingSales) return;
    setState(() => _syncing = true);
    try {
      await _loadSales();
      if (_selectedCustomer != null) {
        await _loadCustomerProducts();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced successfully'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to sync. Please try again.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }
void _clearSalePayments() {
  _cashPaymentController.clear();
  _upiPaymentController.clear();
  _bankPaymentController.clear();

  _paymentMode = 'Credit';
}

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Map<String, dynamic>> get _dayAllocations {
    return _saleProducts;
  }

  int _soldFor(Map<String, dynamic> allocation) =>
      _asInt(allocation['soldQty']);

  int _availableFor(Map<String, dynamic> allocation) {
    final value =
        _asInt(allocation['qty']) -
        _asInt(allocation['returnedQty']) -
        _soldFor(allocation);
    return value < 0 ? 0 : value;
  }

  int _cartQuantityFor(Map<String, dynamic> allocation) {
    return _cart
        .where((line) => identical(line.allocation, allocation))
        .fold(0, (sum, line) => sum + line.quantity);
  }

  int _remainingFor(Map<String, dynamic> allocation) {
    final remaining = _availableFor(allocation) - _cartQuantityFor(allocation);
    return remaining < 0 ? 0 : remaining;
  }

  int get _availableToAdd =>
      _selectedAllocation == null ? 0 : _remainingFor(_selectedAllocation!);

  double get _draftTotal {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    return quantity * rate;
  }

  double get _cartTotal => _cart.fold(0, (sum, line) => sum + line.total);
  double _paymentValue(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  double get _cashPayment => _paymentValue(_cashPaymentController);

  double get _upiPayment => _paymentValue(_upiPaymentController);

  double get _bankPayment => _paymentValue(_bankPaymentController);

 double get _paidAmount =>
    _cashPayment +
    _upiPayment +
    _bankPayment;


// ============================================================
// CUSTOMER CURRENT ADVANCE BALANCE
//
// Backend:
// MAS_CUSTOMER.balance = available customer advance
// ============================================================

double get _customerAdvanceBalance {
  final customer = _selectedCustomer;

  if (customer == null) {
    return 0;
  }

  final balance =
      double.tryParse(
        customer['balance']
                ?.toString() ??
            '0',
      ) ??
      0;

  return balance < 0
      ? 0
      : balance;
}


// ============================================================
// ADVANCE AVAILABLE FOR CURRENT SALE
//
// CREATE:
// Use current customer.balance.
//
// EDIT:
// Backend first restores the advanceUsed from the original
// bill before recalculating it.
//
// We will add that edit-specific value after adding
// advanceUsed to SaleModel.
// ============================================================

double get _availableAdvanceForSale {
  double available =
      _customerAdvanceBalance;

  // During edit, backend restores the advance
  // originally consumed by this sale before
  // recalculating the edited bill.
  if (_isEditingSale &&
      _editingSaleId != null) {
    SaleModel? editingSale;

    for (final sale in _serverSales) {
      if (sale.id == _editingSaleId ||
          sale.saleId == _editingSaleId) {
        editingSale = sale;
        break;
      }
    }

    if (editingSale != null &&
        editingSale.customerId ==
            (_selectedCustomer?['customerId']
                    ?.toString() ??
                '')) {
      available +=
          editingSale.advanceUsed;
    }
  }

  return available;
}


// ============================================================
// BILL AMOUNT REMAINING AFTER CURRENT PAYMENT
// ============================================================

double get _amountAfterImmediatePayment {
  final value =
      _cartTotal -
      _paidAmount;

  return value < 0
      ? 0
      : value;
}


// ============================================================
// CUSTOMER ADVANCE THAT WILL BE USED
// ============================================================

double get _advanceUsedPreview {
  final due =
      _amountAfterImmediatePayment;

  final available =
      _availableAdvanceForSale;

  if (due <= 0 ||
      available <= 0) {
    return 0;
  }

  return available < due
      ? available
      : due;
}


// ============================================================
// FINAL OUTSTANDING PREVIEW
// ============================================================

double get _outstandingAmount {
  final amount =
      _amountAfterImmediatePayment -
      _advanceUsedPreview;

  return amount < 0
      ? 0
      : amount;
}


bool get _isPaymentOverAmount =>
    _paidAmount >
    _cartTotal;


// ============================================================
// PAYMENT STATUS PREVIEW
// ============================================================

String get _calculatedPaymentStatus {
  if (_cartTotal <= 0) {
    return 'PAID';
  }

  if (_outstandingAmount <= 0.001) {
    return 'PAID';
  }

  if (_paidAmount <= 0.001 &&
      _advanceUsedPreview <=
          0.001) {
    return 'CREDIT';
  }

  return 'PARTIAL';
}

  String get _calculatedPaymentMode {
    if (_paidAmount <= 0) {
      return 'Credit';
    }

    final activePaymentCount = [
      _cashPayment,
      _upiPayment,
      _bankPayment,
    ].where((amount) => amount > 0).length;

    // Partial payment always has an unpaid portion,
    // therefore display it as Split.
    if (_paidAmount < _cartTotal) {
      return 'Split';
    }

    if (activePaymentCount > 1) {
      return 'Split';
    }

    if (_cashPayment > 0) {
      return 'Cash';
    }

    if (_upiPayment > 0) {
      return 'UPI';
    }

    if (_bankPayment > 0) {
      return 'Bank Transfer';
    }

    return 'Credit';
  }

  List<Map<String, dynamic>> get _paymentBreakup {
    final payments = <Map<String, dynamic>>[];

    if (_cashPayment > 0) {
      payments.add({'mode': 'Cash', 'amount': _cashPayment, 'referenceNo': ''});
    }

    if (_upiPayment > 0) {
      payments.add({'mode': 'UPI', 'amount': _upiPayment, 'referenceNo': ''});
    }

    if (_bankPayment > 0) {
      payments.add({
        'mode': 'Bank Transfer',
        'amount': _bankPayment,
        'referenceNo': '',
      });
    }

    return payments;
  }

  int get _cartQuantity => _cart.fold(0, (sum, line) => sum + line.quantity);

  void _selectFirstAvailableAllocation() {
    final allocations = _dayAllocations;
    Map<String, dynamic>? selection;
    for (final item in allocations) {
      if (_availableFor(item) > 0) {
        selection = item;
        break;
      }
    }
    selection ??= allocations.isEmpty ? null : allocations.first;
    _selectedAllocation = selection;
    _setSuggestedRate();
  }

  void _setSuggestedRate() {
    final product = (_selectedAllocation?['product'] ?? '').toString();
    _rateController.text = _suggestedRateFor(product).toStringAsFixed(0);
  }

  double _suggestedRateFor(String product) {
    for (final item in _saleProducts) {
      if ((item['product'] ?? '').toString() == product) {
        return double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
      }
    }

    return 0;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (date == null || !mounted) return;
    setState(() {
      _selectedDate = date;
      _cart.clear();
    });
  }

  void _showMessage(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  Future<void> _loadSales() async {
    if (!mounted) return;
    final int requestToken = ++_salesRequestToken;

    setState(() {
      _loadingSales = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.sales),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        final records = data['data'] as List<dynamic>? ?? <dynamic>[];

        final loadedSales = <SaleModel>[];

        final cancelledIds = <String>{};

        for (final record in records) {
          final sale = Map<String, dynamic>.from(record as Map);
          final saleIdentifier =
              sale['saleNo']?.toString() ??
              sale['saleId']?.toString() ??
              sale['_id']?.toString() ??
              '';

          final status = sale['status']?.toString().toUpperCase() ?? 'POSTED';

          if (status == 'CANCELLED' && saleIdentifier.isNotEmpty) {
            cancelledIds.add(saleIdentifier);
          }

          final rawProducts = sale['products'] as List<dynamic>? ?? <dynamic>[];

          final List<SaleProductModel> billProducts = <SaleProductModel>[];

          for (final item in rawProducts) {
            if (item is! Map) {
              continue;
            }

            final product = Map<String, dynamic>.from(item);

            final quantity =
                int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

            final rate =
                double.tryParse(product['rate']?.toString() ?? '0') ?? 0;

            final amount =
                double.tryParse(product['amount']?.toString() ?? '') ??
                (quantity * rate);

            billProducts.add(
              SaleProductModel(
                productId: product['productId']?.toString() ?? '',

                productName: product['productName']?.toString() ?? '',

                variant: product['variant']?.toString() ?? '',

                unit: product['unit']?.toString() ?? 'Pcs',

                quantity: quantity,

                defaultRate:
                    double.tryParse(
                      product['defaultRate']?.toString() ?? '0',
                    ) ??
                    0,

                rate: rate,

                rateSource: product['rateSource']?.toString() ?? 'PRODUCT_RATE',

                amount: amount,
              ),
            );
          }

          final saleDate =
              DateTime.tryParse(sale['saleDate']?.toString() ?? '') ??
              DateTime.now();

          final saleNo =
              sale['saleNo']?.toString() ??
              sale['saleId']?.toString() ??
              sale['_id']?.toString() ??
              '';

          loadedSales.add(
            SaleModel(
              id: saleNo,

              saleId: sale['saleId']?.toString() ?? '',

              date: saleDate,

              customerId: sale['customerId']?.toString() ?? '',

              customerName: sale['customerName']?.toString() ?? '',

              customerMobile: sale['customerMobile']?.toString() ?? '',

              route: sale['route']?.toString() ?? '',

              salesman: sale['createdRole']?.toString().toLowerCase() == 'admin'
                  ? 'Admin'
                  : (sale['salesmanName']?.toString().trim().isNotEmpty == true
                        ? sale['salesmanName'].toString()
                        : sale['createdRole']?.toString() ?? ''),

              products: billProducts,

              paymentMode:
    sale['paymentMode']?.toString() ?? 'Credit',

payments:
    (sale['payments'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList(),
paidAmount:
    double.tryParse(
      sale['paidAmount']?.toString() ?? '0',
    ) ??
    0,

advanceUsed:
    double.tryParse(
      sale['advanceUsed']?.toString() ?? '0',
    ) ??
    0,

outstandingAmount:
    double.tryParse(
      sale['outstandingAmount']?.toString() ?? '0',
    ) ??
    0,

paymentStatus:
    sale['paymentStatus']?.toString() ?? 'PAID',

grandTotal:
    double.tryParse(
          sale['grandTotal']?.toString() ?? '',
        ) ??
billProducts.fold<double>(
  0.0,
  (double sum, SaleProductModel product) {
    return sum + product.amount;
  },
),

status: status,
              godown: sale['godown']?.toString() ?? '',
            ),
          );

          // CLOSE: for (final record in records)
        }

        if (!mounted || requestToken != _salesRequestToken) return;
        setState(() {
          _serverSales
            ..clear()
            ..addAll(loadedSales);

          _cancelledSaleIds
            ..clear()
            ..addAll(cancelledIds);
        });
      } else {
        _showMessage(
          data is Map
              ? data['message']?.toString() ?? 'Unable to load sales.'
              : 'Unable to load sales.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      _showMessage('Unable to load sales from server: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSales = false;
        });
      }
    }
  }

  bool _isSaleCancelled(SaleModel sale) {
    return _cancelledSaleIds.contains(sale.id);
  }

  Future<void> _cancelSale(SaleModel sale) async {
    if (_cancellingSale) {
      return;
    }

    if (_isSaleCancelled(sale)) {
      _showMessage('This sale is already cancelled.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Sale'),
          content: Text(
            'Are you sure you want to cancel ${sale.id}?\n\n'
            'The stock will be restored to the correct available stock automatically.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel Sale'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _cancellingSale = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.sales}/${Uri.encodeComponent(sale.id)}/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        _showMessage(
          data['message']?.toString() ??
              'Sale cancelled successfully. Stock has been adjusted automatically.',
          color: _green,
        );

        // Refresh sales status.
        await _loadSales();

        // If customer is currently selected,
        // refresh stock visible in Create Sale.
        if (_selectedCustomer != null) {
          await _loadCustomerProducts();
        }

        DataSyncService.instance.notifySaleChanged();
      } else {
        _showMessage(
          data is Map
              ? data['message']?.toString() ?? 'Unable to cancel sale.'
              : 'Unable to cancel sale.',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to cancel sale: $error');
    } finally {
      if (mounted) {
        setState(() {
          _cancellingSale = false;
        });
      }
    }
  }

  Future<void> _loadCustomers() async {
    if (!mounted) return;

    setState(() {
      _loadingCustomers = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.customers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        final records = data['data'] as List<dynamic>? ?? <dynamic>[];

        setState(() {
          _customers
            ..clear()
            ..addAll(
              records.map((item) => Map<String, dynamic>.from(item as Map)),
            );
        });
      } else {
        _showMessage(
          data is Map
              ? data['message']?.toString() ?? 'Unable to load customers.'
              : 'Unable to load customers.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      _showMessage('Unable to load customers from server: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingCustomers = false;
        });
      }
    }
  }
Future<void> _loadCustomerProducts() async {
  final Map<String, dynamic>? customer =
      _selectedCustomer;

  if (customer == null) {
    return;
  }

  final String customerId =
      (customer['customerId'] ?? '')
          .toString()
          .trim();

  if (customerId.isEmpty) {
    _showMessage(
      'Customer ID not found.',
    );
    return;
  }

  setState(() {
    _loadingProducts = true;

    _saleProducts.clear();

    _cart.clear();

    _selectedAllocation = null;
  });

  try {
    // ==========================================================
    // CUSTOMER RATE
    //
    // We still need customer rate even for salesman because
    // stock and selling rate are two different things.
    // ==========================================================

    final http.Response rateResponse =
        await http.get(
      Uri.parse(
        '${ApiConfig.customerRates}/$customerId',
      ),
      headers: <String, String>{
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer ${ApiConfig.token}',
      },
    );

    final dynamic rateDecoded =
        jsonDecode(
      rateResponse.body,
    );

    if (rateResponse.statusCode != 200 ||
        rateDecoded is! Map ||
        rateDecoded['success'] != true) {
      final String message =
          rateDecoded is Map
              ? rateDecoded['message']
                      ?.toString() ??
                  'Unable to load customer rates.'
              : 'Unable to load customer rates.';

      throw Exception(message);
    }

    final List<dynamic> rateRecords =
        rateDecoded['data'] is List
            ? rateDecoded['data']
                as List<dynamic>
            : <dynamic>[];

    // ==========================================================
    // PRODUCT ID -> CUSTOMER RATE
    // ==========================================================

    final Map<String, Map<String, dynamic>>
        rateMap =
        <String, Map<String, dynamic>>{};

    for (final dynamic raw
        in rateRecords) {
      if (raw is! Map) {
        continue;
      }

      final Map<String, dynamic> item =
          Map<String, dynamic>.from(
        raw,
      );

      final String productId =
          (item['productId'] ?? '')
              .toString()
              .trim()
              .toUpperCase();

      if (productId.isEmpty) {
        continue;
      }

      rateMap[productId] = item;
    }

    // ==========================================================
    // ADMIN
    //
    // Keep current warehouse/product-stock behaviour.
    // Do not affect admin sale logic.
    // ==========================================================

    if (!_isSalesman) {
      final List<Map<String, dynamic>>
          loadedProducts =
          <Map<String, dynamic>>[];

      for (final dynamic raw
          in rateRecords) {
        if (raw is! Map) {
          continue;
        }

        final Map<String, dynamic> map =
            Map<String, dynamic>.from(
          raw,
        );

        loadedProducts.add(
          <String, dynamic>{
            'productId':
                (map['productId'] ?? '')
                    .toString(),

            'product':
                (map['productName'] ?? '')
                    .toString(),

            'variant':
                (map['variant'] ?? '')
                    .toString(),

            'unit':
                (map['unit'] ?? 'Pcs')
                    .toString(),

            // ADMIN = CENTRAL STOCK
            'qty':
                _asInt(
              map['stock'],
            ),

            'returnedQty': 0,

            'soldQty': 0,

            'rate':
                double.tryParse(
                  map['specialRate']
                          ?.toString() ??
                      '0',
                ) ??
                0,

            'defaultRate':
                double.tryParse(
                  map['defaultRate']
                          ?.toString() ??
                      '0',
                ) ??
                0,

            'hasCustomRate':
                map['hasCustomRate'] ==
                    true,

            'route':
                (customer['route'] ?? '')
                    .toString(),

            'salesman':
                'Admin',
          },
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _saleProducts
          ..clear()
          ..addAll(
            loadedProducts,
          );

        _selectFirstAvailableAllocation();
      });

      return;
    }

    // ==========================================================
    // SALESMAN
    //
    // IMPORTANT:
    // Salesman must NEVER use warehouse stock here.
    //
    // Stock source:
    // GET /api/salesman-stock/my
    // ==========================================================

    final http.Response stockResponse =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/salesman-stock/my',
      ),
      headers: <String, String>{
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer ${ApiConfig.token}',
      },
    );

    final dynamic stockDecoded =
        jsonDecode(
      stockResponse.body,
    );

    if (stockResponse.statusCode != 200 ||
        stockDecoded is! Map ||
        stockDecoded['success'] != true) {
      final String message =
          stockDecoded is Map
              ? stockDecoded['message']
                      ?.toString() ??
                  'Unable to load salesman stock.'
              : 'Unable to load salesman stock.';

      throw Exception(message);
    }

    final dynamic rawStockData =
        stockDecoded['data'];

    if (rawStockData is! Map) {
      throw Exception(
        'Invalid salesman stock response.',
      );
    }

    final Map<String, dynamic> stockData =
        Map<String, dynamic>.from(
      rawStockData,
    );

    final List<dynamic> stockRecords =
        stockData['products'] is List
            ? stockData['products']
                as List<dynamic>
            : <dynamic>[];

    // ==========================================================
    // WHEN EDITING A SALE
    //
    // /salesman-stock/my has already deducted the existing
    // sale quantity.
    //
    // We must temporarily add the quantity of the bill being
    // edited back to the allowed quantity.
    //
    // Example:
    //
    // Allocation remaining after sale = 5
    // Existing bill qty              = 10
    //
    // During edit maximum allowed    = 15
    // ==========================================================

    final Map<String, int>
        editingOriginalQty =
        <String, int>{};

    if (_isEditingSale &&
        _editingSaleId != null) {
      SaleModel? editingSale;

      for (final SaleModel sale
          in _serverSales) {
        if (sale.id ==
                _editingSaleId ||
            sale.saleId ==
                _editingSaleId) {
          editingSale = sale;
          break;
        }
      }

      if (editingSale != null) {
        for (final SaleProductModel product
            in editingSale.products) {
          final String id =
              product.productId
                  .trim()
                  .toUpperCase();

          editingOriginalQty[id] =
              (editingOriginalQty[id] ??
                      0) +
                  product.quantity;
        }
      }
    }

    // ==========================================================
    // BUILD SALESMAN PRODUCT LIST
    // ==========================================================

    final List<Map<String, dynamic>>
        loadedProducts =
        <Map<String, dynamic>>[];

    final Set<String> loadedIds =
        <String>{};

    for (final dynamic raw
        in stockRecords) {
      if (raw is! Map) {
        continue;
      }

      final Map<String, dynamic> stock =
          Map<String, dynamic>.from(
        raw,
      );

      final String productId =
          (stock['productId'] ?? '')
              .toString()
              .trim()
              .toUpperCase();

      if (productId.isEmpty) {
        continue;
      }

      final int available =
          _asInt(
        stock['available'],
      );

      final int oldEditQuantity =
          editingOriginalQty[productId] ??
              0;

      // Available stock salesman is allowed to use.
      final int allowedQuantity =
          available +
          oldEditQuantity;

      if (allowedQuantity <= 0) {
        continue;
      }

      final Map<String, dynamic>? rate =
          rateMap[productId];

      final double defaultRate =
          double.tryParse(
            rate?['defaultRate']
                    ?.toString() ??
                '0',
          ) ??
          0;

      double sellingRate =
          double.tryParse(
            rate?['specialRate']
                    ?.toString() ??
                '0',
          ) ??
          0;

      if (sellingRate <= 0) {
        sellingRate =
            defaultRate;
      }

      loadedProducts.add(
        <String, dynamic>{
          'productId':
              productId,

          'product':
              (stock['productName'] ?? '')
                  .toString(),

          'variant':
              (stock['variant'] ?? '')
                  .toString(),

          'unit':
              (stock['unit'] ?? 'Pcs')
                  .toString(),

          // IMPORTANT:
          // This is NOT warehouse stock.
          //
          // qty = salesman remaining allocation.
          'qty':
              allowedQuantity,

          // Already accounted by backend stock API.
          'returnedQty':
              0,

          'soldQty':
              0,

          'rate':
              sellingRate,

          'defaultRate':
              defaultRate,

          'hasCustomRate':
              rate?['hasCustomRate'] ==
                  true,

          'route':
              (stockData['routeName'] ??
                      customer['route'] ??
                      '')
                  .toString(),

          'salesman':
              (stockData[
                          'salesmanName'] ??
                      '')
                  .toString(),

          // Optional display/debug values
          'allocatedQty':
              _asInt(
            stock['allocated'],
          ),

          'actualSoldQty':
              _asInt(
            stock['sold'],
          ),

          'actualReturnedQty':
              _asInt(
            stock['returned'],
          ),

          'availableQty':
              available,
        },
      );

      loadedIds.add(
        productId,
      );
    }

    // ==========================================================
    // IMPORTANT EDIT CASE
    //
    // Your backend currently returns only products having
    // available > 0.
    //
    // A product may have:
    //
    // Available now = 0
    // Existing edited bill = 10
    //
    // It therefore does not come from salesman-stock API.
    // We still need it while editing that existing bill.
    // ==========================================================

    if (_isEditingSale) {
      for (final MapEntry<String, int> entry
          in editingOriginalQty.entries) {
        if (entry.value <= 0 ||
            loadedIds.contains(
              entry.key,
            )) {
          continue;
        }

        final Map<String, dynamic>? rate =
            rateMap[entry.key];

        if (rate == null) {
          continue;
        }

        final double defaultRate =
            double.tryParse(
              rate['defaultRate']
                      ?.toString() ??
                  '0',
            ) ??
            0;

        double sellingRate =
            double.tryParse(
              rate['specialRate']
                      ?.toString() ??
                  '0',
            ) ??
            0;

        if (sellingRate <= 0) {
          sellingRate =
              defaultRate;
        }

        loadedProducts.add(
          <String, dynamic>{
            'productId':
                entry.key,

            'product':
                (rate['productName'] ?? '')
                    .toString(),

            'variant':
                (rate['variant'] ?? '')
                    .toString(),

            'unit':
                (rate['unit'] ?? 'Pcs')
                    .toString(),

            // Existing bill quantity can at least
            // remain unchanged.
            'qty':
                entry.value,

            'returnedQty':
                0,

            'soldQty':
                0,

            'rate':
                sellingRate,

            'defaultRate':
                defaultRate,

            'hasCustomRate':
                rate['hasCustomRate'] ==
                    true,

            'route':
                (stockData['routeName'] ??
                        customer['route'] ??
                        '')
                    .toString(),

            'salesman':
                (stockData[
                            'salesmanName'] ??
                        '')
                    .toString(),

            'allocatedQty':
                entry.value,

            'actualSoldQty':
                entry.value,

            'actualReturnedQty':
                0,

            'availableQty':
                0,
          },
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _saleProducts
        ..clear()
        ..addAll(
          loadedProducts,
        );

      _selectFirstAvailableAllocation();
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
          message.substring(
        'Exception: '.length,
      );
    }

    _showMessage(
      'Unable to load products: $message',
    );
  } finally {
    if (mounted) {
      setState(() {
        _loadingProducts = false;
      });
    }
  }
}
  void _addProductToSale() {
    final allocation = _selectedAllocation;
    final quantity = int.tryParse(_quantityController.text);
    final rate = double.tryParse(_rateController.text);

    if (allocation == null) {
      _showMessage('Please select an allotted product.');
      return;
    }
    if (quantity == null || quantity <= 0) {
      _showMessage('Please enter a valid quantity.');
      return;
    }
    if (quantity > _availableToAdd) {
      _showMessage('Only $_availableToAdd more of this product is available.');
      return;
    }
    if (rate == null || rate <= 0) {
      _showMessage('Please enter a valid rate.');
      return;
    }

    _cart.add(
      _SaleLineDraft(allocation: allocation, quantity: quantity, rate: rate),
    );
    _quantityController.clear();
    setState(() {});
    _showMessage('${allocation['product']} added to this sale.', color: _green);
  }

  Future<void> _completeSale() async {
    if (_savingSale) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final customer = _selectedCustomer;

    if (customer == null) {
      _showMessage('Please select a customer.');
      return;
    }

    if (_cart.isEmpty) {
      _showMessage('Add at least one product before completing the sale.');
      return;
    }
    if (_isPaymentOverAmount) {
      _showMessage('Paid amount cannot be greater than bill amount.');
      return;
    }

    final customerId = customer['customerId']?.toString() ?? '';

    if (customerId.isEmpty) {
      _showMessage('Customer ID not found.');
      return;
    }

    if (_isEditingSale && (_editingSaleId == null || _editingSaleId!.isEmpty)) {
      _showMessage('Sale ID is missing. Unable to update sale.');
      return;
    }

    setState(() {
      _savingSale = true;
    });

    try {
      // ============================================================
      // REQUEST
      // ============================================================

final requestBody =
    jsonEncode({
  'saleDate':
      _selectedDate
          .toIso8601String(),

  'customerId':
      customerId,

  // Kept for compatibility.
  // Backend calculates the final
  // display payment mode again.
  'paymentMode':
      _calculatedPaymentMode,

  // Actual money received now.
  'payments':
      _paymentBreakup,

  // IMPORTANT:
  // Do NOT send:
  //
  // paidAmount
  // outstandingAmount
  // paymentStatus
  // advanceUsed
  //
  // Backend calculates all of them.

  'products':
      _cart.map(
        (line) {
          return {
            'productId':
                line
                    .allocation[
                        'productId']
                    ?.toString() ??
                '',

            'quantity':
                line.quantity,
          };
        },
      ).toList(),
});

      final headers = <String, String>{
        'Content-Type': 'application/json',

        'Authorization': 'Bearer ${ApiConfig.token}',
      };

      late http.Response response;

      // ============================================================
      // CREATE / UPDATE
      // ============================================================

      if (_isEditingSale) {
        response = await http.put(
          Uri.parse(
            '${ApiConfig.sales}/${Uri.encodeComponent(_editingSaleId!)}',
          ),
          headers: headers,
          body: requestBody,
        );
      } else {
        response = await http.post(
          Uri.parse(ApiConfig.sales),
          headers: headers,
          body: requestBody,
        );
      }

      // ============================================================
      // RESPONSE
      // ============================================================

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (!mounted) {
        return;
      }

      final successStatus = _isEditingSale
          ? response.statusCode == 200
          : response.statusCode == 201;

      if (successStatus &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        final wasEditing = _isEditingSale;

        final saleData = data['data'] as Map<String, dynamic>?;

        final saleNo = saleData?['saleNo']?.toString() ?? _editingSaleNo ?? '';

        _showMessage(
          data['message']?.toString() ??
              (wasEditing
                  ? 'Sale updated successfully.'
                  : saleNo.isEmpty
                  ? 'Sale saved successfully.'
                  : 'Sale $saleNo saved successfully.'),
          color: _green,
        );

        // ==========================================================
        // RESET SCREEN
        // ==========================================================

        setState(() {
          _cart.clear();

          _quantityController.clear();

          _rateController.clear();

          _cashPaymentController.clear();

          _upiPaymentController.clear();

          _bankPaymentController.clear();

          _productSearchController.clear();

          _selectedAllocation = null;

          _isEditingSale = false;

          _editingSaleId = null;

          _editingSaleNo = null;

          // After UPDATE return to My Sales.
          if (wasEditing) {
            _isCreatingSale = false;

            _selectedCustomer = null;

            _saleProducts.clear();

            _customerController.clear();

            _paymentMode = 'Credit';
          }
        });

        // ==========================================================
        // REFRESH DATA
        // ==========================================================

        if (!wasEditing && _selectedCustomer != null) {
          await _loadCustomerProducts();
        }

        await _loadSales();
        DataSyncService.instance.notifySaleChanged();

        return;
      }

      _showMessage(
        data is Map
            ? data['message']?.toString() ??
                  (_isEditingSale
                      ? 'Unable to update sale.'
                      : 'Unable to save sale.')
            : (_isEditingSale
                  ? 'Unable to update sale.'
                  : 'Unable to save sale.'),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _isEditingSale
            ? 'Unable to update sale: $error'
            : 'Unable to save sale: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingSale = false;
        });
      }
    }
  }
  // void _completeSale() {
  //   if (!(_formKey.currentState?.validate() ?? false)) return;
  //   if (_cart.isEmpty) {
  //     _showMessage('Add at least one product before completing the sale.');
  //     return;
  //   }

  //   final customer = _customerController.text.trim();
  //   final saleGroupId = DateTime.now().microsecondsSinceEpoch;

  //   for (int index = 0; index < _cart.length; index++) {
  //     final line = _cart[index];
  //     final allocation = line.allocation;
  //     SalesStore.add(
  //       SaleModel(
  //         id: 'SALE-$saleGroupId-$index',
  //         date: _selectedDate,
  //         customerName: customer,
  //         route: (allocation['route'] ?? '').toString(),
  //         salesman: (allocation['salesman'] ?? '').toString(),
  //         product: (allocation['product'] ?? '').toString(),
  //         quantity: line.quantity,
  //         rate: line.rate,
  //         paymentMode: _paymentMode,
  //       ),
  //     );
  //     allocation['soldQty'] = _soldFor(allocation) + line.quantity;
  //   }

  //   final itemCount = _cart.length;
  //   final total = _cartTotal;
  //   final totalQuantity = _cartQuantity;
  //   _customerController.clear();
  //   _quantityController.clear();
  //   _cart.clear();
  //   _isCreatingSale = false;
  //   setState(() {});

  //   _showMessage(
  //     'Sale saved: $itemCount products, $totalQuantity units for '
  //     '₹${total.toStringAsFixed(0)}.',
  //     color: _green,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (_isCreatingSale) return _buildCreateSaleScreen();

    final sales = _filteredSales;
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildSalesAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            if (_showSearch) _buildSearchField(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                children: <Widget>[
                  _buildMonthlySummary(),
                  const SizedBox(height: 14),
                  _buildPeriodFilters(),
                  const SizedBox(height: 14),
                  if (sales.isEmpty)
                    _buildSalesEmptyState()
                  else
                    ...sales.map(_buildHistorySaleCard),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCreateSaleAction(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCreateSaleScreen() {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildCreateSaleHeader(),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildNumberedHeading(1, 'Sale Information'),

                    const SizedBox(height: 16),

                    Row(
                      children: <Widget>[
                        Expanded(child: _buildDateField()),

                        const SizedBox(width: 10),

                        Expanded(child: _buildRouteAllocationField()),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              _buildCustomerInformationPanel(),

              if (_selectedCustomer != null) ...<Widget>[
                const SizedBox(height: 10),

                if (_loadingProducts)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_saleProducts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(),
                    child: const Text(
                      'No products available.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted),
                    ),
                  )
                else
                  _buildSmartProductInformationPanel(),

                if (!_loadingProducts && _saleProducts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  _buildSaleSummaryPanel(),
                ],

                const SizedBox(height: 48),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCreateSaleHeader() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(132),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF123E9E), Color(0xFF0876DF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 18, 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Back to sales',
                  onPressed: () {
                    setState(() {
                      _isCreatingSale = false;

                      _isEditingSale = false;

                      _editingSaleId = null;

                      _editingSaleNo = null;

                      _selectedCustomer = null;

                      _selectedAllocation = null;

                      _saleProducts.clear();

                      _cart.clear();

                      _customerController.clear();

                      _quantityController.clear();

                      _rateController.clear();

                     _productSearchController
    .clear();

_cashPaymentController
    .clear();

_upiPaymentController
    .clear();

_bankPaymentController
    .clear();

_paymentMode =
    'Credit';
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _isEditingSale ? 'Edit Sale' : 'Create New Sale',

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _isEditingSale
                            ? (_editingSaleNo != null &&
                                      _editingSaleNo!.isNotEmpty
                                  ? 'Update ${_editingSaleNo!}'
                                  : 'Update existing sale')
                            : 'Milk Distribution',

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 66,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberedHeading(int number, String title) {
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _dark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSalesAppBar() {
    return AppBar(
      toolbarHeight: 86,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 58,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded, size: 28),
      ),
      titleSpacing: 2,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'My Sales',
            style: TextStyle(
              color: _dark,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'View all sales you have recorded',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          tooltip: _syncing ? 'Syncing...' : 'Sync',
          onPressed: (_syncing || _loadingSales) ? null : _handleManualSync,
          icon: _syncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primary,
                  ),
                )
              : const Icon(Icons.sync_rounded, size: 27),
        ),
        IconButton(
          tooltip: 'Search sales',
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchController.clear();
            });
          },
          icon: const Icon(Icons.search_rounded, size: 28),
        ),
        IconButton(
          tooltip: 'Filter sales',
          onPressed: _showFilterSheet,
          icon: const Icon(Icons.filter_alt_outlined, size: 27),
        ),
        IconButton(
          tooltip: 'Export Sales Report PDF',
          onPressed: _exportSalesReportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 26),
        ),
        const SizedBox(width: 9),
      ],
    );
  }

  void _exportSalesReportPdf() {
    final sales = _filteredSales;
    if (sales.isEmpty) {
      _showMessage('No sales found to export report.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SalesReportPreviewScreen(
          sales: sales,
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by customer, sale or product',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ),
    );
  }

  List<SaleModel> get _salesSource => _serverSales;

  List<SaleModel> get _filteredSales {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    return _salesSource.where((sale) {
      final matchesProduct = sale.products.any(
        (product) => product.productName.toLowerCase().contains(query),
      );

      final matchesQuery =
          query.isEmpty ||
          sale.id.toLowerCase().contains(query) ||
          sale.customerName.toLowerCase().contains(query) ||
          matchesProduct;
      if (!matchesQuery) return false;
      return switch (_selectedPeriod) {
        _SalesPeriod.all => true,
        _SalesPeriod.today => _sameDay(sale.date, now),
        _SalesPeriod.week => sale.date.isAfter(
          now.subtract(const Duration(days: 7)),
        ),
        _SalesPeriod.month =>
          sale.date.year == now.year && sale.date.month == now.month,
      };
    }).toList();
  }

  double get _monthlySalesTotal {
    final now = DateTime.now();

    return _salesSource
        .where(
          (sale) =>
              !_isSaleCancelled(sale) &&
              sale.date.year == now.year &&
              sale.date.month == now.month,
        )
        .fold<double>(0, (total, sale) => total + sale.total);
  }

  Widget _buildMonthlySummary() {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Total Sales (This Month)',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '₹${_formatMoney(_monthlySalesTotal)}',
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: _primary,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilters() {
    const periods = <(_SalesPeriod, String, IconData)>[
      (_SalesPeriod.all, 'All Sales', Icons.list_alt_rounded),
      (_SalesPeriod.today, 'Today', Icons.calendar_today_outlined),
      (_SalesPeriod.week, 'This Week', Icons.calendar_month_outlined),
      (_SalesPeriod.month, 'This Month', Icons.calendar_month_outlined),
    ];
    return Row(
      children: List<Widget>.generate(periods.length, (index) {
        final item = periods[index];
        final selected = item.$1 == _selectedPeriod;
        return Expanded(
          flex: index == 0 ? 11 : (index == 2 || index == 3 ? 13 : 10),
          child: Padding(
            padding: EdgeInsets.only(
              right: index == periods.length - 1 ? 0 : 7,
            ),
            child: InkWell(
              onTap: () => setState(() => _selectedPeriod = item.$1),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? _primary : AppColors.border,
                  ),
                  boxShadow: selected
                      ? const <BoxShadow>[
                          BoxShadow(
                            color: AppColors.shadowPrimary,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      item.$3,
                      size: 18,
                      color: selected ? Colors.white : _muted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: selected ? Colors.white : _dark,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSalesEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: _cardDecoration(),
      child: Column(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No sales found',
            style: TextStyle(
              color: _dark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedPeriod == _SalesPeriod.all &&
                    _searchController.text.trim().isEmpty
                ? 'Record your first sale using the button below.'
                : 'Try another search or date filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySaleCard(SaleModel sale) {
    const accents = <(Color, Color)>[
      (Color(0xFF3776E8), Color(0xFFEAF1FF)),
      (Color(0xFF239254), Color(0xFFE8F8EC)),
      (Color(0xFFC89500), Color(0xFFFFF5D8)),
      (Color(0xFF7837DF), Color(0xFFF1EAFE)),
    ];
    final index = _salesSource.indexOf(sale);
    final accent = accents[index.abs() % accents.length];
    final isCancelled = _isSaleCancelled(sale);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 18, 13, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 62,
            decoration: BoxDecoration(
              color: accent.$2,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: accent.$1,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  sale.customerName.isEmpty ? 'Customer' : sale.customerName,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: _dark,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${_formatDate(sale.date)}  •  ${_formatTime(sale.date)}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  sale.productSummary,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  sale.id,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(color: _muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? const Color(0xFFFFE5E5)
                      : const Color(0xFFDDF8E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCancelled ? 'Cancelled' : 'Completed',
                  style: TextStyle(
                    color: isCancelled
                        ? AppColors.error
                        : const Color(0xFF21884B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '₹${_formatMoney(sale.total)}',
                        style: const TextStyle(
                          color: _dark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${sale.itemCount} '
                        '${sale.itemCount == 1 ? 'Product' : 'Products'}'
                        ' • ${sale.totalQuantity} Units',

                        style: const TextStyle(color: _muted, fontSize: 10.5),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    tooltip: 'Sale actions',

                    onSelected: (action) async {
                      if (action == 'view') {
                        await _viewSaleDetails(sale);
                        return;
                      }

                      if (action == 'pdf') {
                        _openBill(sale);
                        return;
                      }

                      if (action == 'whatsapp') {
                        _openBill(sale, openWhatsApp: true);
                        return;
                      }

                      if (action == 'edit') {
                        await _editSale(sale);
                        return;
                      }
                      if (action == 'cancel') {
                        await _cancelSale(sale);
                      }
                    },

                    itemBuilder: (_) {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'view',
                          child: ListTile(
                            leading: Icon(Icons.visibility_outlined),
                            title: Text('View Details'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),

                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'pdf',
                          child: ListTile(
                            leading: Icon(Icons.picture_as_pdf_outlined),
                            title: Text('View PDF Bill'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),

                        const PopupMenuItem<String>(
                          value: 'whatsapp',
                          child: ListTile(
                            leading: Icon(Icons.chat_outlined),
                            title: Text('Send on WhatsApp'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),

                        if (!isCancelled) const PopupMenuDivider(),

                        if (!isCancelled)
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(
                                Icons.edit_outlined,
                                color: _primary,
                              ),
                              title: Text(
                                'Edit Sale',
                                style: TextStyle(
                                  color: _dark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (!isCancelled) const PopupMenuDivider(),

                        if (!isCancelled)
                          PopupMenuItem<String>(
                            value: 'cancel',
                            child: ListTile(
                              leading: Icon(
                                Icons.cancel_outlined,
                                color: AppColors.error,
                              ),
                              title: Text(
                                'Cancel Sale',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ];
                    },

                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: _muted,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _viewSaleDetails(SaleModel sale) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
            child: Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 10, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF123E9E), Color(0xFF0876DF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.customerName.trim().isEmpty
                                  ? 'Sale Details'
                                  : sale.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              sale.id,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .85),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        tooltip: 'Close',
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // SCROLLABLE DETAILS
                // ==================================================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==========================================
                        // SALE INFO
                        // ==========================================
                        const Text(
                          'Sale Information',
                          style: TextStyle(
                            color: _dark,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _saleDetailRow('Bill No.', sale.id),

                              _saleDetailDivider(),

                              _saleDetailRow(
                                'Date',
                                '${_formatDate(sale.date)} • ${_formatTime(sale.date)}',
                              ),

                              _saleDetailDivider(),

                              _saleDetailRow(
                                'Customer',
                                sale.customerName.trim().isEmpty
                                    ? '-'
                                    : sale.customerName,
                              ),

                              _saleDetailDivider(),

                              _saleDetailRow(
                                'Customer ID',
                                sale.customerId.trim().isEmpty
                                    ? '-'
                                    : sale.customerId,
                              ),

                              if (sale.customerMobile.trim().isNotEmpty) ...[
                                _saleDetailDivider(),

                                _saleDetailRow('Mobile', sale.customerMobile),
                              ],

                              if (sale.route.trim().isNotEmpty) ...[
                                _saleDetailDivider(),

                                _saleDetailRow('Route', sale.route),
                              ],

                              if (sale.salesman.trim().isNotEmpty) ...[
                                _saleDetailDivider(),

                                _saleDetailRow('Created By', sale.salesman),
                              ],

                              _saleDetailDivider(),

                              _saleDetailRow('Payment', sale.paymentMode),

                              _saleDetailDivider(),

                              _saleDetailRow(
                                'Status',
                                sale.isCancelled ? 'Cancelled' : 'Posted',
                                valueColor: sale.isCancelled
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==========================================
                        // PRODUCTS
                        // ==========================================
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Products',
                                style: TextStyle(
                                  color: _dark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),

                            Text(
                              '${sale.itemCount} ${sale.itemCount == 1 ? 'Product' : 'Products'}',
                              style: const TextStyle(
                                color: _primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0F5FD),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(11),
                                    topRight: Radius.circular(11),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Product',
                                        style: TextStyle(
                                          color: _dark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Qty',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _dark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rate',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: _dark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Amount',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: _dark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (sale.products.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'No products found.',
                                    style: TextStyle(color: _muted),
                                  ),
                                )
                              else
                                ...sale.products.asMap().entries.map((entry) {
                                  final index = entry.key;

                                  final product = entry.value;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color:
                                              index == sale.products.length - 1
                                              ? Colors.transparent
                                              : AppColors.border,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.productName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: _dark,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),

                                              if (product.variant
                                                  .trim()
                                                  .isNotEmpty)
                                                Text(
                                                  product.variant,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: _muted,
                                                    fontSize: 8.5,
                                                  ),
                                                ),

                                              if (product.hasSpecialRate)
                                                const Text(
                                                  'Special Rate',
                                                  style: TextStyle(
                                                    color: AppColors.success,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${product.quantity} ${product.unit}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: _dark,
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ),

                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '₹${_formatMoney(product.rate)}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              color: _dark,
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ),

                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '₹${_formatMoney(product.amount)}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              color: _dark,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==========================================
                        // TOTAL
                        // ==========================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3F7FE), Color(0xFFDCEAFF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _saleDetailRow(
                                'Total Products',
                                '${sale.itemCount}',
                              ),

                              const SizedBox(height: 8),

                              _saleDetailRow(
                                'Total Quantity',
                                '${sale.totalQuantity} Units',
                              ),

                              const Divider(height: 22),

                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Grand Total',
                                      style: TextStyle(
                                        color: _dark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    '₹${_formatMoney(sale.total)}',
                                    style: const TextStyle(
                                      color: _primary,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (sale.godown.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),

                          Text(
                            'Godown: ${sale.godown}',
                            style: const TextStyle(color: _muted, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // BOTTOM BUTTONS
                // ==================================================
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);

                            _openBill(sale);
                          },
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('PDF Bill'),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _saleDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? _dark,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _saleDetailDivider() {
    return const Divider(height: 18, color: AppColors.border);
  }

  void _openBill(SaleModel sale, {bool openWhatsApp = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SalesBillPreviewScreen(
          sale: sale,
          openWhatsAppOnStart: openWhatsApp,
        ),
      ),
    );
  }

  Widget _buildCreateSaleAction() {
    if (!UiSession.instance.can(AppPermission.salesCreate)) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.white,
          elevation: 5,
          shadowColor: AppColors.shadowPrimary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _openCreateSale,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Text(
                'Create New Sale',
                style: TextStyle(
                  color: _primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton(
          heroTag: 'create-sale',
          tooltip: 'Create New Sale',
          onPressed: _openCreateSale,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 33),
        ),
      ],
    );
  }

  Future<void> _editSale(SaleModel sale) async {
    if (!UiSession.instance.can(AppPermission.salesCreate)) {
      _showMessage('You do not have permission to edit sales.');
      return;
    }
    if (sale.isCancelled) {
      _showMessage('Cancelled sale cannot be edited.');
      return;
    }

    // ============================================================
    // FIND CUSTOMER FROM CURRENT CUSTOMER MASTER
    // ============================================================

    Map<String, dynamic>? customer;

    for (final item in _customers) {
      final customerId =
          item['customerId']?.toString().trim().toUpperCase() ?? '';

      if (customerId == sale.customerId.trim().toUpperCase()) {
        customer = item;
        break;
      }
    }

    if (customer == null) {
      _showMessage(
        'Customer ${sale.customerName} was not found in customer master.',
      );
      return;
    }

    // ============================================================
    // ENTER EDIT MODE
    // ============================================================

    setState(() {
      _isEditingSale = true;

      _editingSaleId = sale.id;

      _editingSaleNo = sale.id;

      _isCreatingSale = true;

      _selectedDate = sale.date;

      _selectedCustomer = customer;

      _selectedAllocation = null;

      _customerController.text = sale.customerName;

      _quantityController.clear();

      _rateController.clear();
    _cashPaymentController.text =
    sale.cashAmount > 0
        ? sale.cashAmount.toStringAsFixed(2)
        : '';

_upiPaymentController.text =
    sale.upiAmount > 0
        ? sale.upiAmount.toStringAsFixed(2)
        : '';

_bankPaymentController.text =
    sale.bankTransferAmount > 0
        ? sale.bankTransferAmount.toStringAsFixed(2)
        : '';

_productSearchController.clear();

_paymentMode =
    sale.paymentMode;

      _saleProducts.clear();

      _cart.clear();
    });

    // ============================================================
    // LOAD CURRENT PRODUCTS / CURRENT CUSTOMER RATES
    // ============================================================

    await _loadCustomerProducts();

    if (!mounted) {
      return;
    }

    if (_saleProducts.isEmpty) {
      _showMessage('No products are available for this customer.');
      return;
    }

    // ============================================================
    // RESTORE BILL PRODUCTS INTO CART
    // ============================================================

    final restoredLines = <_SaleLineDraft>[];

    for (final saleProduct in sale.products) {
      Map<String, dynamic>? matchedProduct;

      for (final availableProduct in _saleProducts) {
        final productId =
            availableProduct['productId']?.toString().trim().toUpperCase() ??
            '';

        if (productId == saleProduct.productId.trim().toUpperCase()) {
          matchedProduct = availableProduct;
          break;
        }
      }

      if (matchedProduct == null) {
        _showMessage(
          '${saleProduct.productName} is no longer available in product master.',
        );
        continue;
      }

      // Use current customer-specific rate.
      final currentRate =
          double.tryParse(matchedProduct['rate']?.toString() ?? '0') ??
          saleProduct.rate;

      restoredLines.add(
        _SaleLineDraft(
          allocation: matchedProduct,

          quantity: saleProduct.quantity,

          rate: currentRate > 0 ? currentRate : saleProduct.rate,
        ),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _cart
        ..clear()
        ..addAll(restoredLines);

      if (_saleProducts.isNotEmpty) {
        _selectedAllocation = _saleProducts.first;

        _setSuggestedRate();
      }
    });

    if (restoredLines.isEmpty) {
      _showMessage('Unable to restore products for this sale.');
    }
  }

  void _openCreateSale() {
    if (!UiSession.instance.can(AppPermission.salesCreate)) {
      _showMessage('You do not have permission to create sales.');
      return;
    }
    setState(() {
      // ==========================================================
      // NEW SALE MODE
      // ==========================================================

      _isEditingSale = false;

      _editingSaleId = null;

      _editingSaleNo = null;

      _isCreatingSale = true;

      _selectedDate = DateTime.now();

      _selectedCustomer = null;

      _selectedAllocation = null;

      _customerController.clear();

      _quantityController.clear();

      _rateController.clear();

      _productSearchController.clear();

      _saleProducts.clear();

      _cart.clear();

      _cashPaymentController.clear();

      _upiPaymentController.clear();

      _bankPaymentController.clear();

      _paymentMode = 'Credit';
    });
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: _primary,
      unselectedItemColor: _muted,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
      elevation: 10,
      onTap: _onBottomNavigationTap,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline_rounded),
          label: 'Customers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Sales',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'Collections',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'More',
        ),
      ],
    );
  }

  void _onBottomNavigationTap(int index) {
    if (index == 2) return;
    if (index == 4) {
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Open dashboard menu'),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.pushNamed(context, '/dashboard');
            },
          ),
        ),
      );
      return;
    }
    final route = switch (index) {
      0 => '/dashboard',
      1 => '/customers',
      3 => '/collection',
      _ => '/sales',
    };
    Navigator.pushNamed(context, route);
  }

  Future<void> _showFilterSheet() async {
    final selected = await showModalBottomSheet<_SalesPeriod>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Filter sales',
                style: TextStyle(
                  color: _dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ..._SalesPeriod.values.map(
                (period) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(period.label),
                  trailing: Icon(
                    period == _selectedPeriod
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: period == _selectedPeriod ? _primary : _muted,
                  ),
                  onTap: () => Navigator.pop(sheetContext, period),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedPeriod = selected);
    }
  }

  String _displaySaleId(String id) {
    if (id.startsWith('S-')) return id;
    final digits = id.replaceAll(RegExp(r'\D'), '');
    final suffix = digits.length <= 6
        ? digits
        : digits.substring(digits.length - 6);
    return 'S-${suffix.padLeft(6, '0')}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatMoney(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    var whole = parts.first;
    if (whole.length > 3) {
      final lastThree = whole.substring(whole.length - 3);
      var leading = whole.substring(0, whole.length - 3);
      final chunks = <String>[];
      while (leading.length > 2) {
        chunks.insert(0, leading.substring(leading.length - 2));
        leading = leading.substring(0, leading.length - 2);
      }
      if (leading.isNotEmpty) chunks.insert(0, leading);
      whole = '${chunks.join(',')},$lastThree';
    }
    return '$whole.${parts.last}';
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: _cardDecoration(),
        child: Row(
          children: <Widget>[
            const Icon(Icons.calendar_month_rounded, color: _primary),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('SALE DATE', style: _fieldLabelStyle),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      color: _dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationPicker() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      key: ValueKey<Map<String, dynamic>?>(_selectedAllocation),
      initialValue: _selectedAllocation,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'ALLOTTED PRODUCT',
        icon: Icons.inventory_2_outlined,
      ),
      items: _dayAllocations.map((allocation) {
        final product = (allocation['product'] ?? '').toString();
        final route = (allocation['route'] ?? '').toString();
        return DropdownMenuItem<Map<String, dynamic>>(
          value: allocation,
          child: Text(
            '$product • $route (${_remainingFor(allocation)} available)',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _dark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
      onChanged: (allocation) {
        if (allocation == null) return;
        _selectedAllocation = allocation;
        _quantityController.clear();
        _setSuggestedRate();
        setState(() {});
      },
    );
  }

  // Kept as a reusable compact summary for future detail views.
  // ignore: unused_element
  Widget _buildAllocationSummary() {
    final allocation = _selectedAllocation!;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD2E3FF)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.route_rounded, color: _primary, size: 19),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${allocation['route']} • ${allocation['salesman']}',
                  style: const TextStyle(
                    color: _dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _summaryMetric('Available to sell', _availableToAdd, _green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _muted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildRouteAllocationField() {
    final customer = _selectedCustomer;

    final route = customer?['route']?.toString().trim() ?? '';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.route_outlined, color: _primary, size: 27),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Customer Route',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  customer == null
                      ? 'Select customer'
                      : route.isEmpty
                      ? 'No route assigned'
                      : route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: route.isEmpty ? _muted : _dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.route_rounded, color: _primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildCustomerInformationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNumberedHeading(2, 'Customer'),

          const SizedBox(height: 16),

          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedCustomer,
            isExpanded: true,

            decoration: _referenceInputDecoration(
              label: 'Customer Name',
              icon: Icons.person_outline_rounded,
              trailing: Icons.keyboard_arrow_down_rounded,
            ),

            hint: Text(
              _loadingCustomers ? 'Loading customers...' : 'Select Customer',
            ),

            items: _customers
                .where((customer) => customer['isActive'] != false)
                .map(
                  (customer) => DropdownMenuItem<Map<String, dynamic>>(
                    value: customer,
                    child: Text(
                      customer['name']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),

            onChanged: _loadingCustomers
                ? null
                : (customer) async {
                    if (customer == null) {
                      return;
                    }

                    setState(() {
                      _selectedCustomer = customer;

                      _selectedAllocation = null;

                      _saleProducts.clear();

                      _cart.clear();

                      _customerController.text =
                          customer['name']?.toString() ?? '';
                    });

                    await _loadCustomerProducts();
                  },

            validator: (value) {
              if (value == null) {
                return 'Please select a customer';
              }

              return null;
            },
          ),

          if (_selectedCustomer != null) ...[
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    color: _primary,
                    size: 20,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer?['name']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _dark,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          [
                                _selectedCustomer?['route']?.toString() ?? '',
                                _selectedCustomer?['mobile']?.toString() ?? '',
                              ]
                              .where((value) => value.trim().isNotEmpty)
                              .join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showProductPicker() async {
    if (_saleProducts.isEmpty) {
      _showMessage('No products are available for this customer.');
      return;
    }

    final searchController = TextEditingController();

    Map<String, dynamic>? selectedProduct;

    selectedProduct = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchController.text.trim().toLowerCase();

            final products = _saleProducts.where((product) {
              final name = product['product']?.toString().toLowerCase() ?? '';

              final variant =
                  product['variant']?.toString().toLowerCase() ?? '';

              final productId =
                  product['productId']?.toString().toLowerCase() ?? '';

              return query.isEmpty ||
                  name.contains(query) ||
                  variant.contains(query) ||
                  productId.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * .78,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Product',
                                style: TextStyle(
                                  color: _dark,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Search and select a product for this bill',
                                style: TextStyle(color: _muted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (_) {
                        setSheetState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Search product name...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _primary,
                        ),
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();

                                  setSheetState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: products.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching products found.',
                              style: TextStyle(color: _muted),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),

                            itemCount: products.length,

                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),

                            itemBuilder: (context, index) {
                              final product = products[index];

                              final name = product['product']?.toString() ?? '';

                              final variant =
                                  product['variant']?.toString() ?? '';

                              final unit = product['unit']?.toString() ?? 'Pcs';

                              final available = _remainingFor(product);

                              final rate =
                                  double.tryParse(
                                    product['rate']?.toString() ?? '0',
                                  ) ??
                                  0;

                              final hasCustomRate =
                                  product['hasCustomRate'] == true;

                              return InkWell(
                                onTap: available > 0
                                    ? () {
                                        Navigator.pop(sheetContext, product);
                                      }
                                    : null,

                                borderRadius: BorderRadius.circular(13),

                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: available > 0
                                        ? Colors.white
                                        : AppColors.surfaceMuted,

                                    borderRadius: BorderRadius.circular(13),

                                    border: Border.all(
                                      color: available > 0
                                          ? AppColors.primaryBorder
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceBlue,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: _primary,
                                          size: 22,
                                        ),
                                      ),

                                      const SizedBox(width: 11),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: _dark,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),

                                            if (variant.trim().isNotEmpty)
                                              Text(
                                                variant,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: _muted,
                                                  fontSize: 9.5,
                                                ),
                                              ),

                                            const SizedBox(height: 4),

                                            Text(
                                              '$available $unit available',
                                              style: TextStyle(
                                                color: available > 0
                                                    ? _green
                                                    : AppColors.error,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${rate.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: _primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),

                                          Text(
                                            hasCustomRate
                                                ? 'Customer Rate'
                                                : 'Default Rate',
                                            style: TextStyle(
                                              color: hasCustomRate
                                                  ? _green
                                                  : _muted,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(width: 5),

                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: available > 0
                                            ? _primary
                                            : _muted,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (!mounted || selectedProduct == null) {
      return;
    }

    await _selectSmartProduct(selectedProduct);
  }

  Widget _buildPaymentAmountField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType: const TextInputType.numberWithOptions(decimal: true),

      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],

      decoration: _referenceInputDecoration(
        label: label,
        hint: '0.00',
        icon: icon,
        suffix: '₹',
      ),

      onChanged: (_) {
        setState(() {
          _paymentMode = _calculatedPaymentMode;
        });
      },

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null;
        }

        final amount = double.tryParse(value);

        if (amount == null || amount < 0) {
          return 'Invalid amount';
        }

        return null;
      },
    );
  }

  Widget _buildPaymentSummaryRow(
    String label,
    double value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: valueColor ?? _dark,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSmartProductInformationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNumberedHeading(3, 'Products'),

          const SizedBox(height: 14),

          // ========================================================
          // SELECT PRODUCT BUTTON
          // ========================================================
          InkWell(
            onTap: _showProductPicker,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: _primary,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Product',
                          style: TextStyle(
                            color: _dark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        SizedBox(height: 2),

                        Text(
                          'Search product and enter quantity',
                          style: TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right_rounded, color: _primary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ========================================================
          // SELECTED PRODUCTS
          // ========================================================
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bill Items',
                  style: TextStyle(
                    color: _dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_cart.length} ${_cart.length == 1 ? 'Product' : 'Products'}',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _buildSmartBillingRows(),

          // ========================================================
          // SPLIT PAYMENT
          // ========================================================
          if (_cart.isNotEmpty) ...[
            const SizedBox(height: 18),

            const Divider(),

            const SizedBox(height: 10),

            _buildNumberedHeading(4, 'Payment'),

            const SizedBox(height: 14),

            // ======================================================
            // BILL TOTAL
            // ======================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3F7FE), Color(0xFFDCEAFF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bill Amount',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enter received amount below',
                          style: TextStyle(color: _muted, fontSize: 8.5),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '₹${_cartTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ======================================================
            // CASH
            // ======================================================
            _buildPaymentAmountField(
              controller: _cashPaymentController,
              label: 'Cash',
              icon: Icons.payments_outlined,
            ),

            const SizedBox(height: 10),

            // ======================================================
            // UPI
            // ======================================================
            _buildPaymentAmountField(
              controller: _upiPaymentController,
              label: 'UPI',
              icon: Icons.qr_code_rounded,
            ),

            const SizedBox(height: 10),

            // ======================================================
            // BANK
            // ======================================================
            _buildPaymentAmountField(
              controller: _bankPaymentController,
              label: 'Bank Transfer',
              icon: Icons.account_balance_outlined,
            ),

            const SizedBox(height: 14),

            // ======================================================
            // PAYMENT SUMMARY
            // ======================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildPaymentSummaryRow('Bill Amount', _cartTotal),

                  const Divider(height: 20),

             _buildPaymentSummaryRow(
  'Paid Now',
  _paidAmount,
  valueColor: _green,
),

if (_advanceUsedPreview >
    0.001) ...[
  const SizedBox(height: 9),

  _buildPaymentSummaryRow(
    'Advance Adjusted',
    _advanceUsedPreview,
    valueColor:
        AppColors.primary,
  ),
],

const SizedBox(height: 9),

_buildPaymentSummaryRow(
  'Outstanding',
  _outstandingAmount,
  valueColor:
      _outstandingAmount > 0
          ? AppColors.error
          : _green,
),

                  const Divider(height: 20),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Payment Status',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _calculatedPaymentStatus == 'PAID'
                              ? const Color(0xFFDDF8E8)
                              : _calculatedPaymentStatus == 'PARTIAL'
                              ? const Color(0xFFFFF1D6)
                              : const Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _calculatedPaymentStatus,
                          style: TextStyle(
                            color: _calculatedPaymentStatus == 'PAID'
                                ? _green
                                : _calculatedPaymentStatus == 'PARTIAL'
                                ? const Color(0xFFA96700)
                                : AppColors.error,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_isPaymentOverAmount) ...[
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Paid amount cannot be greater than the bill amount.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartProductCard(Map<String, dynamic> allocation) {
    final product = (allocation['product'] ?? '').toString();
    final available = _remainingFor(allocation);
    final rate = _suggestedRateFor(product);
    return Material(
      color: available > 0 ? Colors.white : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: available > 0 ? () => _selectSmartProduct(allocation) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: available > 0 ? AppColors.primaryBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 54,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(_saleProductImage(product)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      product,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${rate.toStringAsFixed(0)} / unit',
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$available available',
                      style: TextStyle(
                        color: available > 0 ? _green : AppColors.error,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectSmartProduct(Map<String, dynamic> allocation) async {
    final available = _remainingFor(allocation);
    final product = (allocation['product'] ?? '').toString();
    final controller = TextEditingController(text: '1');
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add $product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$available units available',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Quantity',
                suffixText: 'Units',
              ),
              onSubmitted: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null) Navigator.pop(dialogContext, parsed);
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null) Navigator.pop(dialogContext, parsed);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 350), controller.dispose);
    if (!mounted || quantity == null) return;
    if (quantity < 1 || quantity > available) {
      _showMessage('Enter a quantity between 1 and $available.');
      return;
    }
    final existing = _cart.where(
      (line) => identical(line.allocation, allocation),
    );
    setState(() {
      if (existing.isNotEmpty) {
        existing.first.quantity += quantity;
      } else {
        _cart.add(
          _SaleLineDraft(
            allocation: allocation,
            quantity: quantity,
            rate: _suggestedRateFor(product),
          ),
        );
      }
      _selectedAllocation = allocation;
    });
  }

  Widget _buildSmartBillingRows() {
    if (_cart.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No products added yet.\nTap "Select Product" to add items to this bill.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      );
    }
    return Column(
      children: <Widget>[
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: const Color(0xFFF0F5FD),
          child: const Row(
            children: <Widget>[
              Expanded(flex: 4, child: Text('Product', style: _tableHead)),
              Expanded(
                flex: 3,
                child: Text(
                  'Qty',
                  textAlign: TextAlign.center,
                  style: _tableHead,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  style: _tableHead,
                ),
              ),
              SizedBox(width: 28),
            ],
          ),
        ),
        ...List<Widget>.generate(_cart.length, (index) {
          final line = _cart[index];
          final product = (line.allocation['product'] ?? '').toString();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 42,
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(_saleProductImage(product)),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _dark,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '₹${line.rate.toStringAsFixed(0)} / unit',
                        style: const TextStyle(color: _muted, fontSize: 8),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 33,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: <Widget>[
                        _quantityControlButton(
                          icon: Icons.remove_rounded,
                          onPressed: line.quantity > 1
                              ? () => _changeCartQuantity(line, -1)
                              : null,
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _editCartQuantity(line),
                            child: Center(
                              child: Text(
                                '${line.quantity}',
                                style: const TextStyle(
                                  color: _dark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _quantityControlButton(
                          icon: Icons.add_rounded,
                          onPressed: _remainingFor(line.allocation) > 0
                              ? () => _changeCartQuantity(line, 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '₹${line.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _cart.removeAt(index)),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildProductInformationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNumberedHeading(3, 'Product Information'),
          const SizedBox(height: 16),
          _buildAllocationPicker(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: _referenceInputDecoration(
                    label: 'Quantity',
                    hint: '0',
                    icon: Icons.inventory_2_outlined,
                    suffix: 'Units',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: _referenceInputDecoration(
                    label: 'Rate per unit',
                    hint: '0.00',
                    icon: Icons.currency_rupee_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFF2F7FF), Color(0xFFE3EEFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Total Amount',
                    style: TextStyle(
                      color: _dark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '₹${_draftTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _availableToAdd > 0 ? _addProductToSale : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildProductSelectionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _buildNumberedHeading(4, 'Product Selection')),
              Text(
                '${_cart.length} item${_cart.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_cart.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'No products selected yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            )
          else ...<Widget>[
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              color: const Color(0xFFF0F5FD),
              child: const Row(
                children: <Widget>[
                  Expanded(flex: 4, child: Text('Product', style: _tableHead)),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.center,
                      style: _tableHead,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Amount',
                      textAlign: TextAlign.right,
                      style: _tableHead,
                    ),
                  ),
                  SizedBox(width: 30),
                ],
              ),
            ),
            ...List<Widget>.generate(_cart.length, (index) {
              final line = _cart[index];
              final product = (line.allocation['product'] ?? '').toString();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBlue,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Image.asset(_saleProductImage(product)),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            product,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _dark,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${line.rate.toStringAsFixed(2)} / unit',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: <Widget>[
                            _quantityControlButton(
                              icon: Icons.remove_rounded,
                              onPressed: line.quantity > 1
                                  ? () => _changeCartQuantity(line, -1)
                                  : null,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => _editCartQuantity(line),
                                child: Center(
                                  child: Text(
                                    '${line.quantity}',
                                    style: const TextStyle(
                                      color: _dark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _quantityControlButton(
                              icon: Icons.add_rounded,
                              onPressed: _remainingFor(line.allocation) > 0
                                  ? () => _changeCartQuantity(line, 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${line.total.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: _dark,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _cart.removeAt(index)),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _quantityControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 25,
      height: 32,
      child: IconButton(
        tooltip: icon == Icons.add_rounded
            ? 'Increase quantity'
            : 'Decrease quantity',
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        color: _primary,
        disabledColor: AppColors.disabled,
      ),
    );
  }

  void _changeCartQuantity(_SaleLineDraft line, int change) {
    if (change > 0 && _remainingFor(line.allocation) <= 0) {
      _showMessage('No more allotted quantity is available.');
      return;
    }
    final nextQuantity = line.quantity + change;
    if (nextQuantity < 1) return;
    setState(() => line.quantity = nextQuantity);
  }

  Future<void> _editCartQuantity(_SaleLineDraft line) async {
    final maximum = line.quantity + _remainingFor(line.allocation);
    final controller = TextEditingController(text: '${line.quantity}');
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Quantity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Quantity',
                suffixText: 'Units',
                helperText: 'Maximum available: $maximum',
              ),
              onSubmitted: (value) {
                final entered = int.tryParse(value);
                if (entered != null) Navigator.pop(dialogContext, entered);
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final entered = int.tryParse(controller.text);
              if (entered != null) Navigator.pop(dialogContext, entered);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 350), controller.dispose);
    if (!mounted || quantity == null) return;
    if (quantity < 1 || quantity > maximum) {
      _showMessage('Enter a quantity between 1 and $maximum.');
      return;
    }
    setState(() => line.quantity = quantity);
  }

  Widget _buildSaleSummaryPanel() {
    final todayQuantity = _serverSales.fold<int>(
      0,
      (sum, sale) => sum + sale.quantity,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNumberedHeading(5, 'Sale Summary'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFF3F7FE), Color(0xFFDCEAFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total Quantity\n$_cartQuantity Units',
                    style: const TextStyle(
                      color: _dark,
                      height: 1.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'Total Amount\n₹${_cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Additional Notes (Optional)',
            style: TextStyle(color: _dark, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const TextField(
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(hintText: 'Write notes here...'),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _recentSaleMetric(
                'Total Sales',
                '₹${_formatMoney(_monthlySalesTotal)}',
              ),
              const SizedBox(width: 7),
              _recentSaleMetric('Transactions', '${_serverSales.length}'),
              const SizedBox(width: 7),
              _recentSaleMetric('Quantity', '$todayQuantity Units'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMessage('Sale saved as draft.'),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save as Draft'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _cart.isEmpty || _savingSale || _isPaymentOverAmount
                      ? null
                      : _completeSale,
             icon: _savingSale
    ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
    : Icon(
        _isEditingSale
            ? Icons.edit_outlined
            : Icons.check_circle_outline_rounded,
      ),

label: Text(
  _savingSale
      ? (_isEditingSale
          ? 'Updating...'
          : 'Saving...')
      : (_isEditingSale
          ? 'Update Sale'
          : 'Complete Sale'),
),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSaleEntryPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNumberedHeading(2, 'Customer & Quantity'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerController,
            textCapitalization: TextCapitalization.words,
            decoration: _referenceInputDecoration(
              label: 'Customer Name',
              hint: 'Select Customer',
              icon: Icons.person_outline_rounded,
              trailing: Icons.keyboard_arrow_down_rounded,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter the customer name'
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: _referenceInputDecoration(
                    label: 'Quantity',
                    hint: '0',
                    icon: Icons.inventory_2_outlined,
                    suffix: 'Units',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: _referenceInputDecoration(
                    label: 'Rate per unit',
                    hint: '0.00',
                    icon: Icons.currency_rupee_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Total Amount',
                        maxLines: 1,
                        style: TextStyle(
                          color: _dark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹${_draftTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: _referenceInputDecoration(
              label: 'Payment Mode',
              icon: Icons.account_balance_wallet_outlined,
            ),
            items: _paymentModes
                .map(
                  (mode) =>
                      DropdownMenuItem<String>(value: mode, child: Text(mode)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _paymentMode = value);
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _referenceInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? suffix,
    IconData? trailing,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      suffixIcon: trailing == null ? null : Icon(trailing, size: 20),
      prefixIcon: Icon(icon, color: _primary, size: 23),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: _muted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.3),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSaleProductsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _buildNumberedHeading(3, 'Products')),
              const SizedBox(width: 8),
              Text(
                '${_cart.length} item${_cart.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: _availableToAdd > 0 ? _addProductToSale : null,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Product'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: _primary),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_cart.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Enter quantity and rate, then tap Add Product.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            )
          else ...<Widget>[
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F5FD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: const Row(
                children: <Widget>[
                  Expanded(flex: 4, child: Text('Product', style: _tableHead)),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.center,
                      style: _tableHead,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Amount',
                      textAlign: TextAlign.right,
                      style: _tableHead,
                    ),
                  ),
                  SizedBox(width: 30),
                ],
              ),
            ),
            ...List<Widget>.generate(_cart.length, (index) {
              final line = _cart[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 46,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        _saleProductImage(
                          (line.allocation['product'] ?? '').toString(),
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            (line.allocation['product'] ?? '').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _dark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Pouch',
                            style: TextStyle(color: _muted, fontSize: 9.5),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${line.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _dark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${line.total.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: _dark,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _cart.removeAt(index)),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFFF3F7FE), Color(0xFFDCEAFF)],
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Total Quantity\n$_cartQuantity Units',
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 11,
                        height: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeep,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total Amount\n₹${_cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildNumberedHeading(4, 'Additional Notes (Optional)'),
          const SizedBox(height: 10),
          const TextField(
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(hintText: 'Write notes here...'),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.access_time_rounded, color: _primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recent Sales (Today)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _dark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _recentSaleMetric(
                      'Total Sales',
                      '₹${_formatMoney(_monthlySalesTotal)}',
                    ),
                    const SizedBox(width: 7),
                    _recentSaleMetric('Transactions', '${_serverSales.length}'),
                    const SizedBox(width: 7),
                    _recentSaleMetric(
                      'Total Quantity',
                      '${_serverSales.fold<int>(0, (sum, sale) => sum + sale.quantity)} Units',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMessage('Sale saved as draft.'),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save as Draft'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cart.isEmpty ? null : _completeSale,
                  icon: Icon(
                    _isEditingSale
                        ? Icons.edit_outlined
                        : Icons.check_circle_outline_rounded,
                  ),
                  label: Text(
                    _savingSale
                        ? (_isEditingSale ? 'Updating...' : 'Saving...')
                        : (_isEditingSale ? 'Update Sale' : 'Complete Sale'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentSaleMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 8.5),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: _dark,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _saleProductImage(String product) {
    if (product.toLowerCase().contains('curd')) {
      return 'assets/img/product_curd.png';
    }
    if (product.contains('1 L')) {
      return 'assets/img/product_full_cream_milk.png';
    }
    return 'assets/img/product_toned_milk.png';
  }

  // ignore: unused_element
  Widget _buildSaleForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNumberedHeading(2, 'Customer & Quantity'),
          const SizedBox(height: 15),
          TextFormField(
            controller: _customerController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              label: 'Customer Name',
              icon: Icons.person_outline_rounded,
              hint: 'Enter customer name',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter the customer name'
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: _inputDecoration(
                    label: 'Quantity',
                    icon: Icons.local_drink_outlined,
                    hint: 'Max $_availableToAdd',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: _inputDecoration(
                    label: 'Rate per unit',
                    icon: Icons.currency_rupee_rounded,
                    hint: '0.00',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: _inputDecoration(
              label: 'Payment Mode',
              icon: Icons.account_balance_wallet_outlined,
            ),
            items: _paymentModes
                .map(
                  (mode) =>
                      DropdownMenuItem<String>(value: mode, child: Text(mode)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _paymentMode = value);
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Amount for this product',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${_draftTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _availableToAdd > 0 ? _addProductToSale : null,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: Text(
                _availableToAdd > 0 ? 'Add Product' : 'Product Exhausted',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildSaleCart(),
        ],
      ),
    );
  }

  Widget _buildSaleCart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _buildNumberedHeading(3, 'Products')),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_cart.length} item${_cart.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_cart.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1E7F0)),
            ),
            child: const Text(
              'Select a product, enter quantity and rate, then tap Add Product.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          )
        else ...<Widget>[
          ...List<Widget>.generate(_cart.length, (index) {
            final line = _cart[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(11, 9, 5, 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E7F0)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          (line.allocation['product'] ?? '').toString(),
                          style: const TextStyle(
                            color: _dark,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${line.quantity} × ₹${line.rate.toStringAsFixed(2)}'
                          ' • ${line.allocation['route']}',
                          style: const TextStyle(color: _muted, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${line.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _dark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove product',
                    onPressed: () => setState(() => _cart.removeAt(index)),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFE14B4B),
                      size: 19,
                    ),
                  ),
                ],
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$_cartQuantity total units',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Total ₹${_cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _cart.isEmpty ? null : _completeSale,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text(
              'Complete Sale',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAllocation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: _cardDecoration(),
      child: const Column(
        children: <Widget>[
          Icon(Icons.inventory_2_outlined, color: _muted, size: 42),
          SizedBox(height: 10),
          Text(
            'No milk allotted for this date',
            textAlign: TextAlign.center,
            style: TextStyle(color: _dark, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 5),
          Text(
            'Create an allocation first, then return here to record sales.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildRecentSales() {
    final sales = _serverSales.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Recent sales',
          style: TextStyle(
            color: _dark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (sales.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: const Text(
              'No sales recorded yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          )
        else
          ...sales.map(_buildSaleTile),
      ],
    );
  }

  Widget _buildSaleTile(SaleModel sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        children: <Widget>[
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_rounded, color: _green),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  sale.customerName,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${sale.quantity} × ${sale.product} • ${sale.paymentMode}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Text(
            '₹${sale.total.toStringAsFixed(0)}',
            style: const TextStyle(
              color: _green,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE1E7F0)),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary, size: 21),
      labelStyle: _fieldLabelStyle,
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE1E7F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE1E7F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = <String>[
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
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  static const TextStyle _fieldLabelStyle = TextStyle(
    color: _muted,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle _tableHead = TextStyle(
    color: _dark,
    fontSize: 10,
    fontWeight: FontWeight.w900,
  );
}

class _SaleLineDraft {
  _SaleLineDraft({
    required this.allocation,
    required this.quantity,
    required this.rate,
  });

  final Map<String, dynamic> allocation;
  int quantity;
  final double rate;

  double get total => quantity * rate;
}

enum _SalesPeriod {
  all('All Sales'),
  today('Today'),
  week('This Week'),
  month('This Month');

  const _SalesPeriod(this.label);

  final String label;
}
