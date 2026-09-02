import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/access_models.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/customer_rate_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../common/access_denied_screen.dart';

class CustomerRatesScreen extends StatefulWidget {
  const CustomerRatesScreen({super.key});

  @override
  State<CustomerRatesScreen> createState() => _CustomerRatesScreenState();
}

class _CustomerRatesScreenState extends State<CustomerRatesScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, TextEditingController> _rateControllers = {};
  final Set<String> _dirtyProductKeys = {};
  CustomerModel? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    CustomerRateStore.syncCatalogue();
    if (CustomerStore.customers.isNotEmpty) {
      _selectedCustomer = CustomerStore.customers.first;
      _loadRateControllers();
    }
  }

  @override
  void dispose() {
    _disposeRateControllers();
    super.dispose();
  }

  void _disposeRateControllers() {
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    _rateControllers.clear();
  }

  void _loadRateControllers() {
    _dirtyProductKeys.clear();
    final customer = _selectedCustomer;
    if (customer == null) return;

    final previousControllers = _rateControllers;
    final nextControllers = <String, TextEditingController>{};
    for (final product in ProductStore.products) {
      final rate = CustomerRateStore.rateFor(customer, product);
      nextControllers[CustomerRateStore.productKey(
        product,
      )] = TextEditingController(
        text: rate.effectiveRate(product.price).toStringAsFixed(2),
      );
    }
    _rateControllers = nextControllers;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in previousControllers.values) {
        controller.dispose();
      }
    });
  }

  void _selectCustomer(CustomerModel? customer) {
    if (customer == null || identical(customer, _selectedCustomer)) return;
    setState(() {
      _selectedCustomer = customer;
      _loadRateControllers();
    });
  }

  void _markChanged(ProductModel product) {
    _dirtyProductKeys.add(CustomerRateStore.productKey(product));
  }

  void _saveRates() {
    final customer = _selectedCustomer;
    if (customer == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_dirtyProductKeys.isEmpty) {
      _showMessage('No rate changes to save.');
      return;
    }

    var savedCount = 0;
    for (final product in ProductStore.products) {
      final key = CustomerRateStore.productKey(product);
      if (!_dirtyProductKeys.contains(key)) continue;
      final rate = double.parse(_rateControllers[key]!.text.trim());
      CustomerRateStore.setCustomRate(customer, product, rate);
      savedCount++;
    }

    setState(_dirtyProductKeys.clear);
    _showMessage(
      '$savedCount custom rate${savedCount == 1 ? '' : 's'} saved for '
      '${customer.name}.',
      success: true,
    );
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (UiSession.instance.role != UserRole.admin) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _header(),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 580;
      return Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 8 : 18,
          12,
          compact ? 12 : 20,
          12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            SizedBox(width: compact ? 2 : 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Rates',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Set custom product rates for a selected customer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              key: const ValueKey('save-customer-rates'),
              onPressed: _selectedCustomer == null ? null : _saveRates,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: compact
                  ? const SizedBox.shrink()
                  : const Text('Save Rates'),
              style: compact
                  ? ElevatedButton.styleFrom(
                      minimumSize: const Size(48, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                    )
                  : null,
            ),
          ],
        ),
      );
    },
  );

  Widget _body() {
    if (CustomerStore.customers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 52,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 12),
              Text(
                'No customers available',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Add a customer before setting customer rates.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final customer = _selectedCustomer!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 760;
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(desktop ? 18 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _customerSelector(),
                const SizedBox(height: 18),
                _customerSummary(customer, desktop: desktop),
                const SizedBox(height: 20),
                if (desktop) _ratesTable(customer) else _mobileRateList(),
                const SizedBox(height: 16),
                _informationNote(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _customerSelector() => DropdownButtonFormField<CustomerModel>(
    initialValue: _selectedCustomer,
    decoration: InputDecoration(
      labelText: 'Select Customer',
      prefixIcon: const Icon(Icons.search_rounded),
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    ),
    isExpanded: true,
    items: CustomerStore.customers
        .map(
          (customer) => DropdownMenuItem<CustomerModel>(
            value: customer,
            child: Text(
              customer.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
        .toList(growable: false),
    onChanged: _selectCustomer,
  );

  Widget _customerSummary(CustomerModel customer, {required bool desktop}) {
    return Container(
      padding: EdgeInsets.all(desktop ? 22 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: desktop ? 82 : 62,
            width: desktop ? 82 : 62,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.manage_accounts_outlined,
              color: AppColors.primaryDeep,
              size: desktop ? 40 : 30,
            ),
          ),
          SizedBox(width: desktop ? 22 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      customer.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: desktop ? 19 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: customer.isActive
                            ? AppColors.successSoft
                            : AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        customer.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: customer.isActive
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 5,
                  children: [
                    Text(
                      customer.route,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      '•',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    Text(
                      customer.mobile,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratesTable(CustomerModel customer) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(66),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1.15),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: const TableBorder(
          horizontalInside: BorderSide(color: AppColors.divider),
          verticalInside: BorderSide(color: AppColors.divider),
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.surfaceBlue),
            children: [
              _tableHeader('#'),
              _tableHeader('Product Name'),
              _tableHeaderWithInfo('Current Rate'),
              _tableHeader(
                'Custom Rate for ${customer.name}\n(₹)',
                color: AppColors.primaryDark,
              ),
            ],
          ),
          for (var index = 0; index < ProductStore.products.length; index++)
            _productTableRow(ProductStore.products[index], index),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {Color color = AppColors.textPrimary}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _tableHeaderWithInfo(String text) => Container(
    constraints: const BoxConstraints(minHeight: 74),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 7),
        const Tooltip(
          message: 'Default product rate',
          child: Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  TableRow _productTableRow(ProductModel product, int index) {
    return TableRow(
      children: [
        _tableCell(
          Text(
            '${index + 1}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _tableCell(_productIdentity(product), alignment: Alignment.centerLeft),
        _tableCell(
          Text(
            '₹${product.price.toStringAsFixed(2)} / ${product.unit}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _tableCell(_rateField(product), horizontalPadding: 24),
      ],
    );
  }

  Widget _tableCell(
    Widget child, {
    Alignment alignment = Alignment.center,
    double horizontalPadding = 14,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 98),
    alignment: alignment,
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
    child: child,
  );

  Widget _productIdentity(ProductModel product) => Row(
    children: [
      Container(
        height: 54,
        width: 54,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Image.asset(
          product.assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.local_drink_outlined, color: AppColors.primary),
        ),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 4),
            Text(
              product.variant,
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
    ],
  );

  Widget _rateField(ProductModel product) {
    final key = CustomerRateStore.productKey(product);
    return TextFormField(
      key: ValueKey('customer-rate-$key'),
      controller: _rateControllers[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: (_) => _markChanged(product),
      decoration: const InputDecoration(
        prefixText: '₹  ',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      ),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      validator: (value) {
        final rate = double.tryParse(value?.trim() ?? '');
        return rate == null || rate <= 0 ? 'Enter valid rate' : null;
      },
    );
  }

  Widget _mobileRateList() => Column(
    children: [
      for (var index = 0; index < ProductStore.products.length; index++) ...[
        _mobileRateCard(ProductStore.products[index], index),
        if (index != ProductStore.products.length - 1)
          const SizedBox(height: 10),
      ],
    ],
  );

  Widget _mobileRateCard(ProductModel product, int index) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: _productIdentity(product)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT RATE',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '₹${product.price.toStringAsFixed(2)} / ${product.unit}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _rateField(product)),
          ],
        ),
      ],
    ),
  );

  Widget _informationNote() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.primaryBorder),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 19),
        SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(color: AppColors.primaryDark, fontSize: 12),
              children: [
                TextSpan(
                  text: 'Note: ',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text:
                      'Custom rates will override default rates for this customer.',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
