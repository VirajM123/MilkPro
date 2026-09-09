  import 'dart:convert';

  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:http/http.dart' as http;

  import '../../config/api_config.dart';
  import '../../theme/app_colors.dart';

  class SupplierScreen extends StatefulWidget {
    const SupplierScreen({super.key});

    @override
    State<SupplierScreen> createState() => _SupplierScreenState();
  }

  class _SupplierScreenState extends State<SupplierScreen> {
    final TextEditingController _searchController =
        TextEditingController();

    final List<SupplierItem> _suppliers = [];

    bool _loading = true;
    String _searchText = '';

    List<SupplierItem> get _filteredSuppliers {
      final query = _searchText.trim().toLowerCase();

      if (query.isEmpty) {
        return _suppliers;
      }

      return _suppliers.where((supplier) {
        return supplier.supplierName
                .toLowerCase()
                .contains(query) ||
            supplier.supplierId
                .toLowerCase()
                .contains(query) ||
            supplier.mobile.contains(query) ||
            supplier.gstNo
                .toLowerCase()
                .contains(query);
      }).toList();
    }

    int get _activeCount =>
        _suppliers.where((item) => item.isActive).length;

    int get _inactiveCount =>
        _suppliers.where((item) => !item.isActive).length;

    double get _openingBalance =>
        _suppliers.fold<double>(
          0,
          (sum, item) =>
              sum + item.openingBalance,
        );

    @override
    void initState() {
      super.initState();

      _loadSuppliers();
    }

    @override
    void dispose() {
      _searchController.dispose();

      super.dispose();
    }

    // ============================================================
    // LOAD SUPPLIERS
    // ============================================================

    Future<void> _loadSuppliers() async {
      if (mounted) {
        setState(() {
          _loading = true;
        });
      }

      try {
        final response = await http.get(
          Uri.parse(
            ApiConfig.suppliers,
          ),
          headers: {
            'Content-Type':
                'application/json',
            'Authorization':
                'Bearer ${ApiConfig.token}',
          },
        );

        final data =
            jsonDecode(response.body)
                as Map<String, dynamic>;

        if (!mounted) return;

        if (response.statusCode == 200 &&
            data['success'] == true) {
          final records =
              data['data']
                      as List<dynamic>? ??
                  [];

          final suppliers =
              records.map((item) {
            final map =
                item as Map<String, dynamic>;

            return SupplierItem(
              id:
                  map['_id']
                          ?.toString() ??
                      '',
              supplierId:
                  map['supplierId']
                          ?.toString() ??
                      '',
              supplierName:
                  map['supplierName']
                          ?.toString() ??
                      '',
              mobile:
                  map['mobile']
                          ?.toString() ??
                      '',
              email:
                  map['email']
                          ?.toString() ??
                      '',
              address:
                  map['address']
                          ?.toString() ??
                      '',
              gstNo:
                  map['gstNo']
                          ?.toString() ??
                      '',
              openingBalance:
                  double.tryParse(
                        map['openingBalance']
                                ?.toString() ??
                            '0',
                      ) ??
                      0,
              isActive:
                  map['isActive'] != false,
            );
          }).toList();

          setState(() {
            _suppliers
              ..clear()
              ..addAll(suppliers);
          });
        } else {
          _showMessage(
            data['message']?.toString() ??
                'Unable to load suppliers.',
          );
        }
      } catch (error) {
        if (!mounted) return;

        _showMessage(
          'Unable to load suppliers from server.',
        );
      } finally {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    }

    // ============================================================
    // ADD SUPPLIER
    // ============================================================

    Future<void> _showAddSupplierDialog() async {
      final result =
          await showDialog<SupplierItem>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const _SupplierFormDialog(),
      );

      if (result == null || !mounted) {
        return;
      }

      await _saveSupplier(result);
    }

    Future<void> _saveSupplier(
      SupplierItem supplier,
    ) async {
      try {
        final response = await http.post(
          Uri.parse(
            ApiConfig.suppliers,
          ),
          headers: {
            'Content-Type':
                'application/json',
            'Authorization':
                'Bearer ${ApiConfig.token}',
          },
          body: jsonEncode({
            'supplierName':
                supplier.supplierName,
            'mobile':
                supplier.mobile,
            'email':
                supplier.email,
            'address':
                supplier.address,
            'gstNo':
                supplier.gstNo,
            'openingBalance':
                supplier.openingBalance,
            'isActive':
                supplier.isActive,
          }),
        );

        final data =
            jsonDecode(response.body)
                as Map<String, dynamic>;

        if (!mounted) return;

        if ((response.statusCode == 200 ||
                response.statusCode == 201) &&
            data['success'] == true) {
          _showMessage(
            data['message']?.toString() ??
                'Supplier added successfully.',
          );

          await _loadSuppliers();
        } else {
          _showMessage(
            data['message']?.toString() ??
                'Unable to add supplier.',
          );
        }
      } catch (error) {
        if (!mounted) return;

        _showMessage(
          'Unable to connect to backend.',
        );
      }
    }

    // ============================================================
    // EDIT SUPPLIER
    // ============================================================

    Future<void> _showEditSupplierDialog(
      SupplierItem supplier,
    ) async {
      final result =
          await showDialog<SupplierItem>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            _SupplierFormDialog(
          supplier: supplier,
        ),
      );

      if (result == null || !mounted) {
        return;
      }

      await _updateSupplier(
        supplier,
        result,
      );
    }

    Future<void> _updateSupplier(
      SupplierItem oldSupplier,
      SupplierItem newSupplier,
    ) async {
      if (oldSupplier.id.isEmpty) {
        _showMessage(
          'Supplier database ID is missing.',
        );
        return;
      }

      try {
        final response = await http.put(
          Uri.parse(
            '${ApiConfig.suppliers}/${oldSupplier.id}',
          ),
          headers: {
            'Content-Type':
                'application/json',
            'Authorization':
                'Bearer ${ApiConfig.token}',
          },
          body: jsonEncode({
            'supplierName':
                newSupplier.supplierName,
            'mobile':
                newSupplier.mobile,
            'email':
                newSupplier.email,
            'address':
                newSupplier.address,
            'gstNo':
                newSupplier.gstNo,
            'openingBalance':
                newSupplier.openingBalance,
            'isActive':
                newSupplier.isActive,
          }),
        );

        final data =
            jsonDecode(response.body)
                as Map<String, dynamic>;

        if (!mounted) return;

        if (response.statusCode == 200 &&
            data['success'] == true) {
          _showMessage(
            data['message']?.toString() ??
                'Supplier updated successfully.',
          );

          await _loadSuppliers();
        } else {
          _showMessage(
            data['message']?.toString() ??
                'Unable to update supplier.',
          );
        }
      } catch (error) {
        if (!mounted) return;

        _showMessage(
          'Unable to update supplier.',
        );
      }
    }

// ============================================================
// DELETE SUPPLIER
// ============================================================

Future<void> _confirmDeleteSupplier(
  SupplierItem supplier,
) async {
  if (supplier.id.isEmpty) {
    _showMessage(
      'Supplier database ID is missing.',
    );
    return;
  }

  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Delete Supplier',
        ),
        content: Text(
          'Are you sure you want to delete '
          '"${supplier.supplierName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child: const Text(
              'Cancel',
            ),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.error,
              foregroundColor:
                  Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child: const Text(
              'Delete',
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

  await _deleteSupplier(supplier);
}

Future<void> _deleteSupplier(
  SupplierItem supplier,
) async {
  try {
    final response =
        await http.delete(
      Uri.parse(
        '${ApiConfig.suppliers}/${supplier.id}',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer ${ApiConfig.token}',
      },
    );

    final data =
        jsonDecode(response.body)
            as Map<String, dynamic>;

    if (!mounted) return;

    if (response.statusCode == 200 &&
        data['success'] == true) {
      _showMessage(
        data['message']?.toString() ??
            'Supplier deleted successfully.',
      );

      await _loadSuppliers();
    } else {
      _showMessage(
        data['message']?.toString() ??
            'Unable to delete supplier.',
      );
    }
  } catch (error) {
    if (!mounted) return;

    _showMessage(
      'Unable to delete supplier.',
    );
  }
}

    // ============================================================
    // MESSAGE
    // ============================================================

    void _showMessage(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
    }

    // ============================================================
    // BUILD
    // ============================================================

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor:
            AppColors.background,

        appBar: AppBar(
          backgroundColor:
              Colors.white,
          surfaceTintColor:
              Colors.transparent,
          elevation: 0,

          leading: IconButton(
            onPressed: () =>
                Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color:
                  AppColors.textPrimary,
            ),
          ),

          title: const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Suppliers',
                style: TextStyle(
                  color:
                      AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              Text(
                'Supplier & vendor master',
                style: TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          actions: [
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 12,
              ),
              child:
                  ElevatedButton.icon(
                onPressed:
                    _showAddSupplierDialog,

                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),

                label: const Text(
                  'Add',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),

        body: RefreshIndicator(
          onRefresh: _loadSuppliers,

          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding:
                const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              28,
            ),

            children: [
              _buildSummary(),

              const SizedBox(
                height: 14,
              ),

              _buildSearch(),

              const SizedBox(
                height: 14,
              ),

              if (_loading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 60,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (_filteredSuppliers
                  .isEmpty)
                _buildEmptyState()
              else
                ...List.generate(
                  _filteredSuppliers.length,
                  (index) {
                    return _buildSupplierCard(
                      _filteredSuppliers[
                          index],
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }

    // ============================================================
    // SUMMARY
    // ============================================================

    Widget _buildSummary() {
      return Row(
        children: [
          Expanded(
            child: _summaryCard(
              title:
                  'Total Suppliers',
              value:
                  '${_suppliers.length}',
              icon:
                  Icons.store_outlined,
              color:
                  AppColors.primary,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _summaryCard(
              title: 'Active',
              value:
                  '$_activeCount',
              icon:
                  Icons.check_circle_outline,
              color:
                  AppColors.success,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _summaryCard(
              title: 'Inactive',
              value:
                  '$_inactiveCount',
              icon:
                  Icons.pause_circle_outline,
              color:
                  AppColors.error,
            ),
          ),
        ],
      );
    }

    Widget _summaryCard({
      required String title,
      required String value,
      required IconData icon,
      required Color color,
    }) {
      return Container(
        height: 85,
        padding:
            const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),

            const SizedBox(height: 4),

            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            Text(
              title,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color:
                    AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // SEARCH
    // ============================================================

    Widget _buildSearch() {
      return TextField(
        controller:
            _searchController,

        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },

        decoration: InputDecoration(
          hintText:
              'Search supplier, mobile or GST...',

          prefixIcon:
              const Icon(
            Icons.search_rounded,
          ),

          suffixIcon:
              _searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(() {
                          _searchText = '';
                        });
                      },
                      icon:
                          const Icon(
                        Icons.close_rounded,
                      ),
                    ),

          filled: true,
          fillColor:
              Colors.white,

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              13,
            ),
            borderSide:
                const BorderSide(
              color:
                  AppColors.border,
            ),
          ),
        ),
      );
    }

    // ============================================================
    // CARD
    // ============================================================

    Widget _buildSupplierCard(
      SupplierItem supplier,
    ) {
      return Container(
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),

        padding:
            const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            15,
          ),

          border: Border.all(
            color: AppColors.border,
          ),
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Container(
              width: 46,
              height: 46,

              decoration:
                  BoxDecoration(
                color:
                    AppColors.surfaceBlue,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: const Icon(
                Icons
                    .local_shipping_outlined,
                color:
                    AppColors.primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          supplier
                              .supplierName,

                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .textPrimary,
                            fontSize: 13,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),

                      _statusChip(
                        supplier.isActive,
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 4),

                  Text(
                    supplier.supplierId,
                    style:
                        const TextStyle(
                      color:
                          AppColors.primary,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                      height: 7),

                  if (supplier
                      .mobile.isNotEmpty)
                    _detailRow(
                      Icons
                          .phone_outlined,
                      supplier.mobile,
                    ),

                  if (supplier
                      .address.isNotEmpty)
                    _detailRow(
                      Icons
                          .location_on_outlined,
                      supplier.address,
                    ),

                  if (supplier
                      .gstNo.isNotEmpty)
                    _detailRow(
                      Icons
                          .receipt_long_outlined,
                      'GST: ${supplier.gstNo}',
                    ),

                  const SizedBox(
                      height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Opening Balance: ₹${supplier.openingBalance.toStringAsFixed(2)}',
                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .textSecondary,
                            fontSize: 10,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),

               Row(
  mainAxisSize:
      MainAxisSize.min,
  children: [
    TextButton.icon(
      onPressed: () =>
          _showEditSupplierDialog(
        supplier,
      ),
      icon: const Icon(
        Icons.edit_outlined,
        size: 16,
      ),
      label: const Text(
        'Edit',
      ),
    ),

    IconButton(
      tooltip:
          'Delete Supplier',
      onPressed: () =>
          _confirmDeleteSupplier(
        supplier,
      ),
      icon: const Icon(
        Icons.delete_outline_rounded,
        size: 19,
        color: AppColors.error,
      ),
    ),
  ],
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

    Widget _detailRow(
      IconData icon,
      String text,
    ) {
      return Padding(
        padding:
            const EdgeInsets.only(
          bottom: 3,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  AppColors.textSecondary,
            ),

            const SizedBox(width: 5),

            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _statusChip(bool active) {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),

        decoration:
            BoxDecoration(
          color: active
              ? const Color(
                  0xFFECFDF3)
              : const Color(
                  0xFFFFF1F2),

          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),

        child: Text(
          active
              ? 'Active'
              : 'Inactive',

          style: TextStyle(
            color: active
                ? AppColors.success
                : AppColors.error,

            fontSize: 8,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      );
    }

    // ============================================================
    // EMPTY
    // ============================================================

    Widget _buildEmptyState() {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 50,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border: Border.all(
            color: AppColors.border,
          ),
        ),

        child: Column(
          children: [
            const Icon(
              Icons.store_outlined,
              size: 46,
              color:
                  AppColors.textSecondary,
            ),

            const SizedBox(height: 10),

            const Text(
              'No suppliers found',
              style: TextStyle(
                color:
                    AppColors.textPrimary,
                fontSize: 14,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Add your first supplier.',
              style: TextStyle(
                color:
                    AppColors.textSecondary,
                fontSize: 10,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed:
                  _showAddSupplierDialog,
              icon:
                  const Icon(
                Icons.add_rounded,
              ),
              label:
                  const Text(
                'Add Supplier',
              ),
            ),
          ],
        ),
      );
    }
  }

  // ============================================================
  // FORM DIALOG
  // ============================================================

  class _SupplierFormDialog
      extends StatefulWidget {
    final SupplierItem? supplier;

    const _SupplierFormDialog({
      this.supplier,
    });

    @override
    State<_SupplierFormDialog>
        createState() =>
            _SupplierFormDialogState();
  }

  class _SupplierFormDialogState
      extends State<_SupplierFormDialog> {
    late final
        TextEditingController
            _nameController;

    late final
        TextEditingController
            _mobileController;

    late final
        TextEditingController
            _emailController;

    late final
        TextEditingController
            _addressController;

    late final
        TextEditingController
            _gstController;

    late final
        TextEditingController
            _openingBalanceController;

    late bool _isActive;

    final _formKey =
        GlobalKey<FormState>();

    @override
    void initState() {
      super.initState();

      _nameController =
          TextEditingController(
        text:
            widget.supplier
                    ?.supplierName ??
                '',
      );

      _mobileController =
          TextEditingController(
        text:
            widget.supplier?.mobile ??
                '',
      );

      _emailController =
          TextEditingController(
        text:
            widget.supplier?.email ??
                '',
      );

      _addressController =
          TextEditingController(
        text:
            widget.supplier?.address ??
                '',
      );

      _gstController =
          TextEditingController(
        text:
            widget.supplier?.gstNo ??
                '',
      );

      _openingBalanceController =
          TextEditingController(
        text: widget.supplier
                ?.openingBalance
                .toStringAsFixed(2) ??
            '0',
      );

      _isActive =
          widget.supplier?.isActive ??
              true;
    }

    @override
    void dispose() {
      _nameController.dispose();
      _mobileController.dispose();
      _emailController.dispose();
      _addressController.dispose();
      _gstController.dispose();
      _openingBalanceController
          .dispose();

      super.dispose();
    }

    void _save() {
      if (!(_formKey.currentState
              ?.validate() ??
          false)) {
        return;
      }

      Navigator.of(context).pop(
        SupplierItem(
          id:
              widget.supplier?.id ??
                  '',

          supplierId:
              widget.supplier
                      ?.supplierId ??
                  '',

          supplierName:
              _nameController.text
                  .trim(),

          mobile:
              _mobileController.text
                  .trim(),

          email:
              _emailController.text
                  .trim(),

          address:
              _addressController.text
                  .trim(),

          gstNo:
              _gstController.text
                  .trim()
                  .toUpperCase(),

          openingBalance:
              double.tryParse(
                    _openingBalanceController
                        .text
                        .trim(),
                  ) ??
                  0,

          isActive:
              _isActive,
        ),
      );
    }

    @override
    Widget build(
        BuildContext context) {
      final isEdit =
          widget.supplier != null;

      return AlertDialog(
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,

        title: Text(
          isEdit
              ? 'Edit Supplier'
              : 'Add Supplier',
        ),

        content:
            SizedBox(
          width: 430,

          child:
              Form(
            key: _formKey,

            child:
                SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  _field(
                    controller:
                        _nameController,
                    label:
                        'Supplier Name *',
                    icon:
                        Icons.store_outlined,
                    validator: (value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Supplier name is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                      height: 12),

                  _field(
                    controller:
                        _mobileController,
                    label:
                        'Mobile Number',
                    icon:
                        Icons.phone_outlined,
                    keyboardType:
                        TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                      LengthLimitingTextInputFormatter(
                          10),
                    ],
                  ),

                  const SizedBox(
                      height: 12),

                  _field(
                    controller:
                        _emailController,
                    label: 'Email',
                    icon:
                        Icons.email_outlined,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                  ),

                  const SizedBox(
                      height: 12),

                  _field(
                    controller:
                        _addressController,
                    label: 'Address',
                    icon:
                        Icons
                            .location_on_outlined,
                  ),

                  const SizedBox(
                      height: 12),

                  _field(
                    controller:
                        _gstController,
                    label: 'GST No.',
                    icon:
                        Icons
                            .receipt_long_outlined,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                          15),
                    ],
                  ),

                  const SizedBox(
                      height: 12),

                  _field(
                    controller:
                        _openingBalanceController,
                    label:
                        'Opening Balance',
                    icon:
                        Icons
                            .currency_rupee_rounded,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                  ),

                  const SizedBox(
                      height: 6),

                  SwitchListTile(
                    contentPadding:
                        EdgeInsets.zero,

                    title:
                        const Text(
                      'Active Supplier',
                    ),

                    value:
                        _isActive,

                    activeThumbColor:
                        AppColors.primary,

                    onChanged: (value) {
                      setState(() {
                        _isActive =
                            value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .pop(),
            child:
                const Text(
              'Cancel',
            ),
          ),

          ElevatedButton(
            onPressed: _save,
            child: Text(
              isEdit
                  ? 'Update Supplier'
                  : 'Save Supplier',
            ),
          ),
        ],
      );
    }

    Widget _field({
      required
          TextEditingController
              controller,
      required String label,
      required IconData icon,
      TextInputType? keyboardType,
      List<TextInputFormatter>?
          inputFormatters,
      String? Function(String?)?
          validator,
    }) {
      return TextFormField(
        controller: controller,
        keyboardType:
            keyboardType,
        inputFormatters:
            inputFormatters,
        validator: validator,

        decoration:
            InputDecoration(
          labelText: label,

          prefixIcon:
              Icon(icon),

          filled: true,

          fillColor:
              const Color(
            0xFFF8FAFC,
          ),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              11,
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // SUPPLIER MODEL
  // ============================================================

  class SupplierItem {
    final String id;
    final String supplierId;
    final String supplierName;
    final String mobile;
    final String email;
    final String address;
    final String gstNo;
    final double openingBalance;
    final bool isActive;

    const SupplierItem({
      this.id = '',
      this.supplierId = '',
      required this.supplierName,
      this.mobile = '',
      this.email = '',
      this.address = '',
      this.gstNo = '',
      this.openingBalance = 0,
      this.isActive = true,
    });
  }