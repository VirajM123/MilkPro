import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../theme/app_colors.dart';

import '../../models/sale_model.dart';
import '../returns/return_settlement_screen.dart';
import 'sales_bill_preview_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  static const Color _primary = AppColors.primary;
  static const Color _dark = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _green = AppColors.success;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  late DateTime _selectedDate;
  Map<String, dynamic>? _selectedAllocation;
  String _paymentMode = 'Cash';
  final List<_SaleLineDraft> _cart = <_SaleLineDraft>[];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();
  bool _isCreatingSale = false;
  bool _showSearch = false;
  _SalesPeriod _selectedPeriod = _SalesPeriod.all;
final List<Map<String, dynamic>> _customers =
    <Map<String, dynamic>>[];

final List<Map<String, dynamic>> _saleProducts =
    <Map<String, dynamic>>[];

final List<SaleModel> _serverSales =
    <SaleModel>[];
    final Set<String> _cancelledSaleIds =
    <String>{};

bool _cancellingSale = false;

Map<String, dynamic>? _selectedCustomer;

bool _loadingCustomers = false;
bool _loadingProducts = false;
bool _loadingSales = false;
bool _savingSale = false;

  final List<String> _paymentModes = const <String>[
    'Cash',
    'UPI',
    'Credit',
    'Bank Transfer',
  ];

@override
void initState() {
  super.initState();

  _selectedDate = DateTime.now();

  _quantityController.addListener(_refreshTotal);
  _rateController.addListener(_refreshTotal);

  _loadCustomers();
  _loadSales();
}

  @override
  void dispose() {
    _quantityController.removeListener(_refreshTotal);
    _rateController.removeListener(_refreshTotal);
    _customerController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _searchController.dispose();
    _productSearchController.dispose();
    super.dispose();
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
      return double.tryParse(
            item['rate']?.toString() ?? '0',
          ) ??
          0;
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
      final records =
          data['data'] as List<dynamic>? ?? <dynamic>[];

      final loadedSales = <SaleModel>[];

      final cancelledIds = <String>{};


      for (final record in records) {
        final sale =
            Map<String, dynamic>.from(record as Map);
            final saleIdentifier =
    sale['saleNo']?.toString() ??
    sale['saleId']?.toString() ??
    sale['_id']?.toString() ??
    '';

final status =
    sale['status']
        ?.toString()
        .toUpperCase() ??
    'POSTED';

if (status == 'CANCELLED' &&
    saleIdentifier.isNotEmpty) {
  cancelledIds.add(
    saleIdentifier,
  );
}

        final products =
            sale['products'] as List<dynamic>? ??
            <dynamic>[];

        final saleDate =
            DateTime.tryParse(
              sale['saleDate']?.toString() ?? '',
            ) ??
            DateTime.now();

        // Current SaleModel is product-line based.
        // Therefore one MongoDB sale containing multiple
        // products is converted into multiple SaleModel lines.
        for (int index = 0;
            index < products.length;
            index++) {
          final product =
              Map<String, dynamic>.from(
                products[index] as Map,
              );

          loadedSales.add(
            SaleModel(
              id:
                  sale['saleNo']?.toString() ??
                  sale['saleId']?.toString() ??
                  sale['_id']?.toString() ??
                  '',

              date: saleDate,

              customerName:
                  sale['customerName']
                      ?.toString() ??
                  '',

              route:
                  sale['route']?.toString() ??
                  '',

              salesman:
                  sale['createdRole']
                              ?.toString()
                              .toLowerCase() ==
                          'admin'
                      ? 'Admin'
                      : sale['createdRole']
                              ?.toString() ??
                          '',

              product:
                  product['productName']
                      ?.toString() ??
                  '',

              quantity:
                  int.tryParse(
                    product['quantity']
                            ?.toString() ??
                        '0',
                  ) ??
                  0,

              rate:
                  double.tryParse(
                    product['rate']
                            ?.toString() ??
                        '0',
                  ) ??
                  0,

              paymentMode:
                  sale['paymentMode']
                      ?.toString() ??
                  'Cash',
            ),
          );
        }
      }

      if (!mounted) return;
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
            ? data['message']?.toString() ??
                'Unable to load sales.'
            : 'Unable to load sales.',
      );
    }
  } catch (error) {
    if (!mounted) return;

    _showMessage(
      'Unable to load sales from server: $error',
    );
  } finally {
    if (mounted) {
      setState(() {
        _loadingSales = false;
      });
    }
  }
}
bool _isSaleCancelled(
  SaleModel sale,
) {
  return _cancelledSaleIds.contains(
    sale.id,
  );
}
Future<void> _cancelSale(
  SaleModel sale,
) async {
  if (_cancellingSale) {
    return;
  }

  if (_isSaleCancelled(sale)) {
    _showMessage(
      'This sale is already cancelled.',
    );
    return;
  }

  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Cancel Sale',
        ),
       content: Text(
  'Are you sure you want to cancel ${sale.id}?\n\n'
  'The stock will be restored to the correct available stock automatically.',
),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child: const Text(
              'No',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.error,
              foregroundColor:
                  Colors.white,
            ),
            child: const Text(
              'Yes, Cancel Sale',
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true ||
      !mounted) {
    return;
  }

  setState(() {
    _cancellingSale = true;
  });

  try {
    final response =
        await http.put(
      Uri.parse(
        '${ApiConfig.sales}/${Uri.encodeComponent(sale.id)}/cancel',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer ${ApiConfig.token}',
      },
    );

    final data =
        jsonDecode(
      response.body,
    );

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
    } else {
      _showMessage(
        data is Map
            ? data['message']?.toString() ??
                'Unable to cancel sale.'
            : 'Unable to cancel sale.',
      );
    }
  } catch (error) {
    if (!mounted) {
      return;
    }

    _showMessage(
      'Unable to cancel sale: $error',
    );
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
      final records =
          data['data'] as List<dynamic>? ?? <dynamic>[];

      setState(() {
        _customers
          ..clear()
          ..addAll(
            records.map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          );
      });
    } else {
      _showMessage(
        data is Map
            ? data['message']?.toString() ??
                'Unable to load customers.'
            : 'Unable to load customers.',
      );
    }
  } catch (error) {
    if (!mounted) return;

    _showMessage(
      'Unable to load customers from server: $error',
    );
  } finally {
    if (mounted) {
      setState(() {
        _loadingCustomers = false;
      });
    }
  }
}

Future<void> _loadCustomerProducts() async {
  final customer = _selectedCustomer;

  if (customer == null) return;

  final customerId =
      customer['customerId']?.toString() ?? '';

  if (customerId.isEmpty) {
    _showMessage('Customer ID not found.');
    return;
  }

  setState(() {
    _loadingProducts = true;
    _saleProducts.clear();
    _cart.clear();
    _selectedAllocation = null;
  });

  try {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.customerRates}/$customerId',
      ),
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
      final records =
          data['data'] as List<dynamic>? ?? <dynamic>[];

      final loadedProducts =
          <Map<String, dynamic>>[];

      for (final item in records) {
        final map =
            Map<String, dynamic>.from(item as Map);

        loadedProducts.add({
          'productId':
              map['productId']?.toString() ?? '',

          'product':
              map['productName']?.toString() ?? '',

          'variant':
              map['variant']?.toString() ?? '',

          'unit':
              map['unit']?.toString() ?? 'Pcs',

          'qty':
              int.tryParse(
                    map['stock']?.toString() ?? '0',
                  ) ??
                  0,

          'returnedQty': 0,
          'soldQty': 0,

          'rate':
              double.tryParse(
                    map['specialRate']?.toString() ?? '0',
                  ) ??
                  0,

          'defaultRate':
              double.tryParse(
                    map['defaultRate']?.toString() ?? '0',
                  ) ??
                  0,

          'hasCustomRate':
              map['hasCustomRate'] == true,

          'route':
              customer['route']?.toString() ?? '',

          'salesman': 'Admin',
        });
      }

      setState(() {
        _saleProducts
          ..clear()
          ..addAll(loadedProducts);

        if (_saleProducts.isNotEmpty) {
          _selectedAllocation =
              _saleProducts.first;

          _setSuggestedRate();
        }
      });
    } else {
      _showMessage(
        data is Map
            ? data['message']?.toString() ??
                'Unable to load products.'
            : 'Unable to load products.',
      );
    }
  } catch (error) {
    if (!mounted) return;

    _showMessage(
      'Unable to load customer products: $error',
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
  if (_savingSale) return;

  if (!(_formKey.currentState?.validate() ?? false)) {
    return;
  }

  final customer = _selectedCustomer;

  if (customer == null) {
    _showMessage('Please select a customer.');
    return;
  }

  if (_cart.isEmpty) {
    _showMessage(
      'Add at least one product before completing the sale.',
    );
    return;
  }

  final customerId =
      customer['customerId']?.toString() ?? '';

  if (customerId.isEmpty) {
    _showMessage('Customer ID not found.');
    return;
  }

  setState(() {
    _savingSale = true;
  });

  try {
    final response = await http.post(
      Uri.parse(ApiConfig.sales),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.token}',
      },
      body: jsonEncode({
        'saleDate': _selectedDate.toIso8601String(),
        'customerId': customerId,
        'paymentMode': _paymentMode,
        'products': _cart.map((line) {
          return {
            'productId':
                line.allocation['productId']?.toString() ?? '',
            'quantity': line.quantity,
          };
        }).toList(),
      }),
    );

    final data = jsonDecode(response.body);

    if (!mounted) return;

    if (response.statusCode == 201 &&
        data is Map<String, dynamic> &&
        data['success'] == true) {
      final saleData =
          data['data'] as Map<String, dynamic>?;

      final saleNo =
          saleData?['saleNo']?.toString() ?? '';

      _showMessage(
        saleNo.isEmpty
            ? 'Sale saved successfully.'
            : 'Sale $saleNo saved successfully.',
        color: _green,
      );

      // Keep same customer selected so we can
      // immediately reload updated stock.
      setState(() {
        _cart.clear();
        _quantityController.clear();
        _rateController.clear();
        _selectedAllocation = null;
      });

      // Reload products from server.
      // This will show reduced stock immediately.
     await _loadCustomerProducts();
await _loadSales();
    } else {
      _showMessage(
        data is Map
            ? data['message']?.toString() ??
                'Unable to save sale.'
            : 'Unable to save sale.',
      );
    }
  } catch (error) {
    if (!mounted) return;

    _showMessage(
      'Unable to save sale: $error',
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
        _buildNumberedHeading(
          1,
          'Sale Information',
        ),

        const SizedBox(height: 16),

        Row(
          children: <Widget>[
            Expanded(
              child: _buildDateField(),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildRouteAllocationField(),
            ),
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
        child: Center(
          child: CircularProgressIndicator(),
        ),
      )
    else if (_saleProducts.isEmpty)
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: const Text(
          'No products available.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _muted,
          ),
        ),
      )
    else
      _buildSmartProductInformationPanel(),

    if (!_loadingProducts &&
        _saleProducts.isNotEmpty) ...<Widget>[
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
                  onPressed: () => setState(() => _isCreatingSale = false),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Create New Sale',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Milk Distribution',
                        style: TextStyle(
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
        const SizedBox(width: 9),
      ],
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
      final matchesQuery =
          query.isEmpty ||
          sale.id.toLowerCase().contains(query) ||
          sale.customerName.toLowerCase().contains(query) ||
          sale.product.toLowerCase().contains(query);
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
  final now =
      DateTime.now();

  return _salesSource
      .where(
        (sale) =>
            !_isSaleCancelled(sale) &&
            sale.date.year ==
                now.year &&
            sale.date.month ==
                now.month,
      )
      .fold<double>(
        0,
        (total, sale) =>
            total + sale.total,
      );
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
    final isCancelled =
    _isSaleCancelled(sale);
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
                  'Sale #${_displaySaleId(sale.id)}',
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
                  'Customer: ${sale.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
      Container(
  padding:
      const EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 6,
  ),
  decoration: BoxDecoration(
    color: isCancelled
        ? const Color(0xFFFFE5E5)
        : const Color(0xFFDDF8E8),
    borderRadius:
        BorderRadius.circular(20),
  ),
  child: Text(
    isCancelled
        ? 'Cancelled'
        : 'Completed',
    style: TextStyle(
      color: isCancelled
          ? AppColors.error
          : const Color(0xFF21884B),
      fontSize: 10.5,
      fontWeight:
          FontWeight.w800,
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
                        '${sale.quantity} Item${sale.quantity == 1 ? '' : 's'}',
                        style: const TextStyle(color: _muted, fontSize: 11.5),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                PopupMenuButton<String>(
  tooltip: 'Sale actions',

  onSelected: (action) async {
    if (action == 'pdf') {
      _openBill(sale);
      return;
    }

    if (action == 'whatsapp') {
      _openBill(
        sale,
        openWhatsApp: true,
      );
      return;
    }

    if (action == 'cancel') {
      await _cancelSale(sale);
    }
  },

  itemBuilder: (_) {
    return <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'pdf',
        child: ListTile(
          leading: Icon(
            Icons.picture_as_pdf_outlined,
          ),
          title: Text(
            'View PDF Bill',
          ),
          contentPadding:
              EdgeInsets.zero,
        ),
      ),

      const PopupMenuItem<String>(
        value: 'whatsapp',
        child: ListTile(
          leading: Icon(
            Icons.chat_outlined,
          ),
          title: Text(
            'Send on WhatsApp',
          ),
          contentPadding:
              EdgeInsets.zero,
        ),
      ),

      if (!isCancelled)
        const PopupMenuDivider(),

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
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            contentPadding:
                EdgeInsets.zero,
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

void _openCreateSale() {
  setState(() {
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

    _paymentMode = 'Cash';
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

  final route =
      customer?['route']
          ?.toString()
          .trim() ??
      '';

  return Container(
    height: 72,
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(12),
      border:
          Border.all(
        color: AppColors.border,
      ),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.route_outlined,
          color: _primary,
          size: 27,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Customer Route',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
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
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      route.isEmpty
                          ? _muted
                          : _dark,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        const Icon(
          Icons.route_rounded,
          color: _primary,
          size: 20,
        ),
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
          _buildNumberedHeading(2, 'Customer Information'),
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
    _loadingCustomers
        ? 'Loading customers...'
        : 'Select Customer',
  ),

  items: _customers
      .where(
        (customer) =>
            customer['isActive'] != false,
      )
      .map(
        (customer) =>
            DropdownMenuItem<Map<String, dynamic>>(
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
          _selectedCustomer =
              customer;

          _selectedAllocation =
              null;

          _saleProducts.clear();

          _cart.clear();

          _customerController.text =
              customer['name']
                      ?.toString() ??
                  '';
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

  Widget _buildSmartProductInformationPanel() {
    final query = _productSearchController.text.trim().toLowerCase();
    final products = _dayAllocations.where((allocation) {
      final name = (allocation['product'] ?? '').toString().toLowerCase();
      return query.isEmpty || name.contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNumberedHeading(3, 'Product Information'),
          const SizedBox(height: 14),
          TextField(
            controller: _productSearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search product...',
              prefixIcon: const Icon(Icons.search_rounded, color: _primary),
              suffixIcon: _productSearchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear product search',
                      onPressed: () {
                        _productSearchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No matching allotted products.',
                  style: TextStyle(color: _muted),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.42,
              ),
              itemBuilder: (context, index) {
                final allocation = products[index];
                return _buildSmartProductCard(allocation);
              },
            ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Selected Products',
                  style: TextStyle(
                    color: _dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
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
          const SizedBox(height: 10),
          _buildSmartBillingRows(),
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Tap a product above to enter quantity.',
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
            _recentSaleMetric(
  'Transactions',
  '${_serverSales.length}',
),
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
      _cart.isEmpty || _savingSale
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
      : const Icon(
          Icons.check_circle_outline_rounded,
        ),
  label: Text(
    _savingSale
        ? 'Saving...'
        : 'Complete Sale',
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
                   _recentSaleMetric(
  'Transactions',
  '${_serverSales.length}',
),
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
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Complete Sale'),
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
