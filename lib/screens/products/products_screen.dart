import 'package:flutter/material.dart';

import '../../models/access_models.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

enum _StockFilter { all, available, low }

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  String _category = 'All';
  _StockFilter _stockFilter = _StockFilter.all;

  bool get _canManageProducts => UiSession.instance.role == UserRole.admin;

  List<ProductModel> get _products {
    final query = _query.trim().toLowerCase();
    return ProductStore.products
        .where((product) {
          final matchesQuery =
              query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              product.variant.toLowerCase().contains(query);
          final matchesCategory =
              _category == 'All' || product.category == _category;
          final matchesStock = switch (_stockFilter) {
            _StockFilter.all => true,
            _StockFilter.available => product.stock > 0,
            _StockFilter.low => product.isLowStock,
          };
          return matchesQuery && matchesCategory && matchesStock;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{
      'All',
      ...ProductStore.products.map((item) => item.category),
    };
    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Products',
        subtitle: 'Product catalogue and current stock',
        actions: _canManageProducts
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton.filled(
                    tooltip: 'Add product',
                    onPressed: () => _showProductDialog(),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppSearchField(
                hint: 'Search product or variant',
                onChanged: (value) => setState(() => _query = value),
                trailing: IconButton(
                  tooltip: 'Stock filter',
                  onPressed: _showStockFilter,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories.elementAt(index);
                  return ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: AppSectionTitle(
                title: '${_products.length} products',
                subtitle: _stockFilter == _StockFilter.low
                    ? 'Showing low-stock products'
                    : 'Live data connection is not configured',
              ),
            ),
            Expanded(
              child: _products.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products found',
                      message: 'Try changing the search or stock filter.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _products.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, index) => _productCard(_products[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(ProductModel product) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              product.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_drink_outlined,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.variant} • ${product.category}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.stock.toStringAsFixed(0)} ${product.unit}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              StatusChip(
                label: product.isLowStock ? 'Low stock' : 'Available',
                color: product.isLowStock
                    ? AppColors.warning
                    : AppColors.success,
              ),
              if (_canManageProducts) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () => _showProductDialog(product: product),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _showProductDialog({ProductModel? product}) async {
    if (!_canManageProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only an administrator can manage products.'),
        ),
      );
      return;
    }

    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name);
    final variantController = TextEditingController(text: product?.variant);
    final stockController = TextEditingController(
      text: product?.stock.toStringAsFixed(0),
    );
    final priceController = TextEditingController(
      text: product?.price.toStringAsFixed(0),
    );
    final categoryController = TextEditingController(
      text: product?.category ?? 'Dairy',
    );
    final formKey = GlobalKey<FormState>();
    var unit = product?.unit ?? 'Pcs';

    final saved = await showDialog<ProductModel>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Product' : 'Add Product'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _productField(
                      controller: nameController,
                      label: 'Product name',
                    ),
                    const SizedBox(height: 12),
                    _productField(
                      controller: variantController,
                      label: 'Variant / pack size',
                    ),
                    const SizedBox(height: 12),
                    _productField(
                      controller: categoryController,
                      label: 'Category',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const ['Ltr', 'Kg', 'Pcs', 'Box', 'Pkt']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => unit = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _productField(
                            controller: stockController,
                            label: 'Opening stock',
                            numeric: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _productField(
                            controller: priceController,
                            label: 'Price',
                            numeric: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(
                  dialogContext,
                  ProductModel(
                    name: nameController.text.trim(),
                    variant: variantController.text.trim(),
                    unit: unit,
                    stock: double.parse(stockController.text.trim()),
                    price: double.parse(priceController.text.trim()),
                    assetPath: product?.assetPath ?? '',
                    category: categoryController.text.trim(),
                    lowStockLevel: product?.lowStockLevel ?? 20,
                    isActive: product?.isActive ?? true,
                  ),
                );
              },
              child: Text(isEditing ? 'Save Changes' : 'Add Product'),
            ),
          ],
        ),
      ),
    );

    // The dialog route remains in the tree briefly while its closing animation
    // runs, so wait until that transition is complete before disposal.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    nameController.dispose();
    variantController.dispose();
    stockController.dispose();
    priceController.dispose();
    categoryController.dispose();
    if (!mounted || saved == null) return;

    setState(() {
      if (isEditing) {
        final index = ProductStore.products.indexOf(product);
        if (index != -1) ProductStore.products[index] = saved;
      } else {
        ProductStore.products.add(saved);
      }
      _category = 'All';
      _stockFilter = _StockFilter.all;
    });
  }

  Widget _productField({
    required TextEditingController controller,
    required String label,
    bool numeric = false,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    validator: (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return 'Required';
      if (numeric &&
          (double.tryParse(text) == null || double.parse(text) < 0)) {
        return 'Enter a valid value';
      }
      return null;
    },
  );

  void _showStockFilter() => showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Filter', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final filter in _StockFilter.values)
            ListTile(
              title: Text(switch (filter) {
                _StockFilter.all => 'All products',
                _StockFilter.available => 'Available stock',
                _StockFilter.low => 'Low stock',
              }),
              trailing: _stockFilter == filter
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _stockFilter = filter);
                Navigator.pop(sheetContext);
              },
            ),
        ],
      ),
    ),
  );
}
