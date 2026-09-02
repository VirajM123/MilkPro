import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class AssignAllocationPage extends StatefulWidget {
  const AssignAllocationPage({
    super.key,
    required this.routes,
    required this.salesmen,
    required this.products,
  });

  final List<String> routes;
  final List<String> salesmen;
  final List<String> products;

  @override
  State<AssignAllocationPage> createState() => _AssignAllocationPageState();
}

class _AssignAllocationPageState extends State<AssignAllocationPage> {
  static const _customers = <String>[
    'Shree Ganesh Dairy',
    'City Fresh Mart',
    'Sunrise Dairy',
  ];

  final _notes = TextEditingController();
  final _search = TextEditingController();
  final Map<String, TextEditingController> _quantities = {};
  final Set<String> _selected = {};
  late DateTime _date;
  String? _route;
  String? _salesman;
  String _customer = _customers.first;
  String _query = '';

  List<ProductModel> get _catalog {
    final requested = widget.products.toSet();
    final products = ProductStore.products
        .where((item) => requested.isEmpty || requested.contains(item.name))
        .toList(growable: true);
    for (final name in widget.products) {
      if (products.any((item) => item.name == name)) continue;
      products.add(
        ProductModel(
          name: name,
          variant: 'Standard',
          unit: 'Pcs',
          stock: 0,
          price: 0,
          assetPath: '',
        ),
      );
    }
    return products;
  }

  List<ProductModel> get _visibleProducts {
    final query = _query.trim().toLowerCase();
    return _catalog
        .where(
          (item) =>
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.variant.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Map<String, num> get _unitTotals {
    final totals = <String, num>{};
    for (final product in _catalog.where(
      (item) => _selected.contains(item.name),
    )) {
      final quantity = int.tryParse(_quantities[product.name]?.text ?? '') ?? 0;
      if (quantity > 0) {
        totals.update(
          product.unit,
          (value) => value + quantity,
          ifAbsent: () => quantity,
        );
      }
    }
    return totals;
  }

  String get _summaryText {
    final totals = _unitTotals.entries
        .map((entry) => '${entry.value} ${entry.key}')
        .join(' • ');
    return totals.isEmpty ? 'No quantity entered' : totals;
  }

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _route = widget.routes.firstOrNull;
    _salesman = widget.salesmen.firstOrNull;
    for (final product in _catalog) {
      _quantities[product.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _search.dispose();
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _toggleProduct(ProductModel product, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(product.name);
      } else {
        _selected.remove(product.name);
        _quantities[product.name]?.clear();
      }
    });
  }

  void _toggleVisibleProducts() {
    final visible = _visibleProducts;
    final allSelected =
        visible.isNotEmpty &&
        visible.every((item) => _selected.contains(item.name));
    setState(() {
      for (final product in visible) {
        if (allSelected) {
          _selected.remove(product.name);
          _quantities[product.name]?.clear();
        } else {
          _selected.add(product.name);
        }
      }
    });
  }

  void _changeQuantity(ProductModel product, int change) {
    final controller = _quantities[product.name]!;
    final current = int.tryParse(controller.text) ?? 0;
    final next = (current + change).clamp(0, product.stock.toInt());
    setState(() {
      controller.text = next == 0 ? '' : '$next';
      if (next > 0) {
        _selected.add(product.name);
      }
    });
  }

  void _save() {
    if (_route == null || _salesman == null) {
      _message('Route and salesman are required.');
      return;
    }
    final selectedProducts = _catalog
        .where((item) => _selected.contains(item.name))
        .toList();
    if (selectedProducts.isEmpty) {
      _message('Select at least one product.');
      return;
    }
    for (final product in selectedProducts) {
      final quantity = int.tryParse(_quantities[product.name]?.text ?? '') ?? 0;
      if (quantity <= 0) {
        _message('Enter a quantity for ${product.name}.');
        return;
      }
      if (quantity > product.stock) {
        _message('${product.name} exceeds available stock.');
        return;
      }
    }
    final batch =
        '${_date.millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
    Navigator.pop(
      context,
      selectedProducts
          .map(
            (product) => <String, dynamic>{
              'batchId': batch,
              'date': _date,
              'route': _route,
              'salesman': _salesman,
              'customer': _customer,
              'product': product.name,
              'unit': product.unit,
              'qty': int.parse(_quantities[product.name]!.text),
              'returnedQty': 0,
              'notes': _notes.text.trim(),
            },
          )
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Assign Allocation',
        subtitle: 'Allocate multiple products in one entry',
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
                '${_selected.length} selected • quantities stay separated by unit',
            action: TextButton(
              onPressed: _clearAll,
              child: const Text('Clear'),
            ),
          ),
          const SizedBox(height: 10),
          AppSearchField(
            controller: _search,
            hint: 'Search product',
            onChanged: (value) => setState(() => _query = value),
            trailing: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value:
                _visibleProducts.isNotEmpty &&
                _visibleProducts.every((item) => _selected.contains(item.name)),
            title: const Text(
              'Select all visible products',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${_visibleProducts.length} products'),
            onChanged: (_) => _toggleVisibleProducts(),
          ),
          if (_visibleProducts.isEmpty)
            const AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No products found',
              message: 'Try a different product name.',
            )
          else
            ..._visibleProducts.map(_productCard),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _notes,
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

  Widget _detailsCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Allocation Details'),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              child: Text(_formatDate(_date)),
            ),
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            initialValue: _route,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Route',
              prefixIcon: Icon(Icons.route_outlined),
            ),
            items: widget.routes
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => _route = value),
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            initialValue: _salesman,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Salesman',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: widget.salesmen
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => _salesman = value),
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            initialValue: _customer,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Customer / Outlet',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            items: _customers
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) =>
                setState(() => _customer = value ?? _customer),
          ),
        ],
      ),
    ),
  );

  Widget _productCard(ProductModel product) {
    final selected = _selected.contains(product.name);
    final quantity = int.tryParse(_quantities[product.name]?.text ?? '') ?? 0;
    final exceedsStock = quantity > product.stock;
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
                  onChanged: (value) => _toggleProduct(product, value ?? false),
                ),
                Container(
                  height: 46,
                  width: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: product.assetPath.isEmpty
                      ? const Icon(Icons.inventory_2_outlined)
                      : Image.asset(
                          product.assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.inventory_2_outlined),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${product.variant} • Available: '
                        '${product.stock.toStringAsFixed(0)} ${product.unit}',
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
                              controller: _quantities[product.name],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: '0',
                                suffixText: product.unit,
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
      onPressed: onTap,
      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
      child: Icon(icon),
    ),
  );

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
                  '${_selected.length} Products',
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
            onPressed: _save,
            child: const Text('ASSIGN ALLOCATION'),
          ),
        ],
      ),
    ),
  );

  void _clearAll() => setState(() {
    _selected.clear();
    for (final controller in _quantities.values) {
      controller.clear();
    }
  });

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
