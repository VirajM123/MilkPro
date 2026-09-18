import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class SalesCollectionHistoryScreen extends StatefulWidget {
  const SalesCollectionHistoryScreen({super.key});

  @override
  State<SalesCollectionHistoryScreen> createState() =>
      _SalesCollectionHistoryScreenState();
}

class _SalesCollectionHistoryScreenState
    extends State<SalesCollectionHistoryScreen> with SingleTickerProviderStateMixin {
  AppUser get user => UiSession.instance.currentUser;
  bool get isAdmin => user.role == UserRole.admin;

  bool _loading = true;
  String _errorMessage = '';

  // Filter States
  String _selectedPreset = 'month';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedSalesmanId = 'ALL';
  String _selectedCustomerId = 'ALL';
  String _selectedPaymentMode = 'ALL';

  // Summary Data
  Map<String, dynamic> _kpi = <String, dynamic>{};
  Map<String, dynamic> _paymentModes = <String, dynamic>{};
  List<dynamic> _salesmenSummary = <dynamic>[];
  Map<String, dynamic>? _unassignedSummary;
  List<dynamic> _salesmenList = <dynamic>[];
  List<dynamic> _customersList = <dynamic>[];

  // Salesman view detail tabs
  late TabController _salesmanTabController;
  bool _salesmanDetailLoading = false;
  Map<String, dynamic>? _salesmanDetailData;

  @override
  void initState() {
    super.initState();
    _salesmanTabController = TabController(length: 3, vsync: this);
    _initDefaultDates();
    _loadHistoryData();
  }

  @override
  void dispose() {
    _salesmanTabController.dispose();
    super.dispose();
  }

  void _initDefaultDates() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day);
  }

  String _formatDateYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatMoney(dynamic value) {
    final num val = (value is num) ? value : (double.tryParse(value?.toString() ?? '') ?? 0.0);
    final parts = val.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    String result = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      result = intPart[i] + result;
      count++;
      if (count == 3 && i > 0) {
        result = ',$result';
      } else if (count > 3 && (count - 3) % 2 == 0 && i > 0) {
        result = ',$result';
      }
    }
    return '₹ $result.${decPart == "00" ? "00" : decPart}';
  }

  String _formatDisplayDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTimestamp(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m $ampm';
    } catch (_) {
      return '-';
    }
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final queryParams = <String, String>{
        'startDate': _formatDateYmd(_startDate),
        'endDate': _formatDateYmd(_endDate),
      };

      if (isAdmin && _selectedSalesmanId != 'ALL') {
        queryParams['salesmanId'] = _selectedSalesmanId;
      }
      if (_selectedCustomerId != 'ALL') {
        queryParams['customerId'] = _selectedCustomerId;
      }
      if (_selectedPaymentMode != 'ALL') {
        queryParams['paymentMode'] = _selectedPaymentMode;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/history/sales-collection-summary')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode != 200 || decoded is! Map || decoded['success'] != true) {
        throw Exception(decoded is Map ? decoded['message']?.toString() : 'Failed to load history data');
      }

      final data = Map<String, dynamic>.from(decoded);
      if (!mounted) return;

      setState(() {
        _kpi = Map<String, dynamic>.from(data['kpi'] ?? {});
        _paymentModes = Map<String, dynamic>.from(data['paymentModes'] ?? {});
        _salesmenSummary = List<dynamic>.from(data['salesmenSummary'] ?? []);
        _unassignedSummary = data['unassignedSummary'] != null
            ? Map<String, dynamic>.from(data['unassignedSummary'])
            : null;
        _salesmenList = List<dynamic>.from(data['salesmen'] ?? []);
        _customersList = List<dynamic>.from(data['customers'] ?? []);
        _loading = false;
      });

      // If salesman login, also load his detail tabs (Sales, Collections, Customer summary)
      if (!isAdmin) {
        _loadSalesmanPersonalDetails();
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = err.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadSalesmanPersonalDetails() async {
    setState(() {
      _salesmanDetailLoading = true;
    });

    try {
      final queryParams = <String, String>{
        'startDate': _formatDateYmd(_startDate),
        'endDate': _formatDateYmd(_endDate),
      };
      if (_selectedPaymentMode != 'ALL') {
        queryParams['paymentMode'] = _selectedPaymentMode;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/history/salesman-details')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded is Map && decoded['success'] == true) {
        if (!mounted) return;
        setState(() {
          _salesmanDetailData = Map<String, dynamic>.from(decoded);
          _salesmanDetailLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _salesmanDetailLoading = false;
      });
    }
  }

  void _setPreset(String p) {
    final now = DateTime.now();
    setState(() {
      _selectedPreset = p;
      if (p == 'today') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day);
      } else if (p == 'week') {
        final diff = now.weekday - 1;
        _startDate = DateTime(now.year, now.month, now.day - diff);
        _endDate = DateTime(now.year, now.month, now.day);
      } else if (p == 'month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month, now.day);
      }
    });
    _loadHistoryData();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _selectedPreset = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadHistoryData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistoryData,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Custom Navy App Bar matching screenshot
              SliverToBoxAdapter(
                child: _buildTopNavyHeader(),
              ),

              // Main content body
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title section
                    _buildPageTitleRow(),
                    const SizedBox(height: 14),

                    // Top 4 Main KPI Cards
                    _buildMainKpiCards(),
                    const SizedBox(height: 12),

                    // 3 Payment Mode Cards (Cash, Cheque, UPI)
                    _buildPaymentModeRow(),
                    const SizedBox(height: 16),

                    // Filter Card
                    _buildFilterCard(),
                    const SizedBox(height: 18),

                    // Body based on Role:
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage.isNotEmpty)
                      _buildErrorCard()
                    else if (isAdmin)
                      _buildAdminSalesmanSummarySection()
                    else
                      _buildSalesmanPersonalHistorySection(),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. TOP NAVY HEADER (Matching Reference Screenshot)
  // ============================================================
  Widget _buildTopNavyHeader() {
    final initials = (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase();

    return Container(
      color: const Color(0xFF0F2B48),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              // Initial circle avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF0F2B48),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Portal subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isAdmin ? 'Administrator Portal' : 'Salesman Portal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Back/Close Button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. TITLE & DATE ROW
  // ============================================================
  Widget _buildPageTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collection History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isAdmin
                    ? 'Track and analyze payment collections by salesman'
                    : 'Track your live sales, collections and performance',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Date pill badge
        InkWell(
          onTap: _pickDateRange,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDisplayDate(_endDate),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 3. MAIN KPI CARDS (Green Collected, Blue Transactions)
  // ============================================================
  Widget _buildMainKpiCards() {
    final totalCollected = _kpi['totalCollected'] ?? 0;
    final totalTrans = _kpi['collectionTransactions'] ?? 0;
    final totalSales = _kpi['totalSales'] ?? 0;
    final currentOutstanding = _kpi['currentOutstanding'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            // CARD 1: Total Collected (Green)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB7E4C7)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A765),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.currency_rupee, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatMoney(totalCollected),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Text(
                            'Total Collected',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // CARD 2: Total Transactions (Blue)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7DEFF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1665E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalTrans',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Text(
                            'Total Transactions',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // CARD 3 & 4: Total Sales & Outstanding
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Sales', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      _formatMoney(totalSales),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1665E8)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Outstanding', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      _formatMoney(currentOutstanding),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                    if (_kpi['allTimeOutstanding'] != null && _kpi['allTimeOutstanding'] != currentOutstanding) ...[
                      const SizedBox(height: 2),
                      Text(
                        'All-Time: ${_formatMoney(_kpi['allTimeOutstanding'])}',
                        style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // 4. PAYMENT MODE ROW (Cash, Cheque, UPI)
  // ============================================================
  Widget _buildPaymentModeRow() {
    final cash = _paymentModes['cash'] ?? 0;
    final cheque = _paymentModes['cheque'] ?? 0;
    final upi = _paymentModes['upi'] ?? 0;

    return Row(
      children: [
        // Cash Card (Green)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.money_rounded, size: 20, color: Color(0xFF059669)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatMoney(cash),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
                const Text('Cash Collected', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Cheque Card (Orange)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.credit_card_outlined, size: 20, color: Color(0xFFEA580C)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatMoney(cheque),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
                const Text('Cheque Collected', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // UPI Card (Purple)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Column(
              children: [
                const Icon(Icons.call_made_rounded, size: 20, color: Color(0xFF7C3AED)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatMoney(upi),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
                const Text('UPI Collected', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 5. FILTER CARD (Salesman, Start Date, End Date, Modes)
  // ============================================================
  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salesman Dropdown (Admin only)
          if (isAdmin) ...[
            const Text('Salesman', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSalesmanId,
                  items: [
                    const DropdownMenuItem(value: 'ALL', child: Text('All Salesmen')),
                    ..._salesmenList.map(
                      (sm) => DropdownMenuItem(
                        value: sm['salesmanId']?.toString() ?? '',
                        child: Text('${sm['name']} (${sm['salesmanId']})'),
                      ),
                    ),
                    const DropdownMenuItem(value: 'UNASSIGNED', child: Text('Admin / Unassigned')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSalesmanId = val);
                      _loadHistoryData();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Customer Dropdown
          if (_customersList.isNotEmpty) ...[
            const Text('Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCustomerId,
                  items: [
                    const DropdownMenuItem(value: 'ALL', child: Text('All Customers')),
                    ..._customersList.map(
                      (c) => DropdownMenuItem(
                        value: c['customerId']?.toString() ?? '',
                        child: Text('${c['name']} (${c['customerId']})'),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCustomerId = val);
                      _loadHistoryData();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Date Presets
          Row(
            children: [
              _buildPresetChip('Today', 'today'),
              const SizedBox(width: 8),
              _buildPresetChip('This Week', 'week'),
              const SizedBox(width: 8),
              _buildPresetChip('This Month', 'month'),
            ],
          ),
          const SizedBox(height: 10),

          // Start & End Date Pickers
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) {
                      setState(() {
                        _selectedPreset = 'custom';
                        _startDate = d;
                      });
                      _loadHistoryData();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(_formatDisplayDate(_startDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) {
                      setState(() {
                        _selectedPreset = 'custom';
                        _endDate = d;
                      });
                      _loadHistoryData();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(_formatDisplayDate(_endDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment Mode Toggle Chips
          const Text('Payment Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModeChip('All', 'ALL'),
                const SizedBox(width: 8),
                _buildModeChip('Cash', 'CASH'),
                const SizedBox(width: 8),
                _buildModeChip('Cheque', 'CHEQUE'),
                const SizedBox(width: 8),
                _buildModeChip('UPI', 'UPI'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, String value) {
    final active = _selectedPaymentMode == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMode = value);
        _loadHistoryData();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E3A5F) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String preset) {
    final active = _selectedPreset == preset;
    return InkWell(
      onTap: () => _setPreset(preset),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E3A5F) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 6. ADMIN VIEW: SALESMAN SUMMARY CARDS (Matching Screenshot)
  // ============================================================
  Widget _buildAdminSalesmanSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Salesman Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Text(
              '${_salesmenSummary.length} Salesmen',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_salesmenSummary.isEmpty && _unassignedSummary == null)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('No salesman activity found for selected filters.'),
          ),

        // Salesman cards list
        ..._salesmenSummary.map((sm) => _buildSalesmanCard(sm)),

        // Admin / Unassigned card if available
        if (_unassignedSummary != null)
          _buildSalesmanCard(_unassignedSummary!, isUnassigned: true),
      ],
    );
  }

  Widget _buildSalesmanCard(Map<String, dynamic> sm, {bool isUnassigned = false}) {
    final name = sm['salesmanName']?.toString() ?? (isUnassigned ? 'Admin / Unassigned' : 'Salesman');
    final initials = (name.isNotEmpty ? name[0] : 'S').toUpperCase();
    final code = sm['salesmanId']?.toString() ?? '-';
    final routes = sm['routes'] is List ? (sm['routes'] as List).map((r) => r['routeName']).join(', ') : '';
    final totalSales = sm['totalSales'] ?? 0;
    final totalCollected = sm['totalCollected'] ?? 0;
    final currentOutstanding = sm['currentOutstanding'] ?? 0;
    final cash = sm['cash'] ?? 0;
    final cheque = sm['cheque'] ?? 0;
    final upi = sm['upi'] ?? 0;
    final transCount = sm['collectionTransactions'] ?? 0;
    final lastTime = _formatTimestamp(sm['lastCollectionDate']?.toString());

    return InkWell(
      onTap: () => _showSalesmanDetailsModal(sm),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Avatar, Name, Code, Collected Amount, Chevron
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isUnassigned ? const Color(0xFFF1F5F9) : const Color(0xFFE0F2FE),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: isUnassigned ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        routes.isNotEmpty ? '$routes • Code: $code' : 'Code: $code',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatMoney(totalCollected),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const Text('Total Collected', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 10),

            // Metric Trio: Sales, Collection, Outstanding
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sales', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatMoney(totalSales),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1665E8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Collection', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatMoney(totalCollected),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Outstanding', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatMoney(currentOutstanding),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Mini Modes Row (Cash, Cheque, UPI)
            Row(
              children: [
                Expanded(
                  child: _buildMiniModeBox(Icons.money, _formatMoney(cash), 'Cash', const Color(0xFF10B981)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniModeBox(Icons.credit_card, _formatMoney(cheque), 'Cheque', const Color(0xFFEA580C)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniModeBox(Icons.call_made, _formatMoney(upi), 'UPI', const Color(0xFF8B5CF6)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom row: transactions & last collection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('$transCount Transactions', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('Last: $lastTime', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniModeBox(IconData icon, String amount, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 7. SALESMAN VIEW: MY SALES & COLLECTION TABS
  // ============================================================
  Widget _buildSalesmanPersonalHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Sales & Collection History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 10),

        // Tabs
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          ),
          child: TabBar(
            controller: _salesmanTabController,
            labelColor: const Color(0xFF1665E8),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF1665E8),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'My Sales'),
              Tab(text: 'My Collections'),
              Tab(text: 'Customer Summary'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (_salesmanDetailLoading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_salesmanDetailData == null)
          const Text('No records available.')
        else
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _salesmanTabController,
              children: [
                _buildSalesmanSalesList(_salesmanDetailData!['sales']?['list'] ?? []),
                _buildSalesmanCollectionsList(_salesmanDetailData!['collections']?['list'] ?? []),
                _buildSalesmanCustomerSummaryList(_salesmanDetailData!['customerSummary'] ?? []),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSalesmanSalesList(List<dynamic> sales) {
    if (sales.isEmpty) {
      return const Center(child: Text('No sales bills recorded for this period.'));
    }
    return ListView.builder(
      itemCount: sales.length,
      itemBuilder: (context, idx) {
        final s = sales[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            title: Text(s['customerName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Bill: ${s['saleNo']} • ${_formatTimestamp(s['saleDate'])}', style: const TextStyle(fontSize: 11)),
            trailing: Text(_formatMoney(s['grandTotal']), style: const TextStyle(color: Color(0xFF1665E8), fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildSalesmanCollectionsList(List<dynamic> cols) {
    if (cols.isEmpty) {
      return const Center(child: Text('No collection receipts recorded for this period.'));
    }
    return ListView.builder(
      itemCount: cols.length,
      itemBuilder: (context, idx) {
        final c = cols[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            title: Text(c['customerName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Rec: ${c['receiptNo']} • ${c['paymentMode']}', style: const TextStyle(fontSize: 11)),
            trailing: Text(_formatMoney(c['amount']), style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildSalesmanCustomerSummaryList(List<dynamic> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No customer summary available.'));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final c = list[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            title: Text(c['customerName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Sales: ${_formatMoney(c['periodSales'])} | Col: ${_formatMoney(c['periodCollections'])}', style: const TextStyle(fontSize: 11)),
            trailing: Text(
              'Due: ${_formatMoney(c['currentOutstanding'])}',
              style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // 8. SALESMAN DETAILS MODAL SHEET (Admin Click)
  // ============================================================
  void _showSalesmanDetailsModal(Map<String, dynamic> sm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SalesmanDetailModalSheet(
        salesman: sm,
        startDate: _startDate,
        endDate: _endDate,
        formatMoney: _formatMoney,
        formatDate: _formatDisplayDate,
        formatTimestamp: _formatTimestamp,
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          Text(_errorMessage, style: const TextStyle(color: Color(0xFFE5484D))),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadHistoryData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ==============================================================
// SALESMAN DETAIL BOTTOM SHEET WIDGET
// ==============================================================
class _SalesmanDetailModalSheet extends StatefulWidget {
  const _SalesmanDetailModalSheet({
    required this.salesman,
    required this.startDate,
    required this.endDate,
    required this.formatMoney,
    required this.formatDate,
    required this.formatTimestamp,
  });

  final Map<String, dynamic> salesman;
  final DateTime startDate;
  final DateTime endDate;
  final String Function(dynamic) formatMoney;
  final String Function(DateTime) formatDate;
  final String Function(String?) formatTimestamp;

  @override
  State<_SalesmanDetailModalSheet> createState() => _SalesmanDetailModalSheetState();
}

class _SalesmanDetailModalSheetState extends State<_SalesmanDetailModalSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      String ymd(DateTime dt) =>
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/history/salesman-details').replace(
        queryParameters: {
          'salesmanId': widget.salesman['salesmanId']?.toString() ?? '',
          'startDate': ymd(widget.startDate),
          'endDate': ymd(widget.endDate),
        },
      );

      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );

      final decoded = jsonDecode(res.body);
      if (res.statusCode == 200 && decoded is Map && decoded['success'] == true) {
        if (!mounted) return;
        setState(() {
          _details = Map<String, dynamic>.from(decoded);
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.salesman['salesmanName'] ?? 'Salesman';
    final code = widget.salesman['salesmanId'] ?? '-';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2B48),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Code: $code', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF1665E8),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF1665E8),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Sales Bills'),
                Tab(text: 'Collections'),
                Tab(text: 'Customer Summary'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSalesTab(),
                      _buildCollectionsTab(),
                      _buildCustomerSummaryTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final ov = _details?['overview'] ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _statBox('Total Sales', widget.formatMoney(ov['totalSales']), '${ov['salesBillsCount'] ?? 0} bills', const Color(0xFF1665E8)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statBox('Total Collected', widget.formatMoney(ov['totalCollected']), '${ov['collectionTransactions'] ?? 0} receipts', const Color(0xFF059669)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statBox(
                'Outstanding',
                widget.formatMoney(ov['currentOutstanding']),
                ov['allTimeOutstanding'] != null && ov['allTimeOutstanding'] != ov['currentOutstanding']
                    ? 'All-Time: ${widget.formatMoney(ov['allTimeOutstanding'])}'
                    : 'Period balance',
                const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statBox('Advance', widget.formatMoney(ov['currentAdvance']), 'Customer Credit', const Color(0xFF7C3AED)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statBox(String label, String value, String sub, Color col) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: col)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    final sales = (_details?['sales']?['list'] as List?) ?? [];
    if (sales.isEmpty) return const Center(child: Text('No sales bills.'));
    return ListView.builder(
      itemCount: sales.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final s = sales[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: ListTile(
            title: Text(s['customerName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Bill: ${s['saleNo']} • Mode: ${s['paymentMode']}', style: const TextStyle(fontSize: 11)),
            trailing: Text(widget.formatMoney(s['grandTotal']), style: const TextStyle(color: Color(0xFF1665E8), fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildCollectionsTab() {
    final cols = (_details?['collections']?['list'] as List?) ?? [];
    if (cols.isEmpty) return const Center(child: Text('No collections.'));
    return ListView.builder(
      itemCount: cols.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final c = cols[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: ListTile(
            title: Text(c['customerName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Rec: ${c['receiptNo']} • ${c['paymentMode']}', style: const TextStyle(fontSize: 11)),
            trailing: Text(widget.formatMoney(c['amount']), style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildCustomerSummaryTab() {
    final list = (_details?['customerSummary'] as List?) ?? [];
    if (list.isEmpty) return const Center(child: Text('No customer summary.'));
    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final c = list[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: ListTile(
            title: Text(c['customerName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Sales: ${widget.formatMoney(c['periodSales'])} | Col: ${widget.formatMoney(c['periodCollections'])}', style: const TextStyle(fontSize: 11)),
            trailing: Text('Due: ${widget.formatMoney(c['currentOutstanding'])}', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        );
      },
    );
  }
}
