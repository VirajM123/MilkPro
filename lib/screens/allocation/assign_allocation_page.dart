import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../common/access_denied_screen.dart';

class AssignAllocationPage extends StatefulWidget {
  const AssignAllocationPage({
    super.key,
    required this.routes,
    required this.salesmen,
    required this.products,
    this.existingAllocation,
  });

  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> salesmen;
  final List<Map<String, dynamic>> products;

  // null = Create
  // not null = Edit
  final Map<String, dynamic>? existingAllocation;

  @override
  State<AssignAllocationPage> createState() => _AssignAllocationPageState();
}

class _AssignAllocationPageState extends State<AssignAllocationPage> {
  final TextEditingController _notes = TextEditingController();

  // final TextEditingController _search = TextEditingController();

  final Map<String, TextEditingController> _quantities =
      <String, TextEditingController>{};

  final Set<String> _selectedProductIds = <String>{};

  late DateTime _date;

  String? _routeId;
  String? _salesmanId;

  // String _query = '';

  bool _saving = false;
  bool get _isEditing => widget.existingAllocation != null;

  String get _editingAllocationId =>
      (widget.existingAllocation?['allocationId'] ?? '').toString().trim();
  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString().trim() ?? '') ?? 0.0;
  }

  String _formatQty(num value) {
    final double number = value.toDouble();

    if (number == number.roundToDouble()) {
      return number.toStringAsFixed(0);
    }

    return number
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  bool get _hasExistingActivity {
    final dynamic rawProducts = widget.existingAllocation?['products'];

    if (rawProducts is! List) {
      return false;
    }

    for (final dynamic raw in rawProducts) {
      if (raw is! Map) {
        continue;
      }

      final double sold = _asDouble(raw['soldQuantity']);

      final double returned = _asDouble(raw['returnedQuantity']);

      if (sold > 0 || returned > 0) {
        return true;
      }
    }

    return false;
  }

  double _oldAllocatedQuantity(String productId) {
    final dynamic rawProducts = widget.existingAllocation?['products'];

    if (rawProducts is! List) {
      return 0;
    }

    for (final dynamic raw in rawProducts) {
      if (raw is! Map) {
        continue;
      }

      final String id = (raw['productId'] ?? '').toString().trim();

      if (id == productId) {
        return _asDouble(raw['quantity']);
      }
    }

    return 0;
  }

  double _minimumAllowedQuantity(String productId) {
    final dynamic rawProducts = widget.existingAllocation?['products'];

    if (rawProducts is! List) {
      return 0;
    }

    for (final dynamic raw in rawProducts) {
      if (raw is! Map) {
        continue;
      }

      final String id = (raw['productId'] ?? '').toString().trim();

      if (id != productId) {
        continue;
      }

      final double sold = _asDouble(raw['soldQuantity']);

      final double returned = _asDouble(raw['returnedQuantity']);

      return sold + returned;
    }

    return 0;
  }

  double _maximumAllowedQuantity(Map<String, dynamic> product) {
    final String productId = _productId(product);

    final double warehouseStock = _productStock(product).toDouble();

    if (!_isEditing) {
      return warehouseStock;
    }

    return warehouseStock + _oldAllocatedQuantity(productId);
  }
  // ============================================================
  // PRODUCT HELPERS
  // ============================================================

  List<Map<String, dynamic>> get _catalog {
    return widget.products
        .where(
          (item) => item['isActive'] != false && _productId(item).isNotEmpty,
        )
        .toList(growable: false);
  }

  String _productId(Map<String, dynamic> product) {
    return (product['productId'] ?? '').toString().trim();
  }

  String _productName(Map<String, dynamic> product) {
    return (product['productName'] ?? product['name'] ?? '').toString().trim();
  }

  String _productVariant(Map<String, dynamic> product) {
    return (product['variant'] ?? '').toString().trim();
  }

  String _productUnit(Map<String, dynamic> product) {
    final String unit = (product['unit'] ?? '').toString().trim();

    return unit.isEmpty ? 'Pcs' : unit;
  }

  num _productStock(Map<String, dynamic> product) {
    final dynamic value = product['stock'];

    if (value is num) {
      return value;
    }

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // MASTER HELPERS
  // ============================================================

  String _routeName(Map<String, dynamic> route) {
    return (route['routeName'] ?? '').toString().trim();
  }

  String _salesmanName(Map<String, dynamic> salesman) {
    return (salesman['name'] ?? '').toString().trim();
  }

  Map<String, dynamic>? _findRoute(String? routeId) {
    if (routeId == null) {
      return null;
    }

    for (final route in widget.routes) {
      if ((route['routeId'] ?? '').toString() == routeId) {
        return route;
      }
    }

    return null;
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Map<String, num> get _unitTotals {
    final Map<String, num> totals = <String, num>{};

    for (final product in _catalog) {
      final String productId = _productId(product);

      if (!_selectedProductIds.contains(productId)) {
        continue;
      }
      final double quantity =
          double.tryParse(_quantities[productId]?.text.trim() ?? '') ?? 0;

      if (quantity <= 0) {
        continue;
      }

      final String unit = _productUnit(product);

      totals.update(
        unit,
        (value) => value + quantity,
        ifAbsent: () => quantity,
      );
    }

    return totals;
  }

  String get _summaryText {
    final String totals = _unitTotals.entries
        .map((entry) => '${_formatQty(entry.value)} ${entry.key}')
        .join(' • ');

    return totals.isEmpty ? 'No quantity entered' : totals;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ============================================================
    // CREATE MODE
    // ============================================================

    _date = DateTime.now();

    if (widget.routes.isNotEmpty) {
      final Map<String, dynamic> firstRoute = widget.routes.first;

      _routeId = (firstRoute['routeId'] ?? '').toString();

      final String routeSalesmanId = (firstRoute['salesmanId'] ?? '')
          .toString()
          .trim();

      if (routeSalesmanId.isNotEmpty &&
          widget.salesmen.any(
            (item) => (item['salesmanId'] ?? '').toString() == routeSalesmanId,
          )) {
        _salesmanId = routeSalesmanId;
      }
    }

    if (_salesmanId == null && widget.salesmen.isNotEmpty) {
      _salesmanId = (widget.salesmen.first['salesmanId'] ?? '').toString();
    }

    // ============================================================
    // PRODUCT CONTROLLERS
    // ============================================================

    for (final product in _catalog) {
      final String productId = _productId(product);

      _quantities[productId] = TextEditingController();
    }

    // ============================================================
    // EDIT MODE - RESTORE EXISTING ALLOCATION
    // ============================================================

    final Map<String, dynamic>? existing = widget.existingAllocation;

    if (existing == null) {
      return;
    }

    final dynamic rawDate = existing['allocationDate'];

    if (rawDate != null) {
      _date =
          DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now();
    }

    _routeId = (existing['routeId'] ?? '').toString().trim();

    _salesmanId = (existing['salesmanId'] ?? '').toString().trim();

    _notes.text = (existing['notes'] ?? '').toString();

    final dynamic rawProducts = existing['products'];

    if (rawProducts is List) {
      for (final dynamic raw in rawProducts) {
        if (raw is! Map) {
          continue;
        }

        final String productId = (raw['productId'] ?? '').toString().trim();

        final double quantity = _asDouble(raw['quantity']);

        if (productId.isEmpty || quantity <= 0) {
          continue;
        }

        if (!_quantities.containsKey(productId)) {
          continue;
        }

        _selectedProductIds.add(productId);

        _quantities[productId]!.text = _formatQty(quantity);
      }
    }
  }

  @override
  void dispose() {
    _notes.dispose();

    for (final controller in _quantities.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );

    if (picked != null && mounted) {
      setState(() {
        _date = picked;
      });
    }
  }

  // ============================================================
  // PRODUCT SELECTION
  // ============================================================
  void _toggleProduct(Map<String, dynamic> product, bool selected) {
    final String productId = _productId(product);

    if (!selected && _isEditing && _minimumAllowedQuantity(productId) > 0) {
      _message(
        '${_productName(product)} cannot be removed because sales or returns already exist.',
      );
      return;
    }

    setState(() {
      if (selected) {
        _selectedProductIds.add(productId);
      } else {
        _selectedProductIds.remove(productId);

        _quantities[productId]?.clear();
      }
    });
  }

  void _changeQuantity(Map<String, dynamic> product, double change) {
    final String productId = _productId(product);

    final TextEditingController controller = _quantities[productId]!;

    final double current = double.tryParse(controller.text.trim()) ?? 0;

    final double maximumQuantity = _maximumAllowedQuantity(product);

    final double minimumQuantity = _isEditing
        ? _minimumAllowedQuantity(productId)
        : 0;

    final double next = (current + change)
        .clamp(minimumQuantity, maximumQuantity)
        .toDouble();

    setState(() {
      controller.text = next <= 0 ? '' : _formatQty(next);

      if (next > 0) {
        _selectedProductIds.add(productId);
      }
    });
  }

  // ============================================================
  // ROUTE CHANGE
  // ============================================================
  void _onRouteChanged(String? value) {
    setState(() {
      _routeId = value;

      // Clear previous salesman first.
      // This prevents a stale salesman remaining selected
      // if the new route has no valid salesman assignment.
      _salesmanId = null;

      final route = _findRoute(value);

      if (route == null) {
        return;
      }

      final String assignedSalesmanId = (route['salesmanId'] ?? '')
          .toString()
          .trim();

      if (assignedSalesmanId.isEmpty) {
        return;
      }

      final bool exists = widget.salesmen.any(
        (salesman) =>
            (salesman['salesmanId'] ?? '').toString().trim() ==
            assignedSalesmanId,
      );

      if (exists) {
        _salesmanId = assignedSalesmanId;
      }
    });
  }

  // ============================================================
  // SAVE ALLOCATION
  // ============================================================

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    if (_routeId == null || _routeId!.trim().isEmpty) {
      _message('Route is required.');
      return;
    }
    // ============================================================
// VERIFY ROUTE -> SALESMAN RELATIONSHIP
//
// Route Master is the source of truth.
// One salesman may have many routes,
// but every route belongs to one salesman.
// ============================================================

final selectedRoute =
    _findRoute(
  _routeId,
);

if (selectedRoute == null) {
  _message(
    'Selected route not found.',
  );
  return;
}

final String
    assignedSalesmanId =
    (selectedRoute[
                'salesmanId'] ??
            '')
        .toString()
        .trim();

if (assignedSalesmanId.isEmpty) {
  _message(
    'Selected route does not have a salesman assigned.',
  );
  return;
}

if (assignedSalesmanId !=
    _salesmanId!.trim()) {
  _message(
    'Selected salesman does not match the salesman assigned to this route.',
  );
  return;
}

    if (_salesmanId == null || _salesmanId!.trim().isEmpty) {
      _message('Salesman is required.');
      return;
    }

    final List<Map<String, dynamic>> selectedProducts = _catalog
        .where((item) => _selectedProductIds.contains(_productId(item)))
        .toList();

    if (selectedProducts.isEmpty) {
      _message('Select at least one product.');
      return;
    }

    final List<Map<String, dynamic>> requestProducts = <Map<String, dynamic>>[];

    for (final product in selectedProducts) {
      final String productId = _productId(product);

      final String productName = _productName(product);

      final double quantity =
          double.tryParse(_quantities[productId]?.text.trim() ?? '') ?? 0;

      if (quantity <= 0) {
        _message('Enter a quantity for $productName.');
        return;
      }
      final double maximumQuantity = _maximumAllowedQuantity(product);

      final double minimumQuantity = _isEditing
          ? _minimumAllowedQuantity(productId)
          : 0;

      if (quantity > maximumQuantity) {
        _message(
          '$productName exceeds available quantity. Maximum allowed is $maximumQuantity.',
        );
        return;
      }

      if (quantity < minimumQuantity) {
        _message(
          '$productName cannot be reduced below $minimumQuantity because stock is already sold or returned.',
        );
        return;
      }

      requestProducts.add({'productId': productId, 'quantity': quantity});
    }

    setState(() {
      _saving = true;
    });

    try {
      final Uri uri = _isEditing
          ? Uri.parse(
              '${ApiConfig.baseUrl}/api/allocations/$_editingAllocationId',
            )
          : Uri.parse('${ApiConfig.baseUrl}/api/allocations');

      final Map<String, dynamic> body = <String, dynamic>{
        'allocationDate': _date.toIso8601String(),

        'routeId': _routeId,

        'salesmanId': _salesmanId,

        'notes': _notes.text.trim(),

        'products': requestProducts,
      };

      final http.Response response;

      if (_isEditing) {
        response = await http.put(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',

            'Authorization': 'Bearer ${ApiConfig.token}',
          },
          body: jsonEncode(body),
        );
      } else {
        response = await http.post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',

            'Authorization': 'Bearer ${ApiConfig.token}',
          },
          body: jsonEncode(body),
        );
      }

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      final int expectedStatus = _isEditing ? 200 : 201;

      if (response.statusCode != expectedStatus) {
        final String message = decoded is Map
            ? decoded['message']?.toString() ?? 'Unable to save allocation.'
            : 'Unable to save allocation.';

        throw Exception(message);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(_date);
    } catch (error) {
      if (!mounted) {
        return;
      }

      String message = error.toString();

      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }

      _message(message);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (UiSession.instance.role != UserRole.admin) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      appBar: PremiumAppBar(
        title: _isEditing ? 'Edit Allocation' : 'Assign Allocation',

        subtitle: _isEditing
            ? 'Update allocated products and quantity'
            : 'Allocate multiple products in one entry',
      ),
      bottomNavigationBar: _bottomSummary(),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _detailsCard(),
          const SizedBox(height: 14),
          AppSectionTitle(
            title: 'Products & Quantity',
            subtitle:
                '${_selectedProductIds.length} selected • Allocate only required products',
            action: _selectedProductIds.isEmpty
                ? null
                : TextButton(
                    onPressed: _saving ? null : _clearAll,
                    child: const Text('Clear'),
                  ),
          ),

          const SizedBox(height: 10),

          // ============================================================
          // PRODUCT PICKER BUTTON
          // ============================================================
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _saving ? null : _openProductPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBlue,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Products',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Search and select products from stock',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_selectedProductIds.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selectedProductIds.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                  const SizedBox(width: 6),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ============================================================
          // SELECTED PRODUCTS ONLY
          // ============================================================
          if (_selectedProductIds.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 34,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No products selected',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tap Select Products to add products.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Selected Products',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                Text(
                  '${_selectedProductIds.length} products',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ..._catalog
                .where(
                  (product) =>
                      _selectedProductIds.contains(_productId(product)),
                )
                .map(_productCard),
          ],
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _notes,
                enabled: !_saving,
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS CARD
  // ============================================================

  Widget _detailsCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Allocation Details'),
          const SizedBox(height: 14),
          InkWell(
            onTap: _saving ? null : _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              child: Text(_formatDate(_date)),
            ),
          ),
          const SizedBox(height: 11),

          // ==========================================
          // ROUTE
          // ==========================================
          DropdownButtonFormField<String>(
            initialValue: _routeId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Route',
              prefixIcon: Icon(Icons.route_outlined),
            ),
            items: widget.routes.where((item) => item['isActive'] != false).map(
              (item) {
                final String routeId = (item['routeId'] ?? '').toString();

                return DropdownMenuItem<String>(
                  value: routeId,
                  child: Text(_routeName(item)),
                );
              },
            ).toList(),
            onChanged: _saving || (_isEditing && _hasExistingActivity)
                ? null
                : _onRouteChanged,
          ),

          const SizedBox(height: 11),

          // ==========================================
          // SALESMAN
          // ==========================================
         DropdownButtonFormField<String>(
  key: ValueKey(
    'salesman_$_salesmanId',
  ),

  initialValue:
      _salesmanId,

  isExpanded:
      true,

  decoration:
      const InputDecoration(
    labelText:
        'Assigned Salesman',

    prefixIcon:
        Icon(
      Icons.badge_outlined,
    ),

    helperText:
        'Automatically selected from Route Master.',
  ),

  items:
      widget.salesmen
          .where(
            (item) =>
                item['isActive'] !=
                false,
          )
          .map(
            (item) {
              final String
                  salesmanId =
                  (item[
                              'salesmanId'] ??
                          '')
                      .toString()
                      .trim();

              return DropdownMenuItem<
                  String>(
                value:
                    salesmanId,

                child:
                    Text(
                  _salesmanName(
                    item,
                  ),
                ),
              );
            },
          )
          .toList(),

  // ==========================================================
  // IMPORTANT
  //
  // Route Master is the source of truth.
  //
  // One Route -> One Salesman
  // One Salesman -> Multiple Routes
  //
  // Therefore salesman must not be manually changed here.
  // Changing Route automatically updates salesman.
  // ==========================================================

  onChanged:
      null,
),
        ],
      ),
    ),
  );

  Future<void> _openProductPicker() async {
    final TextEditingController searchController = TextEditingController();

    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final String normalizedQuery = query.trim().toLowerCase();

            final List<Map<String, dynamic>> filteredProducts = _catalog.where((
              product,
            ) {
              final String name = _productName(product).toLowerCase();

              final String variant = _productVariant(product).toLowerCase();

              final String productId = _productId(product).toLowerCase();

              return normalizedQuery.isEmpty ||
                  name.contains(normalizedQuery) ||
                  variant.contains(normalizedQuery) ||
                  productId.contains(normalizedQuery);
            }).toList();

            final bool allVisibleSelected =
                filteredProducts.isNotEmpty &&
                filteredProducts.every(
                  (product) =>
                      _selectedProductIds.contains(_productId(product)),
                );

            return Container(
              height: MediaQuery.of(context).size.height * .88,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ==================================================
                  // HANDLE
                  // ==================================================
                  const SizedBox(height: 8),

                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // ==================================================
                  // HEADER
                  // ==================================================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Products',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Search, select and then enter quantities.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // SEARCH
                  // ==================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      autofocus: false,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setSheetState(() {
                          query = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search product name, variant or ID',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();

                                  setSheetState(() {
                                    query = '';
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // SELECT ALL VISIBLE
                  // ==================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Checkbox(
                          value: allVisibleSelected,
                          onChanged: filteredProducts.isEmpty
                              ? null
                              : (_) {
                                  setState(() {
                                    for (final product in filteredProducts) {
                                      final String productId = _productId(
                                        product,
                                      );

                                      if (allVisibleSelected) {
                                        _selectedProductIds.remove(productId);

                                        _quantities[productId]?.clear();
                                      } else {
                                        _selectedProductIds.add(productId);
                                      }
                                    }
                                  });

                                  setSheetState(() {});
                                },
                        ),

                        Expanded(
                          child: Text(
                            allVisibleSelected
                                ? 'Unselect visible products'
                                : 'Select all visible products',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        Text(
                          '${filteredProducts.length} products',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // ==================================================
                  // PRODUCT LIST
                  // ==================================================
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 42,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No matching products',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                            itemCount: filteredProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];

                              final String productId = _productId(product);

                              final String productName = _productName(product);

                              final String variant = _productVariant(product);

                              final String unit = _productUnit(product);

                              final num stock = _productStock(product);

                              final bool selected = _selectedProductIds
                                  .contains(productId);

                              return Material(
                                color: selected
                                    ? AppColors.surfaceBlue
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      if (selected) {
                                        _selectedProductIds.remove(productId);

                                        _quantities[productId]?.clear();
                                      } else {
                                        _selectedProductIds.add(productId);
                                      }
                                    });

                                    setSheetState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: selected,
                                          onChanged: (_) {
                                            setState(() {
                                              if (selected) {
                                                _selectedProductIds.remove(
                                                  productId,
                                                );

                                                _quantities[productId]?.clear();
                                              } else {
                                                _selectedProductIds.add(
                                                  productId,
                                                );
                                              }
                                            });

                                            setSheetState(() {});
                                          },
                                        ),

                                        const SizedBox(width: 2),

                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.inventory_2_outlined,
                                            size: 20,
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                productName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${variant.isEmpty ? 'Standard' : variant} • '
                                                '${stock.toStringAsFixed(0)} $unit available',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 10,
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
                            },
                          ),
                  ),

                  // ==================================================
                  // BOTTOM BUTTON
                  // ==================================================
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_selectedProductIds.length} product${_selectedProductIds.length == 1 ? '' : 's'} selected',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);

                              setState(() {});
                            },
                            child: const Text('DONE'),
                          ),
                        ],
                      ),
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

    if (mounted) {
      setState(() {});
    }
  }
  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _productCard(Map<String, dynamic> product) {
    final String productId = _productId(product);

    final String productName = _productName(product);

    final String variant = _productVariant(product);

    final String unit = _productUnit(product);

    final double stock = _productStock(product).toDouble();

    final bool selected = _selectedProductIds.contains(productId);

    final double quantity =
        double.tryParse(_quantities[productId]?.text.trim() ?? '') ?? 0;

    final double maxAllowed = _maximumAllowedQuantity(product);

    final bool exceedsStock = quantity > maxAllowed;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? AppColors.surfaceBlue : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: _saving
                      ? null
                      : (value) => _toggleProduct(product, value ?? false),
                ),
                Container(
                  height: 46,
                  width: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${variant.isEmpty ? 'Standard' : variant} • Available: '
                        '${_formatQty(stock)} $unit',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: !selected
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          _stepButton(
                            Icons.remove_rounded,
                            () => _changeQuantity(product, -1),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _quantities[productId],
                              enabled: !_saving,
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: false,
                                  ),

                              inputFormatters: [
                                TextInputFormatter.withFunction((
                                  oldValue,
                                  newValue,
                                ) {
                                  final bool valid = RegExp(
                                    r'^\d*\.?\d{0,2}$',
                                  ).hasMatch(newValue.text);

                                  return valid ? newValue : oldValue;
                                }),
                              ],
                              onChanged: (_) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                hintText: '0',
                                suffixText: unit,
                                errorText: exceedsStock
                                    ? 'Exceeds stock'
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _stepButton(
                            Icons.add_rounded,
                            () => _changeQuantity(product, 1),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) => SizedBox.square(
    dimension: 48,
    child: OutlinedButton(
      onPressed: _saving ? null : onTap,
      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
      child: Icon(icon),
    ),
  );

  // ============================================================
  // BOTTOM SUMMARY
  // ============================================================

  Widget _bottomSummary() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedProductIds.length} Products',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _summaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'UPDATE ALLOCATION' : 'ASSIGN ALLOCATION'),
          ),
        ],
      ),
    ),
  );

  // ============================================================
  // CLEAR
  // ============================================================

  void _clearAll() {
    setState(() {
      _selectedProductIds.clear();

      for (final controller in _quantities.values) {
        controller.clear();
      }
    });
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
