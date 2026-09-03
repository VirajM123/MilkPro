import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class AssignAllocationPage extends StatefulWidget {
  const AssignAllocationPage({
    super.key,
    required this.routes,
    required this.salesmen,
    required this.products,
    required this.customers,
  });

  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> salesmen;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> customers;

  @override
  State<AssignAllocationPage> createState() =>
      _AssignAllocationPageState();
}

class _AssignAllocationPageState
    extends State<AssignAllocationPage> {
  final TextEditingController _notes =
      TextEditingController();

  final TextEditingController _search =
      TextEditingController();

  final Map<String, TextEditingController>
      _quantities =
      <String, TextEditingController>{};

  final Set<String> _selectedProductIds =
      <String>{};

  late DateTime _date;

  String? _routeId;
  String? _salesmanId;
  String? _customerId;

  String _query = '';

  bool _saving = false;

  // ============================================================
  // PRODUCT HELPERS
  // ============================================================

  List<Map<String, dynamic>> get _catalog {
    return widget.products
        .where(
          (item) =>
              item['isActive'] != false &&
              _productId(item).isNotEmpty,
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>>
      get _visibleProducts {
    final String query =
        _query.trim().toLowerCase();

    return _catalog.where((item) {
      final String name =
          _productName(item).toLowerCase();

      final String variant =
          _productVariant(item).toLowerCase();

      return query.isEmpty ||
          name.contains(query) ||
          variant.contains(query);
    }).toList(growable: false);
  }

  String _productId(
    Map<String, dynamic> product,
  ) {
    return (product['productId'] ?? '')
        .toString()
        .trim();
  }

  String _productName(
    Map<String, dynamic> product,
  ) {
    return (product['productName'] ??
            product['name'] ??
            '')
        .toString()
        .trim();
  }

  String _productVariant(
    Map<String, dynamic> product,
  ) {
    return (product['variant'] ?? '')
        .toString()
        .trim();
  }

  String _productUnit(
    Map<String, dynamic> product,
  ) {
    final String unit =
        (product['unit'] ?? '')
            .toString()
            .trim();

    return unit.isEmpty ? 'Pcs' : unit;
  }

  num _productStock(
    Map<String, dynamic> product,
  ) {
    final dynamic value =
        product['stock'];

    if (value is num) {
      return value;
    }

    return num.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // MASTER HELPERS
  // ============================================================

  String _routeName(
    Map<String, dynamic> route,
  ) {
    return (route['routeName'] ?? '')
        .toString()
        .trim();
  }

  String _salesmanName(
    Map<String, dynamic> salesman,
  ) {
    return (salesman['name'] ?? '')
        .toString()
        .trim();
  }

  String _customerName(
    Map<String, dynamic> customer,
  ) {
    return (customer['name'] ?? '')
        .toString()
        .trim();
  }

  Map<String, dynamic>? _findRoute(
    String? routeId,
  ) {
    if (routeId == null) {
      return null;
    }

    for (final route in widget.routes) {
      if ((route['routeId'] ?? '')
              .toString() ==
          routeId) {
        return route;
      }
    }

    return null;
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Map<String, num> get _unitTotals {
    final Map<String, num> totals =
        <String, num>{};

    for (final product in _catalog) {
      final String productId =
          _productId(product);

      if (!_selectedProductIds.contains(
        productId,
      )) {
        continue;
      }

      final int quantity =
          int.tryParse(
                _quantities[productId]
                        ?.text ??
                    '',
              ) ??
              0;

      if (quantity <= 0) {
        continue;
      }

      final String unit =
          _productUnit(product);

      totals.update(
        unit,
        (value) => value + quantity,
        ifAbsent: () => quantity,
      );
    }

    return totals;
  }

  String get _summaryText {
    final String totals =
        _unitTotals.entries
            .map(
              (entry) =>
                  '${entry.value} ${entry.key}',
            )
            .join(' • ');

    return totals.isEmpty
        ? 'No quantity entered'
        : totals;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _date = DateTime.now();

    if (widget.routes.isNotEmpty) {
      final Map<String, dynamic>
          firstRoute =
          widget.routes.first;

      _routeId =
          (firstRoute['routeId'] ?? '')
              .toString();

      final String routeSalesmanId =
          (firstRoute['salesmanId'] ?? '')
              .toString()
              .trim();

      if (routeSalesmanId.isNotEmpty &&
          widget.salesmen.any(
            (item) =>
                (item['salesmanId'] ?? '')
                    .toString() ==
                routeSalesmanId,
          )) {
        _salesmanId =
            routeSalesmanId;
      }
    }

    if (_salesmanId == null &&
        widget.salesmen.isNotEmpty) {
      _salesmanId =
          (widget.salesmen.first[
                      'salesmanId'] ??
                  '')
              .toString();
    }

    if (widget.customers.isNotEmpty) {
      _customerId =
          (widget.customers.first[
                      'customerId'] ??
                  '')
              .toString();
    }

    for (final product in _catalog) {
      final String productId =
          _productId(product);

      _quantities[productId] =
          TextEditingController();
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _search.dispose();

    for (final controller
        in _quantities.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _pickDate() async {
    final DateTime? picked =
        await showDatePicker(
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

  void _toggleProduct(
    Map<String, dynamic> product,
    bool selected,
  ) {
    final String productId =
        _productId(product);

    setState(() {
      if (selected) {
        _selectedProductIds.add(
          productId,
        );
      } else {
        _selectedProductIds.remove(
          productId,
        );

        _quantities[productId]
            ?.clear();
      }
    });
  }

  void _toggleVisibleProducts() {
    final List<Map<String, dynamic>>
        visible =
        _visibleProducts;

    final bool allSelected =
        visible.isNotEmpty &&
        visible.every(
          (item) =>
              _selectedProductIds.contains(
            _productId(item),
          ),
        );

    setState(() {
      for (final product in visible) {
        final String productId =
            _productId(product);

        if (allSelected) {
          _selectedProductIds.remove(
            productId,
          );

          _quantities[productId]
              ?.clear();
        } else {
          _selectedProductIds.add(
            productId,
          );
        }
      }
    });
  }

  void _changeQuantity(
    Map<String, dynamic> product,
    int change,
  ) {
    final String productId =
        _productId(product);

    final TextEditingController
        controller =
        _quantities[productId]!;

    final int current =
        int.tryParse(
              controller.text,
            ) ??
            0;

    final int availableStock =
        _productStock(product).toInt();

    final int next =
        (current + change).clamp(
      0,
      availableStock,
    );

    setState(() {
      controller.text =
          next == 0 ? '' : '$next';

      if (next > 0) {
        _selectedProductIds.add(
          productId,
        );
      }
    });
  }

  // ============================================================
  // ROUTE CHANGE
  // ============================================================

  void _onRouteChanged(
    String? value,
  ) {
    setState(() {
      _routeId = value;

      final route =
          _findRoute(value);

      if (route == null) {
        return;
      }

      final String assignedSalesmanId =
          (route['salesmanId'] ?? '')
              .toString()
              .trim();

      if (assignedSalesmanId.isEmpty) {
        return;
      }

      final bool exists =
          widget.salesmen.any(
        (salesman) =>
            (salesman['salesmanId'] ?? '')
                .toString() ==
            assignedSalesmanId,
      );

      if (exists) {
        _salesmanId =
            assignedSalesmanId;
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

    if (_routeId == null ||
        _routeId!.trim().isEmpty) {
      _message(
        'Route is required.',
      );
      return;
    }

    if (_salesmanId == null ||
        _salesmanId!.trim().isEmpty) {
      _message(
        'Salesman is required.',
      );
      return;
    }

    final List<Map<String, dynamic>>
        selectedProducts =
        _catalog
            .where(
              (item) =>
                  _selectedProductIds
                      .contains(
                _productId(item),
              ),
            )
            .toList();

    if (selectedProducts.isEmpty) {
      _message(
        'Select at least one product.',
      );
      return;
    }

    final List<Map<String, dynamic>>
        requestProducts =
        <Map<String, dynamic>>[];

    for (final product
        in selectedProducts) {
      final String productId =
          _productId(product);

      final String productName =
          _productName(product);

      final int quantity =
          int.tryParse(
                _quantities[productId]
                        ?.text
                        .trim() ??
                    '',
              ) ??
              0;

      if (quantity <= 0) {
        _message(
          'Enter a quantity for $productName.',
        );
        return;
      }

      final num stock =
          _productStock(product);

      if (quantity > stock) {
        _message(
          '$productName exceeds available stock.',
        );
        return;
      }

      requestProducts.add({
        'productId':
            productId,
        'quantity':
            quantity,
      });
    }

    setState(() {
      _saving = true;
    });

    try {
      final http.Response response =
          await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/allocations',
        ),
        headers: <String, String>{
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer ${ApiConfig.token}',
        },
        body: jsonEncode({
          'allocationDate':
              _date.toIso8601String(),

          'routeId':
              _routeId,

          'salesmanId':
              _salesmanId,

          'customerId':
              _customerId ?? '',

          'notes':
              _notes.text.trim(),

          'products':
              requestProducts,
        }),
      );

      dynamic decoded;

      try {
        decoded =
            jsonDecode(
          response.body,
        );
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode != 201) {
        final String message =
            decoded is Map
                ? decoded['message']
                        ?.toString() ??
                    'Unable to save allocation.'
                : 'Unable to save allocation.';

        throw Exception(
          message,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        true,
      );
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

      _message(
        message,
      );
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
    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Assign Allocation',
        subtitle:
            'Allocate multiple products in one entry',
      ),
      bottomNavigationBar:
          _bottomSummary(),
      body: ListView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior
                .onDrag,
        padding:
            const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        children: [
          _detailsCard(),
          const SizedBox(
            height: 14,
          ),
          AppSectionTitle(
            title:
                'Products & Quantity',
            subtitle:
                '${_selectedProductIds.length} selected • quantities stay separated by unit',
            action: TextButton(
              onPressed:
                  _saving
                      ? null
                      : _clearAll,
              child:
                  const Text(
                'Clear',
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          AppSearchField(
            controller:
                _search,
            hint:
                'Search product',
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            trailing:
                _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed:
                            () {
                          _search
                              .clear();

                          setState(
                            () {
                              _query =
                                  '';
                            },
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .close_rounded,
                        ),
                      ),
          ),
          const SizedBox(
            height: 8,
          ),
          CheckboxListTile(
            contentPadding:
                EdgeInsets.zero,
            controlAffinity:
                ListTileControlAffinity
                    .leading,
            value:
                _visibleProducts
                        .isNotEmpty &&
                    _visibleProducts.every(
                      (item) =>
                          _selectedProductIds
                              .contains(
                        _productId(
                          item,
                        ),
                      ),
                    ),
            title:
                const Text(
              'Select all visible products',
              style:
                  TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '${_visibleProducts.length} products',
            ),
            onChanged:
                _saving
                    ? null
                    : (_) =>
                        _toggleVisibleProducts(),
          ),
          if (_visibleProducts
              .isEmpty)
            const AppEmptyState(
              icon:
                  Icons.search_off_rounded,
              title:
                  'No products found',
              message:
                  'Try a different product name.',
            )
          else
            ..._visibleProducts.map(
              _productCard,
            ),
          const SizedBox(
            height: 14,
          ),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: TextField(
                controller:
                    _notes,
                enabled:
                    !_saving,
                minLines: 2,
                maxLines: 3,
                textInputAction:
                    TextInputAction.done,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Notes (optional)',
                  prefixIcon:
                      Icon(
                    Icons.notes_rounded,
                  ),
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

  Widget _detailsCard() =>
      Card(
        child: Padding(
          padding:
              const EdgeInsets.all(
            16,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const AppSectionTitle(
                title:
                    'Allocation Details',
              ),
              const SizedBox(
                height: 14,
              ),
              InkWell(
                onTap:
                    _saving
                        ? null
                        : _pickDate,
                child:
                    InputDecorator(
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Date',
                    prefixIcon:
                        Icon(
                      Icons
                          .calendar_month_outlined,
                    ),
                  ),
                  child:
                      Text(
                    _formatDate(
                      _date,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 11,
              ),

              // ==========================================
              // ROUTE
              // ==========================================

              DropdownButtonFormField<
                  String>(
                initialValue:
                    _routeId,
                isExpanded:
                    true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Route',
                  prefixIcon:
                      Icon(
                    Icons.route_outlined,
                  ),
                ),
                items:
                    widget.routes
                        .where(
                          (item) =>
                              item['isActive'] !=
                              false,
                        )
                        .map(
                          (item) {
                            final String
                                routeId =
                                (item['routeId'] ??
                                        '')
                                    .toString();

                            return DropdownMenuItem<
                                String>(
                              value:
                                  routeId,
                              child:
                                  Text(
                                _routeName(
                                  item,
                                ),
                              ),
                            );
                          },
                        )
                        .toList(),
                onChanged:
                    _saving
                        ? null
                        : _onRouteChanged,
              ),

              const SizedBox(
                height: 11,
              ),

              // ==========================================
              // SALESMAN
              // ==========================================

              DropdownButtonFormField<
                  String>(
                key: ValueKey(
                  _salesmanId,
                ),
                initialValue:
                    _salesmanId,
                isExpanded:
                    true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Salesman',
                  prefixIcon:
                      Icon(
                    Icons.badge_outlined,
                  ),
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
                                (item['salesmanId'] ??
                                        '')
                                    .toString();

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
                onChanged:
                    _saving
                        ? null
                        : (value) {
                            setState(
                              () {
                                _salesmanId =
                                    value;
                              },
                            );
                          },
              ),

              const SizedBox(
                height: 11,
              ),

              // ==========================================
              // CUSTOMER
              // ==========================================

              DropdownButtonFormField<
                  String>(
                initialValue:
                    _customerId,
                isExpanded:
                    true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Customer / Outlet',
                  prefixIcon:
                      Icon(
                    Icons
                        .storefront_outlined,
                  ),
                ),
                items:
                    widget.customers
                        .where(
                          (item) =>
                              item['isActive'] !=
                              false,
                        )
                        .map(
                          (item) {
                            final String
                                customerId =
                                (item['customerId'] ??
                                        '')
                                    .toString();

                            return DropdownMenuItem<
                                String>(
                              value:
                                  customerId,
                              child:
                                  Text(
                                _customerName(
                                  item,
                                ),
                              ),
                            );
                          },
                        )
                        .toList(),
                onChanged:
                    _saving
                        ? null
                        : (value) {
                            setState(
                              () {
                                _customerId =
                                    value;
                              },
                            );
                          },
              ),
            ],
          ),
        ),
      );

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _productCard(
    Map<String, dynamic> product,
  ) {
    final String productId =
        _productId(product);

    final String productName =
        _productName(product);

    final String variant =
        _productVariant(product);

    final String unit =
        _productUnit(product);

    final num stock =
        _productStock(product);

    final bool selected =
        _selectedProductIds.contains(
      productId,
    );

    final int quantity =
        int.tryParse(
              _quantities[productId]
                      ?.text ??
                  '',
            ) ??
            0;

    final bool exceedsStock =
        quantity > stock;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      color:
          selected
              ? AppColors.surfaceBlue
              : AppColors.surface,
      child: Padding(
        padding:
            const EdgeInsets.all(
          12,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value:
                      selected,
                  onChanged:
                      _saving
                          ? null
                          : (value) =>
                              _toggleProduct(
                                product,
                                value ??
                                    false,
                              ),
                ),
                Container(
                  height:
                      46,
                  width:
                      46,
                  padding:
                      const EdgeInsets.all(
                    4,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.surface,
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons
                        .inventory_2_outlined,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        productName,
                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .textPrimary,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        '${variant.isEmpty ? 'Standard' : variant} • Available: '
                        '${stock.toStringAsFixed(0)} $unit',
                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .textSecondary,
                          fontSize:
                              11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration:
                  const Duration(
                milliseconds: 150,
              ),
              child:
                  !selected
                      ? const SizedBox
                          .shrink()
                      : Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 10,
                          ),
                          child:
                              Row(
                            children: [
                              _stepButton(
                                Icons
                                    .remove_rounded,
                                () =>
                                    _changeQuantity(
                                  product,
                                  -1,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child:
                                    TextField(
                                  controller:
                                      _quantities[
                                          productId],
                                  enabled:
                                      !_saving,
                                  textAlign:
                                      TextAlign
                                          .center,
                                  keyboardType:
                                      TextInputType
                                          .number,
                                  textInputAction:
                                      TextInputAction
                                          .next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter
                                        .digitsOnly,
                                  ],
                                  onChanged:
                                      (_) {
                                    setState(
                                      () {},
                                    );
                                  },
                                  decoration:
                                      InputDecoration(
                                    hintText:
                                        '0',
                                    suffixText:
                                        unit,
                                    errorText:
                                        exceedsStock
                                            ? 'Exceeds stock'
                                            : null,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              _stepButton(
                                Icons
                                    .add_rounded,
                                () =>
                                    _changeQuantity(
                                  product,
                                  1,
                                ),
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

  Widget _stepButton(
    IconData icon,
    VoidCallback onTap,
  ) =>
      SizedBox.square(
        dimension:
            48,
        child:
            OutlinedButton(
          onPressed:
              _saving
                  ? null
                  : onTap,
          style:
              OutlinedButton.styleFrom(
            padding:
                EdgeInsets.zero,
          ),
          child:
              Icon(
            icon,
          ),
        ),
      );

  // ============================================================
  // BOTTOM SUMMARY
  // ============================================================

  Widget _bottomSummary() =>
      SafeArea(
        top:
            false,
        child:
            Container(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12,
          ),
          decoration:
              const BoxDecoration(
            color:
                AppColors.surface,
            border:
                Border(
              top:
                  BorderSide(
                color:
                    AppColors.border,
              ),
            ),
          ),
          child:
              Row(
            children: [
              Expanded(
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize
                          .min,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      '${_selectedProductIds.length} Products',
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textPrimary,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                    Text(
                      _summaryText,
                      maxLines:
                          1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textSecondary,
                        fontSize:
                            11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              ElevatedButton(
                onPressed:
                    _saving
                        ? null
                        : _save,
                child:
                    _saving
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
                            'ASSIGN ALLOCATION',
                          ),
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

      for (final controller
          in _quantities.values) {
        controller.clear();
      }
    });
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(
            message,
          ),
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
  }

  String _formatDate(
    DateTime date,
  ) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}