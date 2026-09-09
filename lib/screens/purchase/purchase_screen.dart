import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../theme/app_colors.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryBlue = AppColors.primary;
  static const Color darkBlue = AppColors.primaryDeep;
  static const Color textBlue = AppColors.textPrimary;
  static const Color borderColor = AppColors.border;
  static const Color fieldBackground = AppColors.surface;
  static const Color softBlue = AppColors.surfaceBlue;
  static const Color pageBackground = AppColors.background;
  static const Color green = AppColors.success;
  static const Color red = AppColors.error;
  static const TextStyle _purchaseHead = TextStyle(
    color: textBlue,
    fontSize: 9.5,
    fontWeight: FontWeight.w900,
  );

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isCreatingPurchase = false;

  // Purchase edit mode
  bool _isEditingPurchase = false;
  String? _editingPurchaseId;
  String? _editingPurchaseNo;

  final List<_PurchaseRecord> _savedPurchases = [];

  DateTime purchaseDate = DateTime(2026, 8, 20);
  DateTime billDate = DateTime(2026, 8, 20);
  DateTime dueDate = DateTime(2026, 8, 30);

  String? selectedSupplierId;
  String selectedPaymentType = 'Credit';
  String selectedGodown = 'Main Godown';

  final TextEditingController invoiceController = TextEditingController(
    text: 'INV-2548',
  );

  final TextEditingController remarksController = TextEditingController();

  final TextEditingController productSearchController = TextEditingController();

  String productQuery = '';

  final TextEditingController discountController = TextEditingController(
    text: '200',
  );

  final TextEditingController taxController = TextEditingController(text: '5');

  final List<_SupplierOption> suppliers = [];
  final List<_ProductOption> masterProducts = [];

  bool _loadingSuppliers = false;
  bool _loadingMasterProducts = false;
  bool _loadingPurchases = true;
  bool _savingPurchase = false;

  final List<String> paymentTypes = ['Credit', 'Cash', 'UPI', 'Bank Transfer'];

  final List<String> godowns = [
    'Main Godown',
    'Cold Storage',
    'Shop Godown',
    'Secondary Godown',
  ];

  // ============================================================
  // PRODUCTS
  // ============================================================

  final List<PurchaseProduct> products = [];

  // ============================================================
  // GETTERS
  // ============================================================

  double get totalQuantity {
    return products.fold(0, (sum, product) => sum + product.quantity);
  }

  double get subTotal {
    return products.fold(0, (sum, product) => sum + product.amount);
  }

  double get discount {
    return double.tryParse(discountController.text) ?? 0;
  }

  double get taxPercentage {
    return double.tryParse(taxController.text) ?? 0;
  }

  double get taxableAmount {
    final value = subTotal - discount;
    return value < 0 ? 0 : value;
  }

  double get taxAmount {
    return taxableAmount * taxPercentage / 100;
  }

  double get grandTotal {
    return taxableAmount + taxAmount;
  }

  List<PurchaseProduct> get visibleProducts {
    final query = productQuery.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query) ||
              product.description.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  // ============================================================
  // DATE
  // ============================================================

  String formatDate(DateTime date) {
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

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  Future<DateTime?> selectDate(
    BuildContext context,
    DateTime currentDate,
  ) async {
    return showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _loadSuppliers() async {
    if (mounted) {
      setState(() {
        _loadingSuppliers = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.suppliers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final records = data['data'] as List<dynamic>? ?? [];

        final loaded = records
            .where((item) {
              final map = item as Map<String, dynamic>;

              return map['isActive'] != false;
            })
            .map((item) {
              final map = item as Map<String, dynamic>;

              return _SupplierOption(
                id: map['_id']?.toString() ?? '',
                supplierId: map['supplierId']?.toString() ?? '',
                supplierName: map['supplierName']?.toString() ?? '',
              );
            })
            .where(
              (item) =>
                  item.supplierId.isNotEmpty && item.supplierName.isNotEmpty,
            )
            .toList();

        setState(() {
          suppliers
            ..clear()
            ..addAll(loaded);

          if (selectedSupplierId == null && suppliers.isNotEmpty) {
            selectedSupplierId = suppliers.first.supplierId;
          }
        });
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to load suppliers.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSuppliers = false;
        });
      }
    }
  }

  Future<void> _loadMasterProducts() async {
    if (mounted) {
      setState(() {
        _loadingMasterProducts = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.products),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final records = data['data'] as List<dynamic>? ?? [];

        final loaded = records
            .where((item) {
              final map = item as Map<String, dynamic>;

              return map['isActive'] != false;
            })
            .map((item) {
              final map = item as Map<String, dynamic>;

              return _ProductOption(
                id: map['_id']?.toString() ?? '',
                productId: map['productId']?.toString() ?? '',
                name: map['productName']?.toString() ?? '',
                variant: map['variant']?.toString() ?? '',
                unit: map['unit']?.toString() ?? 'Pcs',
                price: double.tryParse(map['price']?.toString() ?? '0') ?? 0,
              );
            })
            .where((item) => item.productId.isNotEmpty && item.name.isNotEmpty)
            .toList();

        setState(() {
          masterProducts
            ..clear()
            ..addAll(loaded);
        });
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to load products.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingMasterProducts = false;
        });
      }
    }
  }

  Future<void> _loadPurchases() async {
    if (mounted) {
      setState(() {
        _loadingPurchases = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.purchases),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final records = data['data'] as List<dynamic>? ?? [];

        final loaded = records.map((item) {
          final map = item as Map<String, dynamic>;

          final productLines = map['products'] as List<dynamic>? ?? [];

          final loadedProducts = productLines.map((item) {
            final productMap = item as Map<String, dynamic>;

            return PurchaseProduct(
              productId: productMap['productId']?.toString() ?? '',

              name: productMap['productName']?.toString() ?? '',

              description: productMap['variant']?.toString() ?? '',

              quantity:
                  double.tryParse(productMap['quantity']?.toString() ?? '0') ??
                  0,

              unit: productMap['unit']?.toString() ?? '',

              rate: double.tryParse(productMap['rate']?.toString() ?? '0') ?? 0,
            );
          }).toList();

          return _PurchaseRecord(
            id: map['_id']?.toString() ?? '',

            purchaseId: map['purchaseId']?.toString() ?? '',

            number: map['purchaseNo']?.toString() ?? '',

            date:
                DateTime.tryParse(map['purchaseDate']?.toString() ?? '') ??
                DateTime.now(),

            supplierId: map['supplierId']?.toString() ?? '',

            supplier: map['supplierName']?.toString() ?? '',

            invoice: map['invoiceNo']?.toString() ?? '',

            billDate:
                DateTime.tryParse(map['billDate']?.toString() ?? '') ??
                DateTime.now(),

            paymentType: map['paymentType']?.toString() ?? 'Credit',

            dueDate:
                DateTime.tryParse(map['dueDate']?.toString() ?? '') ??
                DateTime.now(),

            godown: map['godown']?.toString() ?? 'Main Godown',

            remarks: map['remarks']?.toString() ?? '',

            products: loadedProducts,

            itemCount: productLines.length,

            quantity:
                double.tryParse(map['totalQuantity']?.toString() ?? '0') ?? 0,

            subTotal: double.tryParse(map['subTotal']?.toString() ?? '0') ?? 0,

            discount: double.tryParse(map['discount']?.toString() ?? '0') ?? 0,

            taxPercentage:
                double.tryParse(map['taxPercentage']?.toString() ?? '0') ?? 0,

            taxAmount:
                double.tryParse(map['taxAmount']?.toString() ?? '0') ?? 0,

            amount: double.tryParse(map['grandTotal']?.toString() ?? '0') ?? 0,

            status: map['status']?.toString() ?? 'POSTED',
          );
        }).toList();

        setState(() {
          _savedPurchases
            ..clear()
            ..addAll(loaded);
        });
      } else {
        _showMessage(
          data['message']?.toString() ?? 'Unable to load purchases.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to load purchases.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingPurchases = false;
        });
      }
    }
  }
  // ============================================================
  // ADD PRODUCT
  // ============================================================

  Future<void> _showAddProductDialog() async {
    if (masterProducts.isEmpty) {
      await _loadMasterProducts();

      if (!mounted) return;

      if (masterProducts.isEmpty) {
        _showMessage('No active products found in Product Master.');
        return;
      }
    }

    String? selectedProductId;

    final quantityController = TextEditingController();

    final rateController = TextEditingController();

    final result = await showDialog<PurchaseProduct>(
      context: context,
      barrierDismissible: false,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _ProductOption? selectedProduct;

            if (selectedProductId != null) {
              for (final item in masterProducts) {
                if (item.productId == selectedProductId) {
                  selectedProduct = item;
                  break;
                }
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),

              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),

                padding: const EdgeInsets.all(22),

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          _smallIconBox(Icons.inventory_2_outlined),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Text(
                              'Add Product',
                              style: TextStyle(
                                color: darkBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Product',
                        style: TextStyle(
                          color: textBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        value: selectedProductId,

                        isExpanded: true,

                        decoration: InputDecoration(
                          hintText: 'Select Product',

                          prefixIcon: const Icon(
                            Icons.local_drink_outlined,
                            color: primaryBlue,
                          ),

                          filled: true,
                          fillColor: Colors.white,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),

                        items: masterProducts
                            .map(
                              (product) => DropdownMenuItem<String>(
                                value: product.productId,
                                child: Text(
                                  product.variant.isEmpty
                                      ? product.name
                                      : '${product.name} - ${product.variant}',
                                ),
                              ),
                            )
                            .toList(),

                        onChanged: (value) {
                          setDialogState(() {
                            selectedProductId = value;

                            _ProductOption? found;

                            for (final item in masterProducts) {
                              if (item.productId == value) {
                                found = item;
                                break;
                              }
                            }

                            if (found != null) {
                              rateController.text = found.price.toStringAsFixed(
                                2,
                              );
                            }
                          });
                        },
                      ),

                      if (selectedProduct != null) ...[
                        const SizedBox(height: 10),

                        Text(
                          '${selectedProduct.variant.isEmpty ? '' : '${selectedProduct.variant} • '}${selectedProduct.unit}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      _dialogTextField(
                        controller: quantityController,
                        label: 'Quantity',
                        hint: '0.00',
                        icon: Icons.numbers,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _dialogTextField(
                        controller: rateController,
                        label: 'Purchase Rate',
                        hint: '₹ 0.00',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 26),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (selectedProduct == null) {
                                  _showMessage('Please select a product.');
                                  return;
                                }

                                final qty =
                                    double.tryParse(
                                      quantityController.text.trim(),
                                    ) ??
                                    0;

                                final rate =
                                    double.tryParse(
                                      rateController.text.trim(),
                                    ) ??
                                    0;

                                if (qty <= 0 || rate < 0) {
                                  _showMessage(
                                    'Enter valid quantity and rate.',
                                  );

                                  return;
                                }

                                Navigator.pop(
                                  dialogContext,

                                  PurchaseProduct(
                                    productId: selectedProduct!.productId,

                                    name: selectedProduct.name,

                                    description: selectedProduct.variant,

                                    quantity: qty,

                                    unit: selectedProduct.unit,

                                    rate: rate,
                                  ),
                                );
                              },

                              icon: const Icon(Icons.add, color: Colors.white),

                              label: const Text('Add Product'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;

    if (result != null) {
      final alreadyAdded = products.any(
        (item) => item.productId == result.productId,
      );

      if (alreadyAdded) {
        _showMessage('Product already added. Edit its quantity instead.');
        return;
      }

      setState(() {
        products.add(result);
      });
    }
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textBlue,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: primaryBlue),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: primaryBlue, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void _resetPurchaseForm() {
  purchaseDate = DateTime.now();

  billDate = DateTime.now();

  dueDate =
      DateTime.now().add(
    const Duration(days: 10),
  );

  selectedSupplierId =
      suppliers.isNotEmpty
          ? suppliers.first.supplierId
          : null;

  selectedPaymentType =
      paymentTypes.first;

  selectedGodown =
      godowns.first;

  invoiceController.clear();

  remarksController.clear();

  discountController.text = '0';

  taxController.text = '5';

  productSearchController.clear();

  productQuery = '';

  products.clear();

  // Reset Edit Mode
  _isEditingPurchase = false;

  _editingPurchaseId = null;

  _editingPurchaseNo = null;
}

  void _clearPurchase() {
    setState(() {
      _resetPurchaseForm();
    });

    _showMessage('Purchase form cleared');
  }

  // ============================================================
  // SAVE
  // ============================================================

Future<void> _savePurchase() async {
  if (_savingPurchase) return;

  final formState = _formKey.currentState;

  if (formState == null || !formState.validate()) {
    return;
  }

  if (selectedSupplierId == null || selectedSupplierId!.isEmpty) {
    _showMessage('Please select supplier.');
    return;
  }

  if (products.isEmpty) {
    _showMessage('Please add at least one product.');
    return;
  }

  for (final product in products) {
    if (product.quantity <= 0) {
      _showMessage(
        'Product quantity must be greater than zero.',
      );
      return;
    }

    if (product.rate < 0) {
      _showMessage(
        'Invalid purchase rate.',
      );
      return;
    }
  }

  // Extra protection for edit mode.
  if (_isEditingPurchase &&
      (_editingPurchaseId == null ||
          _editingPurchaseId!.isEmpty)) {
    _showMessage(
      'Purchase ID is missing. Unable to update purchase.',
    );
    return;
  }

  setState(() {
    _savingPurchase = true;
  });

  try {
    // ============================================================
    // REQUEST BODY - SAME FOR CREATE AND EDIT
    // ============================================================

    final requestBody = jsonEncode({
      'purchaseDate': purchaseDate.toIso8601String(),
      'supplierId': selectedSupplierId,
      'invoiceNo': invoiceController.text.trim(),
      'billDate': billDate.toIso8601String(),
      'paymentType': selectedPaymentType,
      'dueDate': dueDate.toIso8601String(),
      'godown': selectedGodown,
      'remarks': remarksController.text.trim(),
      'products': products
          .map(
            (item) => item.toJson(),
          )
          .toList(),
      'discount': discount,
      'taxPercentage': taxPercentage,
    });

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${ApiConfig.token}',
    };

    late http.Response response;

    // ============================================================
    // CREATE OR EDIT PURCHASE
    // ============================================================

    if (_isEditingPurchase) {
      // EDIT EXISTING PURCHASE
      response = await http.put(
        Uri.parse(
          '${ApiConfig.purchases}/$_editingPurchaseId',
        ),
        headers: headers,
        body: requestBody,
      );
    } else {
      // CREATE NEW PURCHASE
      response = await http.post(
        Uri.parse(
          ApiConfig.purchases,
        ),
        headers: headers,
        body: requestBody,
      );
    }

    // ============================================================
    // PARSE RESPONSE
    // ============================================================

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {
      // Backend returned non-JSON response.
    }

    if (!mounted) return;

    // ============================================================
    // SUCCESS
    // ============================================================

    if ((response.statusCode == 200 ||
            response.statusCode == 201) &&
        data['success'] == true) {
      final wasEditing = _isEditingPurchase;

      _showMessage(
        data['message']?.toString() ??
            (wasEditing
                ? 'Purchase updated successfully.'
                : 'Purchase saved successfully.'),
      );

      // Reload purchase history.
      await _loadPurchases();

      // Reload stock/product master.
      await _loadMasterProducts();

      if (!mounted) return;

      setState(() {
        _resetPurchaseForm();
        _isCreatingPurchase = false;
      });

      return;
    }

    // ============================================================
    // BACKEND ERROR
    // ============================================================

    _showMessage(
      data['message']?.toString() ??
          (_isEditingPurchase
              ? 'Unable to update purchase.'
              : 'Unable to save purchase.'),
    );
  } catch (error) {
    if (!mounted) return;

    debugPrint(
      'PURCHASE SAVE/UPDATE ERROR: $error',
    );

    _showMessage(
      _isEditingPurchase
          ? 'Unable to update purchase. Please check backend connection.'
          : 'Unable to save purchase. Please check backend connection.',
    );
  } finally {
    if (mounted) {
      setState(() {
        _savingPurchase = false;
      });
    }
  }
}

  Future<void> _cancelPurchase(_PurchaseRecord purchase) async {
    if (purchase.id.isEmpty) {
      _showMessage('Purchase database ID is missing.');
      return;
    }

    if (purchase.isCancelled) {
      _showMessage('Purchase is already cancelled.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Purchase?'),

          content: Text(
            'Are you sure you want to delete ${purchase.number}?\n\n'
            'The purchase will be cancelled and its stock will be reversed automatically.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),

              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              child: const Text('Delete Purchase'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.purchases}/${purchase.id}/cancel'),

        headers: {
          'Content-Type': 'application/json',

          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        _showMessage(
          data['message']?.toString() ?? 'Purchase cancelled successfully.',
        );

        await _loadPurchases();

        await _loadMasterProducts();
      } else {
        _showMessage(
          data['message']?.toString() ?? 'Unable to cancel purchase.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to cancel purchase.');
    }
  }
  // ============================================================
  // MONEY
  // ============================================================

  String _money(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final value = parts[0];

    String result = '';

    if (value.length <= 3) {
      result = value;
    } else {
      final lastThree = value.substring(value.length - 3);
      var remaining = value.substring(0, value.length - 3);

      final groups = <String>[];

      while (remaining.length > 2) {
        groups.insert(0, remaining.substring(remaining.length - 2));

        remaining = remaining.substring(0, remaining.length - 2);
      }

      if (remaining.isNotEmpty) {
        groups.insert(0, remaining);
      }

      result = '${groups.join(',')},$lastThree';
    }

    return '$result.${parts[1]}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  void initState() {
    super.initState();

    purchaseDate = DateTime.now();
    billDate = DateTime.now();
    dueDate = DateTime.now().add(const Duration(days: 10));

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadSuppliers(),
      _loadMasterProducts(),
      _loadPurchases(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCreatingPurchase) return _buildPurchaseHistory();

    return _buildPurchaseForm();
  }

  Widget _buildPurchaseForm() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth > 900 ? 850.0 : screenWidth;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPurchaseEntryHeader(),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildReferencePurchaseDetails(),
                          _sectionDivider(),
                          _buildProductsSection(),
                          _buildReferencePurchaseSummary(),
                          _buildBottomButtons(),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseHistory() {
    final total = _savedPurchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.amount,
    );
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
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
              'My Purchases',
              style: TextStyle(
                color: textBlue,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'View all saved purchase entries',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: const <Widget>[
          IconButton(
            tooltip: 'Search purchases',
            onPressed: null,
            icon: Icon(Icons.search_rounded, color: textBlue, size: 28),
          ),
          IconButton(
            tooltip: 'Filter purchases',
            onPressed: null,
            icon: Icon(Icons.filter_alt_outlined, color: textBlue, size: 27),
          ),
          SizedBox(width: 9),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: <Widget>[
          Container(
            height: 104,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Total Purchases',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '₹${_money(total)}',
                        style: const TextStyle(
                          color: textBlue,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: softBlue,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: primaryBlue,
                    size: 29,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _purchaseFilter('All Purchases', Icons.list_alt_rounded, true),
              const SizedBox(width: 8),
              _purchaseFilter('Today', Icons.calendar_today_outlined, false),
              const SizedBox(width: 8),
              _purchaseFilter(
                'This Month',
                Icons.calendar_month_outlined,
                false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingPurchases)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_savedPurchases.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Center(child: Text('No purchases found.')),
            )
          else
            ..._savedPurchases.map(_buildSavedPurchaseCard),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: Colors.white,
            elevation: 5,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _openNewPurchase,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                child: Text(
                  'New Purchase',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'new-purchase',
            onPressed: _openNewPurchase,
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 33),
          ),
        ],
      ),
    );
  }

  Widget _purchaseFilter(String label, IconData icon, bool selected) {
    return Expanded(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? primaryBlue : borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: selected ? Colors.white : textBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildSavedPurchaseCard(
  _PurchaseRecord purchase,
) {
  return Container(
    margin: const EdgeInsets.only(
      bottom: 12,
    ),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      border: Border.all(
        color: borderColor,
      ),
    ),

    child: Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: <Widget>[
        // ========================================================
        // PURCHASE ICON
        // ========================================================

        Container(
          width: 48,
          height: 54,
          decoration: BoxDecoration(
            color: softBlue,
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons
                .shopping_cart_checkout_rounded,
            color: primaryBlue,
            size: 25,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ========================================================
        // PRODUCT / SUPPLIER / REFERENCE
        // ========================================================

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // PRODUCT NAME
              Text(
                purchase.displayProductName,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color: textBlue,
                  fontSize: 14,
                  height: 1.15,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              // SUPPLIER
              Text(
                purchase.supplier.isEmpty
                    ? 'Supplier not available'
                    : purchase.supplier,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              // DATE + INVOICE
              Text(
                '${formatDate(purchase.date)} • ${purchase.displayInvoice}',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                  fontSize: 9.5,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              // PURCHASE NUMBER AS SMALL REFERENCE
              Text(
                purchase.number,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // VIEW / EDIT / DELETE
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      _viewPurchase(
                        purchase,
                      );
                    },
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    child:
                        const Padding(
                      padding:
                          EdgeInsets.all(
                        5,
                      ),
                      child: Icon(
                        Icons
                            .visibility_outlined,
                        color:
                            primaryBlue,
                        size: 19,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  if (!purchase
                      .isCancelled)
                    InkWell(
                      onTap: () {
                        _editPurchase(
                          purchase,
                        );
                      },
                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),
                      child:
                          const Padding(
                        padding:
                            EdgeInsets.all(
                          5,
                        ),
                        child: Icon(
                          Icons
                              .edit_outlined,
                          color:
                              AppColors
                                  .primary,
                          size: 19,
                        ),
                      ),
                    ),

                  if (!purchase
                      .isCancelled)
                    const SizedBox(
                      width: 8,
                    ),

                  if (!purchase
                      .isCancelled)
                    InkWell(
                      onTap: () {
                        _cancelPurchase(
                          purchase,
                        );
                      },
                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),
                      child:
                          const Padding(
                        padding:
                            EdgeInsets.all(
                          5,
                        ),
                        child: Icon(
                          Icons
                              .delete_outline_rounded,
                          color:
                              AppColors
                                  .error,
                          size: 19,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        // ========================================================
        // RIGHT SIDE
        // ========================================================

        SizedBox(
          width: 92,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [
              // STATUS
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration:
                    BoxDecoration(
                  color: purchase
                          .isCancelled
                      ? const Color(
                          0xFFFFF1F2,
                        )
                      : AppColors
                          .successSoft,
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
                child: Text(
                  purchase.isCancelled
                      ? 'Cancelled'
                      : 'Posted',
                  style: TextStyle(
                    color: purchase
                            .isCancelled
                        ? AppColors.error
                        : AppColors
                            .success,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(
                height: 9,
              ),

              // AMOUNT
              Text(
                '₹${_money(purchase.amount)}',
                textAlign:
                    TextAlign.right,
                maxLines: 1,
                style:
                    const TextStyle(
                  color: textBlue,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              // ITEMS
              Text(
                '${purchase.itemCount} ${purchase.itemCount == 1 ? 'Item' : 'Items'}',
                textAlign:
                    TextAlign.right,
                style:
                    const TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              // QUANTITY
              Text(
                '${purchase.quantity.toStringAsFixed(0)} Pcs',
                textAlign:
                    TextAlign.right,
                style:
                    const TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Future<void> _viewPurchase(_PurchaseRecord purchase) async {
    await showDialog<void>(
      context: context,

      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750, maxHeight: 750),

            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Purchase Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textBlue,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const Divider(),

                  const SizedBox(height: 10),

                  _viewDetailRow('Purchase No.', purchase.number),

                  _viewDetailRow('Purchase Date', formatDate(purchase.date)),

                  _viewDetailRow('Supplier', purchase.supplier),

                  _viewDetailRow('Invoice No.', purchase.invoice),

                  _viewDetailRow('Bill Date', formatDate(purchase.billDate)),

                  _viewDetailRow('Payment Type', purchase.paymentType),

                  _viewDetailRow('Due Date', formatDate(purchase.dueDate)),

                  _viewDetailRow('Godown', purchase.godown),

                  _viewDetailRow('Status', purchase.status),

                  if (purchase.remarks.isNotEmpty)
                    _viewDetailRow('Remarks', purchase.remarks),

                  const SizedBox(height: 20),

                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textBlue,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...purchase.products.asMap().entries.map((entry) {
                    final index = entry.key;

                    final product = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),

                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),

                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Row(
                        children: [
                          SizedBox(width: 30, child: Text('${index + 1}')),

                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                if (product.description.isNotEmpty)
                                  Text(
                                    product.description,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: Text(
                              '${product.quantity} ${product.unit}',
                              textAlign: TextAlign.center,
                            ),
                          ),

                          Expanded(
                            child: Text(
                              '₹${_money(product.rate)}',
                              textAlign: TextAlign.right,
                            ),
                          ),

                          Expanded(
                            child: Text(
                              '₹${_money(product.amount)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 30),

                  _viewDetailRow(
                    'Total Quantity',
                    purchase.quantity.toStringAsFixed(2),
                  ),

                  _viewDetailRow('Subtotal', '₹${_money(purchase.subTotal)}'),

                  _viewDetailRow('Discount', '₹${_money(purchase.discount)}'),

                  _viewDetailRow(
                    'Tax',
                    '${purchase.taxPercentage.toStringAsFixed(2)}%',
                  ),

                  _viewDetailRow(
                    'Tax Amount',
                    '₹${_money(purchase.taxAmount)}',
                  ),

                  const Divider(),

                  _viewDetailRow(
                    'Grand Total',
                    '₹${_money(purchase.amount)}',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _viewDetailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textBlue,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editPurchase(_PurchaseRecord purchase) {
    if (purchase.isCancelled) {
      _showMessage('Cancelled purchase cannot be edited.');
      return;
    }

    setState(() {
      _isEditingPurchase = true;

      _editingPurchaseId = purchase.id;

      _editingPurchaseNo = purchase.number;

      purchaseDate = purchase.date;

      billDate = purchase.billDate;

      dueDate = purchase.dueDate;

      selectedSupplierId = purchase.supplierId;

      selectedPaymentType = paymentTypes.contains(purchase.paymentType)
          ? purchase.paymentType
          : paymentTypes.first;

      selectedGodown = godowns.contains(purchase.godown)
          ? purchase.godown
          : godowns.first;

      invoiceController.text = purchase.invoice;

      remarksController.text = purchase.remarks;

      discountController.text = purchase.discount.toStringAsFixed(2);

      taxController.text = purchase.taxPercentage.toStringAsFixed(2);

      products
        ..clear()
        ..addAll(
          purchase.products.map(
            (item) => PurchaseProduct(
              productId: item.productId,

              name: item.name,

              description: item.description,

              quantity: item.quantity,

              unit: item.unit,

              rate: item.rate,
            ),
          ),
        );

      productSearchController.clear();

      productQuery = '';

      _isCreatingPurchase = true;
    });
  }

  void _openNewPurchase() {
    setState(() {
      _isEditingPurchase = false;

      _editingPurchaseId = null;

      _editingPurchaseNo = null;

      _resetPurchaseForm();

      _isCreatingPurchase = true;
    });
  }

  // ============================================================
  // HEADER
  // ============================================================

Widget _buildPurchaseEntryHeader() {
  return Container(
    height: 156,
    width: double.infinity,
    padding:
        const EdgeInsets.fromLTRB(
      18,
      38,
      20,
      16,
    ),
    decoration:
        const BoxDecoration(
      gradient: LinearGradient(
        colors: <Color>[
          Color(0xFF2564DE),
          Color(0xFF1685F6),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    ),
    child: Row(
      children: <Widget>[
        IconButton(
          tooltip: 'Back to purchases',
          onPressed: () {
            setState(() {
              _resetPurchaseForm();
              _isCreatingPurchase = false;
            });
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _isEditingPurchase
                    ? 'Edit Purchase'
                    : 'Purchase',
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              if (_isEditingPurchase)
                Text(
                  _editingPurchaseNo !=
                              null &&
                          _editingPurchaseNo!
                              .isNotEmpty
                      ? 'Update purchase • $_editingPurchaseNo'
                      : 'Update purchase entry',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                )
              else
                const Text(
                  'Create new purchase entry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        Stack(
          clipBehavior:
              Clip.none,
          children: <Widget>[
            const Icon(
              Icons
                  .notifications_none_rounded,
              color: Colors.white,
              size: 30,
            ),

            Positioned(
              right: -6,
              top: -8,
              child: Container(
                width: 22,
                height: 22,
                alignment:
                    Alignment.center,
                decoration:
                    const BoxDecoration(
                  color:
                      AppColors.error,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Text(
                  '3',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900,
                  ),
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
  Widget _buildHeader() {
    return Container(
      height: 235,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2463DF), Color(0xFF1681F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: 30,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            right: 55,
            top: 62,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            right: 30,
            bottom: 35,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _milkBottle(42, 110),
                const SizedBox(width: 5),
                _milkBottle(34, 86),
                const SizedBox(width: 7),
                _milkBottle(48, 132),
                const SizedBox(width: 8),
                Container(
                  width: 66,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Text(
                    'MILK',
                    style: TextStyle(
                      color: Color(0xFF2494EE),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 22,
            right: 22,
            top: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() => _isCreatingPurchase = false);
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(width: 17),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Create new purchase entry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                    Positioned(
                      right: -7,
                      top: -10,
                      child: Container(
                        height: 25,
                        width: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4136),
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _milkBottle(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(width * .25),
          topRight: Radius.circular(width * .25),
          bottomLeft: Radius.circular(width * .13),
          bottomRight: Radius.circular(width * .13),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .30)),
      ),
    );
  }

  // ============================================================
  // PURCHASE DETAILS
  // ============================================================

  Widget _buildReferencePurchaseDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: <Widget>[
            Expanded(
  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: <Widget>[
      const Text(
        'Purchase No.',
        style: TextStyle(
          color: textBlue,
          fontSize: 11,
        ),
      ),

      const SizedBox(
        height: 5,
      ),

      Text(
        _isEditingPurchase
            ? (_editingPurchaseNo ??
                '')
            : 'Auto Generated',

        style:
            const TextStyle(
          color: primaryBlue,
          fontSize: 15,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    ],
  ),
),
                Container(width: 1, height: 42, color: borderColor),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final value = await selectDate(context, purchaseDate);
                      if (value != null) setState(() => purchaseDate = value);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Entry Date',
                          style: TextStyle(color: textBlue, fontSize: 11),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: primaryBlue,
                              size: 19,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                formatDate(purchaseDate),
                                maxLines: 1,
                                style: const TextStyle(
                                  color: darkBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _supplierField()),
              const SizedBox(width: 10),
              Expanded(child: _invoiceField()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _billDateField()),
              const SizedBox(width: 8),
              Expanded(child: _paymentTypeField()),
              const SizedBox(width: 8),
              Expanded(child: _dueDateField()),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPurchaseDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 26),
      child: Column(
        children: [
          Row(
            children: [
              _sectionIcon(Icons.calendar_month_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Purchase Details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Purchase No.  PUR-2026-0012',
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          if (MediaQuery.sizeOf(context).width < 700)
            Column(
              children: [
                _purchaseDateField(),
                const SizedBox(height: 17),
                _supplierField(),
                const SizedBox(height: 17),
                _invoiceField(),
                const SizedBox(height: 17),
                _billDateField(),
                const SizedBox(height: 17),
                _paymentTypeField(),
                const SizedBox(height: 17),
                _dueDateField(),
                const SizedBox(height: 17),
                _godownField(),
                const SizedBox(height: 17),
                _remarksField(),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _purchaseDateField()),
                    const SizedBox(width: 30),
                    Expanded(child: _supplierField()),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: _invoiceField()),
                    const SizedBox(width: 30),
                    Expanded(child: _billDateField()),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: _paymentTypeField()),
                    const SizedBox(width: 30),
                    Expanded(child: _dueDateField()),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: _godownField()),
                    const SizedBox(width: 30),
                    Expanded(child: _remarksField()),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _purchaseDateField() {
    return _fieldContainer(
      label: 'Purchase Date',
      icon: Icons.calendar_month_outlined,
      value: formatDate(purchaseDate),
      trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: textBlue),
      onTap: () async {
        final value = await selectDate(context, purchaseDate);

        if (value != null) {
          setState(() {
            purchaseDate = value;
          });
        }
      },
    );
  }

  Widget _supplierField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supplier / Vendor',
          style: TextStyle(
            color: textBlue,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: 58,
          decoration: BoxDecoration(
            color: fieldBackground,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const SizedBox(width: 11),

              _fieldIcon(Icons.person_outline),

              const SizedBox(width: 10),

              Expanded(
                child: _loadingSuppliers
                    ? const Center(child: LinearProgressIndicator())
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              suppliers.any(
                                (item) => item.supplierId == selectedSupplierId,
                              )
                              ? selectedSupplierId
                              : null,

                          hint: const Text('Select Supplier'),

                          isExpanded: true,

                          items: suppliers
                              .map(
                                (supplier) => DropdownMenuItem<String>(
                                  value: supplier.supplierId,
                                  child: Text(
                                    supplier.supplierName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),

                          onChanged: suppliers.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedSupplierId = value;
                                  });
                                },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _invoiceField() {
    return _inputField(
      label: 'Bill / Invoice No.',
      icon: Icons.description_outlined,
      controller: invoiceController,
      hint: 'Enter invoice number',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Invoice number is required';
        }
        return null;
      },
    );
  }

  Widget _billDateField() {
    return _fieldContainer(
      label: 'Bill Date',
      icon: Icons.calendar_month_outlined,
      value: formatDate(billDate),
      onTap: () async {
        final value = await selectDate(context, billDate);

        if (value != null) {
          setState(() {
            billDate = value;
          });
        }
      },
    );
  }

  Widget _paymentTypeField() {
    return _dropdownField(
      label: 'Payment Type',
      icon: Icons.credit_card_outlined,
      value: selectedPaymentType,
      items: paymentTypes,
      onChanged: (value) {
        setState(() {
          selectedPaymentType = value!;
        });
      },
    );
  }

  Widget _dueDateField() {
    return _fieldContainer(
      label: 'Due Date',
      icon: Icons.calendar_month_outlined,
      value: formatDate(dueDate),
      onTap: () async {
        final value = await selectDate(context, dueDate);

        if (value != null) {
          setState(() {
            dueDate = value;
          });
        }
      },
    );
  }

  Widget _godownField() {
    return _dropdownField(
      label: 'Godown',
      icon: Icons.home_work_outlined,
      value: selectedGodown,
      items: godowns,
      onChanged: (value) {
        setState(() {
          selectedGodown = value!;
        });
      },
    );
  }

  Widget _remarksField() {
    return _inputField(
      label: 'Remarks (Optional)',
      icon: Icons.sticky_note_2_outlined,
      controller: remarksController,
      hint: 'Enter remarks',
    );
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  Widget _buildProductsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Column(
        children: [
          Row(
            children: [
              _sectionIcon(Icons.inventory_2_outlined),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'Products',
                  style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 21),
                label: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('purchaseProductSearch'),
            controller: productSearchController,
            onChanged: (value) => setState(() => productQuery = value),
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: productQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        productSearchController.clear();
                        setState(() => productQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: softBlue,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            _emptyProducts()
          else if (visibleProducts.isEmpty)
            _emptySearchResults()
          else if (MediaQuery.sizeOf(context).width < 700)
            _buildCompactPurchaseTable()
          else
            Column(
              children: [
                _buildProductTableHeader(),
                const SizedBox(height: 9),
                ...List.generate(
                  visibleProducts.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildProductRow(
                      visibleProducts[index],
                      products.indexOf(visibleProducts[index]),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompactPurchaseTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F5FD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(flex: 4, child: Text('Product', style: _purchaseHead)),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: _purchaseHead,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Rate',
                    textAlign: TextAlign.center,
                    style: _purchaseHead,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.right,
                    style: _purchaseHead,
                  ),
                ),
                SizedBox(width: 28),
              ],
            ),
          ),
          ...List<Widget>.generate(visibleProducts.length, (visibleIndex) {
            final product = visibleProducts[visibleIndex];
            final index = products.indexOf(product);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 27,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: softBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${visibleIndex + 1}',
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkBlue,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          product.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: ValueKey('purchaseQty-${product.name}'),
                      initialValue: product.quantity.toStringAsFixed(0),
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 7,
                        ),
                      ),
                      onChanged: (value) {
                        final quantity = double.tryParse(value);
                        if (quantity != null) {
                          setState(() => product.quantity = quantity);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      product.rate.toStringAsFixed(0),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _money(product.amount),
                        style: const TextStyle(
                          color: darkBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => products.removeAt(index)),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: red,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: _remarksField(),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMobileProductCard(PurchaseProduct product, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8295B6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete product',
                onPressed: () {
                  setState(() {
                    products.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline_rounded, color: red),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _mobileNumberField(
                  label: 'Quantity',
                  initialValue: product.quantity,
                  suffix: product.unit,
                  onChanged: (value) {
                    setState(() {
                      product.quantity = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _mobileNumberField(
                  label: 'Rate',
                  initialValue: product.rate,
                  prefix: '₹',
                  onChanged: (value) {
                    setState(() {
                      product.rate = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  'Amount',
                  style: TextStyle(
                    color: textBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹ ${_money(product.amount)}',
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileNumberField({
    required String label,
    required double initialValue,
    required ValueChanged<double> onChanged,
    String? prefix,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textBlue,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue.toStringAsFixed(2),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            prefixText: prefix == null ? null : '$prefix ',
            suffixText: suffix,
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: primaryBlue, width: 1.2),
            ),
          ),
          onChanged: (value) {
            final number = double.tryParse(value);
            if (number != null) {
              onChanged(number);
            }
          },
        ),
      ],
    );
  }

  Widget _buildProductTableHeader() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 54,
            child: Center(
              child: Text(
                '#',
                style: TextStyle(color: textBlue, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 24,
            child: Text(
              'Product',
              style: TextStyle(
                color: textBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Qty',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 17,
            child: Text(
              'Rate (₹)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'Amount (₹)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 55),
        ],
      ),
    );
  }

  Widget _buildProductRow(PurchaseProduct product, int index) {
    return SizedBox(
      height: 78,
      child: Row(
        children: [
          _productCell(
            width: 54,
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: darkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            flex: 24,
            child: _productCell(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        product.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8295B6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            flex: 22,
            child: _editableNumberCell(
              initialValue: product.quantity,
              suffix: product.unit,
              onChanged: (value) {
                setState(() {
                  product.quantity = value;
                });
              },
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            flex: 17,
            child: _editableNumberCell(
              initialValue: product.rate,
              onChanged: (value) {
                setState(() {
                  product.rate = value;
                });
              },
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            flex: 20,
            child: _productCell(
              child: Center(
                child: Text(
                  _money(product.amount),
                  style: const TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 7),

          _productCell(
            width: 55,
            child: IconButton(
              tooltip: 'Delete product',
              onPressed: () {
                setState(() {
                  products.removeAt(index);
                });
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: red,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableNumberCell({
    required double initialValue,
    required ValueChanged<double> onChanged,
    String? suffix,
  }) {
    final controller = TextEditingController(
      text: initialValue.toStringAsFixed(2),
    );

    return _productCell(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: const TextStyle(
                color: darkBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                final number = double.tryParse(value);

                if (number != null) {
                  onChanged(number);
                }
              },
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 9),
              child: Text(
                suffix,
                style: const TextStyle(color: Color(0xFF91A3C1), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productCell({required Widget child, double? width}) {
    return Container(
      width: width,
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .018),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF8AA7D3)),
          SizedBox(height: 10),
          Text(
            'No products added',
            style: TextStyle(color: textBlue, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 5),
          Text(
            'Tap Add Product to add purchase items.',
            style: TextStyle(color: Color(0xFF8295B6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _emptySearchResults() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    decoration: BoxDecoration(
      color: softBlue,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Column(
      children: [
        Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF8AA7D3)),
        SizedBox(height: 8),
        Text(
          'No matching products',
          style: TextStyle(color: darkBlue, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  // ============================================================
  // PURCHASE SUMMARY
  // ============================================================

  Widget _buildReferencePurchaseSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF4F8FF), Color(0xFFE8F1FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.calculate_outlined, color: primaryBlue, size: 25),
              SizedBox(width: 10),
              Text(
                'Purchase Summary',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _compactSummaryValue('Total Items', '${products.length}'),
              _compactSummaryDivider(),
              _compactSummaryValue(
                'Total Quantity',
                '${totalQuantity.toStringAsFixed(0)} Pcs',
              ),
              _compactSummaryDivider(),
              _compactSummaryValue('Sub Total', '₹${_money(subTotal)}'),
              _compactSummaryDivider(),
              _compactSummaryValue(
                'Total Amount',
                '₹${_money(grandTotal)}',
                primary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactSummaryValue(
    String label,
    String value, {
    bool primary = false,
  }) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: textBlue, fontSize: 8.5),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: primary ? primaryBlue : darkBlue,
                fontSize: primary ? 15 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactSummaryDivider() {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.primaryBorder,
    );
  }

  // ignore: unused_element
  Widget _buildPurchaseSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 3, 24, 25),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _sectionIcon(Icons.stacked_bar_chart_rounded),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'Purchase Summary',
                  style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (MediaQuery.sizeOf(context).width < 700)
            _summaryValues()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 130,
                    margin: const EdgeInsets.only(right: 25),
                    decoration: BoxDecoration(
                      color: softBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 55,
                        color: Color(0xFF93ADD2),
                      ),
                    ),
                  ),
                ),
                Expanded(flex: 7, child: _summaryValues()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _summaryValues() {
    return Column(
      children: [
        _summaryRow(
          title: 'Total Quantity',
          value: '${totalQuantity.toStringAsFixed(2)} Ltr',
        ),

        const SizedBox(height: 14),

        _summaryRow(title: 'Sub Total', value: '₹ ${_money(subTotal)}'),

        const SizedBox(height: 14),

        _editableSummaryRow(
          title: 'Discount',
          controller: discountController,
          prefix: '₹',
          textColor: green,
        ),

        const SizedBox(height: 14),

        _taxSummaryRow(),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: borderColor, height: 1),
        ),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Grand Total',
                style: TextStyle(
                  color: textBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '₹ ${_money(grandTotal)}',
              style: const TextStyle(
                color: primaryBlue,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow({required String title, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: textBlue, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: textBlue,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _editableSummaryRow({
    required String title,
    required TextEditingController controller,
    required String prefix,
    Color textColor = textBlue,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: textBlue, fontSize: 13),
          ),
        ),
        SizedBox(
          width: 130,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '$prefix ',
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              prefixStyle: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _taxSummaryRow() {
    return Row(
      children: [
        const Text(
          'Tax (GST ',
          style: TextStyle(color: textBlue, fontSize: 13),
        ),
        SizedBox(
          width: 32,
          child: TextField(
            controller: taxController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(color: textBlue, fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
        ),
        const Text('%)', style: TextStyle(color: textBlue, fontSize: 13)),
        const Spacer(),
        Text(
          '₹ ${_money(taxAmount)}',
          style: const TextStyle(
            color: textBlue,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 58,
              child: OutlinedButton.icon(
                onPressed: _clearPurchase,
                icon: const Icon(Icons.delete_outline_rounded, color: red),
                label: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: red,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: borderColor, width: 1.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: _savingPurchase ? null : _savePurchase,
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                ),
             label: Text(
  _savingPurchase
      ? (_isEditingPurchase
          ? 'Updating...'
          : 'Saving...')
      : (_isEditingPurchase
          ? 'Update Purchase'
          : 'Save Purchase'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
  // REUSABLE FORM WIDGETS
  // ============================================================

  Widget _fieldContainer({
    required String label,
    required IconData icon,
    required String value,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textBlue,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: fieldBackground,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const SizedBox(width: 11),
                _fieldIcon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: darkBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) ...[trailing, const SizedBox(width: 14)],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textBlue,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: fieldBackground,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const SizedBox(width: 11),
              _fieldIcon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textBlue,
                      ),
                    ),
                    style: const TextStyle(
                      color: darkBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    items: items
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textBlue,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFA5B2C9),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: _fieldIcon(icon),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 55,
              minHeight: 55,
            ),
            filled: true,
            fillColor: fieldBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: primaryBlue, width: 1.3),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldIcon(IconData icon) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: primaryBlue, size: 20),
    );
  }

  Widget _sectionIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF73A2FF), Color(0xFF2167E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 23),
    );
  }

  Widget _smallIconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: primaryBlue, size: 21),
    );
  }

  Widget _sectionDivider() {
    return Container(height: 1, color: const Color(0xFFE9EFF8));
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    invoiceController.dispose();
    remarksController.dispose();
    productSearchController.dispose();
    discountController.dispose();
    taxController.dispose();
    super.dispose();
  }
}

// ============================================================
// PURCHASE PRODUCT MODEL
// ============================================================

class PurchaseProduct {
  String productId;
  String name;
  String description;
  double quantity;
  String unit;
  double rate;

  PurchaseProduct({
    required this.productId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
  });

  double get amount => quantity * rate;

  Map<String, dynamic> toJson() {
    return {'productId': productId, 'quantity': quantity, 'rate': rate};
  }
}

class _PurchaseRecord {
  const _PurchaseRecord({
    required this.id,
    required this.purchaseId,
    required this.number,
    required this.date,
    required this.supplierId,
    required this.supplier,
    required this.invoice,
    required this.billDate,
    required this.paymentType,
    required this.dueDate,
    required this.godown,
    required this.remarks,
    required this.products,
    required this.itemCount,
    required this.quantity,
    required this.subTotal,
    required this.discount,
    required this.taxPercentage,
    required this.taxAmount,
    required this.amount,
    required this.status,
  });

  final String id;
  final String purchaseId;
  final String number;

  final DateTime date;

  final String supplierId;
  final String supplier;

  final String invoice;

  final DateTime billDate;

  final String paymentType;

  final DateTime dueDate;

  final String godown;

  final String remarks;

  final List<PurchaseProduct> products;

  final int itemCount;

  final double quantity;

  final double subTotal;

  final double discount;

  final double taxPercentage;

  final double taxAmount;

  final double amount;

  final String status;
  

  String get displayProductName {
  if (products.isEmpty) {
    return 'Purchase';
  }

  final firstProductName = products.first.name.trim();

  if (products.length == 1) {
    return firstProductName.isEmpty
        ? 'Product'
        : firstProductName;
  }

  final remainingProducts = products.length - 1;

  return '${firstProductName.isEmpty ? 'Product' : firstProductName} + $remainingProducts more';
}

String get displayInvoice {
  if (invoice.trim().isNotEmpty) {
    return invoice.trim();
  }

  return number;
}

bool get isCancelled =>
    status.toUpperCase() == 'CANCELLED';
}

class _SupplierOption {
  const _SupplierOption({
    required this.id,
    required this.supplierId,
    required this.supplierName,
  });

  final String id;
  final String supplierId;
  final String supplierName;
}

class _ProductOption {
  const _ProductOption({
    required this.id,
    required this.productId,
    required this.name,
    required this.variant,
    required this.unit,
    required this.price,
  });

  final String id;
  final String productId;
  final String name;
  final String variant;
  final String unit;
  final double price;
}
