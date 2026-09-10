import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../common/simple_screen_widgets.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  String _query = '';

  bool? _activeOnly;

  bool _loadingCustomers = true;

  List<CustomerModel> _customerList = [];
  List<String> _routeList = [];

  bool _loadingRoutes = false;

  // ============================================================
  // CURRENT CUSTOMER OUTSTANDING
  //
  // customer.balance = opening/master balance
  // This map = live ledger balance
  // ============================================================

  final Map<String, double> _currentBalances = <String, double>{};

  bool _loadingBalances = false;

  static const _avatarColors = <Color>[
    Color(0xFFE8F1FF),
    Color(0xFFE5F8EB),
    Color(0xFFF1E7FF),
    Color(0xFFFFF0E5),
  ];
  static const _avatarTextColors = <Color>[
    AppColors.primary,
    AppColors.success,
    AppColors.purple,
    AppColors.warning,
  ];

  List<CustomerModel> get _customers {
    final query = _query.toLowerCase().trim();

    return _customerList.where((customer) {
      final matchesStatus =
          _activeOnly == null || customer.isActive == _activeOnly;

      final matchesQuery =
          query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          customer.mobile.contains(query) ||
          customer.route.toLowerCase().contains(query);

      return matchesStatus && matchesQuery;
    }).toList();
  }

  double get _totalDue {
    double total = 0;

    for (final CustomerModel customer in _customerList) {
      total += _currentBalanceFor(customer);
    }

    return total;
  }

  double _currentBalanceFor(CustomerModel customer) {
    final String customerId = customer.customerId.trim().toUpperCase();

    if (customerId.isEmpty) {
      return customer.balance;
    }

    return _currentBalances[customerId] ?? customer.balance;
  }

  @override
  void initState() {
    super.initState();

    _loadCustomers();
    _loadRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentBalances() async {
    if (_customerList.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _loadingBalances = true;
      });
    }

    try {
      final List<Future<void>> requests = [];

      final Map<String, double> loadedBalances = <String, double>{};

      for (final CustomerModel customer in _customerList) {
        final String customerId = customer.customerId.trim().toUpperCase();

        if (customerId.isEmpty) {
          continue;
        }

        requests.add(() async {
          try {
            final http.Response response = await http.get(
              Uri.parse(ApiConfig.customerLedger(customerId)),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${ApiConfig.token}',
              },
            );

            if (response.statusCode != 200) {
              return;
            }

            final dynamic decoded = jsonDecode(response.body);

            if (decoded is! Map || decoded['success'] != true) {
              return;
            }

            final dynamic ledgerData = decoded['data'];

            if (ledgerData is! Map) {
              return;
            }

            loadedBalances[customerId] =
                double.tryParse(ledgerData['balance']?.toString() ?? '0') ?? 0;
          } catch (_) {
            // Keep existing value for this
            // customer if one request fails.
          }
        }());
      }

      await Future.wait(requests);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentBalances
          ..clear()
          ..addAll(loadedBalances);

        _loadingBalances = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingBalances = false;
      });
    }
  }

  Future<void> _loadCustomers() async {
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

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> records = data['data'] as List<dynamic>? ?? [];

        final customers = records.map((item) {
          final map = item as Map<String, dynamic>;

          return CustomerModel.fromJson(map);
        }).toList();

        setState(() {
          _customerList = customers;
        });

        await _loadCurrentBalances();
      } else {
        _message(data['message']?.toString() ?? 'Unable to load customers.');
      }
    } catch (error) {
      if (!mounted) return;

      _message('Unable to load customers from server.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingCustomers = false;
        });
      }
    }
  }

  Future<void> _loadRoutes() async {
    if (mounted) {
      setState(() {
        _loadingRoutes = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.routes),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> records = data['data'] as List<dynamic>? ?? [];

        final routes = records
            .where((item) {
              final map = item as Map<String, dynamic>;
              return map['isActive'] != false;
            })
            .map((item) {
              final map = item as Map<String, dynamic>;
              return map['routeName']?.toString() ?? '';
            })
            .where((name) => name.trim().isNotEmpty)
            .toList();

        setState(() {
          _routeList = routes;
        });
      } else {
        _message(data['message']?.toString() ?? 'Unable to load routes.');
      }
    } catch (error) {
      if (!mounted) return;

      _message('Unable to load routes from server.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingRoutes = false;
        });
      }
    }
  }

  Future<void> _addCustomer() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    String? route = _routeList.isNotEmpty ? _routeList.first : null;

    final customer = await showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 22,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Customer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter customer name'
                      : null,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) => value?.length == 10
                      ? null
                      : 'Enter a 10-digit mobile number',
                ),
                const SizedBox(height: 11),
                DropdownButtonFormField<String>(
                  value: route,
                  isExpanded: true,

                  decoration: InputDecoration(
                    labelText: 'Route',
                    prefixIcon: const Icon(Icons.route_outlined),
                    suffixIcon: _loadingRoutes
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),

                  items: _routeList
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),

                  onChanged: _routeList.isEmpty
                      ? null
                      : (value) {
                          route = value;
                        },

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select route';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Opening balance',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }

                      Navigator.pop(
                        sheetContext,
                        CustomerModel(
                          name: nameController.text.trim(),

                          mobile: mobileController.text.trim(),

                          route: route ?? '',

                          balance: double.tryParse(balanceController.text) ?? 0,
                        ),
                      );
                    },
                    child: const Text('Save Customer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (customer == null || !mounted) {
      return;
    }

    await _saveCustomer(customer);
  }

  Future<void> _saveCustomer(CustomerModel customer) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.customers),

        headers: {
          'Content-Type': 'application/json',

          'Authorization': 'Bearer ${ApiConfig.token}',
        },

        body: jsonEncode({
          'name': customer.name,

          'mobile': customer.mobile,

          'route': customer.route,

          'balance': customer.balance,
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSavedMessage(
          context,
          data['message']?.toString() ?? 'Customer added successfully.',
        );

        await _loadCustomers();
      } else {
        _message(data['message']?.toString() ?? 'Unable to add customer.');
      }
    } catch (error) {
      if (!mounted) return;

      _message('Unable to connect to backend.');
    }
  }

  Future<void> _editCustomer(CustomerModel customer) async {
    if (customer.id.trim().isEmpty) {
      _message('Customer database ID is missing. Please reload customers.');
      return;
    }

    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: customer.name);

    final mobileController = TextEditingController(text: customer.mobile);

    final balanceController = TextEditingController(
      text: customer.balance.toStringAsFixed(0),
    );

    String? selectedRoute = customer.route.trim().isNotEmpty
        ? customer.route
        : (_routeList.isNotEmpty ? _routeList.first : null);

    // In case an old customer contains a route
    // that is currently inactive / missing.
    final availableRoutes = <String>[..._routeList];

    if (selectedRoute != null &&
        selectedRoute.trim().isNotEmpty &&
        !availableRoutes.contains(selectedRoute)) {
      availableRoutes.insert(0, selectedRoute);
    }

    bool isActive = customer.isActive;

    final updatedCustomer = await showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  MediaQuery.viewInsetsOf(sheetContext).bottom + 22,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Edit Customer',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),

                      if (customer.customerId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          customer.customerId,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter customer name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 11),

                      TextFormField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          if (value?.length != 10) {
                            return 'Enter a 10-digit mobile number';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 11),

                      DropdownButtonFormField<String>(
                        value: selectedRoute,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Route',
                          prefixIcon: Icon(Icons.route_outlined),
                        ),
                        items: availableRoutes
                            .map(
                              (route) => DropdownMenuItem<String>(
                                value: route,
                                child: Text(
                                  route,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: availableRoutes.isEmpty
                            ? null
                            : (value) {
                                setSheetState(() {
                                  selectedRoute = value;
                                });
                              },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please select route';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 11),

                      TextFormField(
                        controller: balanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Opening / current balance',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isActive,
                        title: const Text('Customer Active'),
                        subtitle: Text(
                          isActive
                              ? 'Customer can be used in transactions'
                              : 'Customer is currently inactive',
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            isActive = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }

                            Navigator.pop(
                              sheetContext,
                              customer.copyWith(
                                name: nameController.text.trim(),
                                mobile: mobileController.text.trim(),
                                route: selectedRoute ?? '',
                                balance:
                                    double.tryParse(balanceController.text) ??
                                    0,
                                isActive: isActive,
                              ),
                            );
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Update Customer'),
                        ),
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

    if (updatedCustomer == null || !mounted) {
      return;
    }

    await _updateCustomer(updatedCustomer);
  }

  Future<void> _updateCustomer(CustomerModel customer) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.customerById(customer.id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
        body: jsonEncode({
          'name': customer.name,
          'mobile': customer.mobile,
          'route': customer.route,
          'balance': customer.balance,
          'isActive': customer.isActive,
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        showSavedMessage(
          context,
          data['message']?.toString() ?? 'Customer updated successfully.',
        );

        await _loadCustomers();
      } else {
        _message(data['message']?.toString() ?? 'Unable to update customer.');
      }
    } catch (error) {
      if (!mounted) return;

      _message('Unable to connect to backend.');
    }
  }

  Future<void> _deleteCustomer(CustomerModel customer) async {
    if (customer.id.trim().isEmpty) {
      _message('Customer database ID is missing. Please reload customers.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Customer?'),
          content: Text(
            'Are you sure you want to delete "${customer.name}"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.customerById(customer.id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Customer deleted successfully.',
            ),
          ),
        );

        await _loadCustomers();
      } else {
        _message(data['message']?.toString() ?? 'Unable to delete customer.');
      }
    } catch (error) {
      if (!mounted) return;

      _message('Unable to connect to backend.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                    children: [
                      _buildSummary(),
                      const SizedBox(height: 18),
                      _buildSearchAndFilter(),
                      const SizedBox(height: 18),
                      if (_loadingCustomers)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_customers.isEmpty)
                        _buildEmptyState()
                      else
                        ...List.generate(
                          _customers.length,
                          (index) => _customerCard(_customers[index], index),
                        ),
                      const SizedBox(height: 8),
                      _buildAddCustomerBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 132,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0B3C9D), Color(0xFF075BC7)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(7, 14, 10, 22),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 29,
            ),
            tooltip: 'Back',
          ),
          IconButton(
            onPressed: _showQuickMenu,
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 30),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Manage your customer directory',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFFD8E7FF), fontSize: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _searchFocusNode.requestFocus(),
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'Search',
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => _message('No new customer alerts.'),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Notifications',
              ),
              Positioned(
                right: 3,
                top: 1,
                child: Container(
                  height: 19,
                  width: 19,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
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

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            label: 'Total Customers',
            value: '${_customerList.length}',
            icon: Icons.groups_rounded,
            color: AppColors.primary,
            background: const Color(0xFFF3F7FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            label: 'Total Outstanding',
            value: '₹${_totalDue.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFFFF681D),
            background: const Color(0xFFFFF7F2),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 39,
            width: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search by name, mobile or route...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: _showFilters,
          icon: const Icon(Icons.tune_rounded, size: 19),
          label: const Text('Filter'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(94, 51),
            backgroundColor: AppColors.surfaceBlue,
          ),
        ),
      ],
    );
  }

  Widget _customerCard(CustomerModel customer, int index) {
    final avatarColor = _avatarColors[index % _avatarColors.length];
    final avatarTextColor = _avatarTextColors[index % _avatarTextColors.length];
    final double currentBalance =
    _currentBalanceFor(
  customer,
);
    final canEdit = UiSession.instance.can(AppPermission.customersEdit);
    final canDelete = UiSession.instance.role == UserRole.admin;
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: avatarColor,
                    foregroundColor: avatarTextColor,
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (customer.isActive)
                    Positioned(
                      right: -1,
                      bottom: 2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF17C66B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${customer.route}  •  ${customer.mobile}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                 Text(
  _loadingBalances
      ? '...'
      : '₹${currentBalance.toStringAsFixed(0)}',
  style: TextStyle(
    color: currentBalance > 0.001
        ? const Color(0xFFFF681D)
        : AppColors.success,
    fontSize: 15,
    fontWeight: FontWeight.w900,
  ),
),

const SizedBox(height: 3),

Text(
  _loadingBalances
      ? 'Checking...'
      : currentBalance > 0.001
          ? 'Outstanding'
          : 'Clear',
  style: const TextStyle(
    color:
        AppColors.textSecondary,
    fontSize: 9.5,
  ),
),
                ],
              ),
              const SizedBox(width: 3),

              if (canEdit || canDelete)
                PopupMenuButton<String>(
                  tooltip: 'Customer actions',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCustomer(customer);
                    }

                    if (value == 'delete') {
                      _deleteCustomer(customer);
                    }
                  },
                  itemBuilder: (context) => [
                    if (canEdit)
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Text('Edit Customer'),
                          ],
                        ),
                      ),

                    if (canEdit && canDelete)
                      const PopupMenuDivider(),

                    if (canDelete)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete Customer',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          SizedBox(
            height: 42,
            child: Row(
              children: [
                Expanded(
                  child: _cardAction(
                    Icons.phone_outlined,
                    'Call',
                    () => _message('Calling ${customer.mobile}'),
                  ),
                ),
                _actionDivider(),
                Expanded(
                  child: _cardAction(
                    Icons.visibility_outlined,
                    'View',
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            CustomerDetailScreen(customer: customer),
                      ),
                    ),
                  ),
                ),
                _actionDivider(),
                Expanded(
                  child: _cardAction(
                    Icons.account_balance_wallet_outlined,
                    'Collection',
                    () => _message('Collection opened for ${customer.name}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionDivider() =>
      Container(height: 18, width: 1, color: AppColors.divider);

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 42,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          const Text(
            'No Customers Found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try changing your search or status filter.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          if (UiSession.instance.can(AppPermission.customersCreate)) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _addCustomer,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Customer'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddCustomerBanner() {
    if (!UiSession.instance.can(AppPermission.customersCreate)) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          final info = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maintain customers & collections',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Keep customer data updated for smooth operations.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final button = OutlinedButton.icon(
            onPressed: _addCustomer,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Customer'),
          );
          if (compact) {
            return Column(
              children: [
                info,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    const items = <(IconData, String)>[
      (Icons.home_outlined, 'Home'),
      (Icons.grid_view_outlined, 'Operations'),
      (Icons.badge_outlined, 'Salesmen'),
      (Icons.analytics_outlined, 'Reports'),
      (Icons.more_horiz_rounded, 'More'),
    ];
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: _bottomNavigationTap,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.$1),
              selectedIcon: Icon(item.$1, color: AppColors.primary),
              label: item.$2,
            ),
          )
          .toList(),
    );
  }

  void _bottomNavigationTap(int index) {
    if (index == 0) {
      Navigator.maybePop(context);
      return;
    }
    if (index == 2) {
      Navigator.pushNamed(context, '/salesmen');
      return;
    }
    if (index == 3) {
      Navigator.pushNamed(context, '/reports');
      return;
    }
    _showQuickMenu();
  }

  void _showQuickMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick menu', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Allocation'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, '/allocation');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Sales'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, '/sales');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Collection'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, '/collection');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final option in <bool?>[null, true, false])
              ListTile(
                leading: Icon(
                  _activeOnly == option
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: _activeOnly == option
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(
                  option == null
                      ? 'All customers'
                      : option
                      ? 'Active'
                      : 'Inactive',
                ),
                onTap: () {
                  setState(() => _activeOnly = option);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }
}
