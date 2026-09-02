import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../returns/return_settlement_screen.dart';
import 'assign_allocation_page.dart';

class AllocationScreen extends StatefulWidget {
  const AllocationScreen({super.key});

  @override
  State<AllocationScreen> createState() => _AllocationScreenState();
}

class _AllocationScreenState extends State<AllocationScreen> {
  static const Color primaryBlue = AppColors.primary;
  static const Color darkBlue = AppColors.primaryDeep;
  static const Color backgroundColor = AppColors.background;
  static const Color textDark = AppColors.textPrimary;
  static const Color textGrey = AppColors.textSecondary;
  static const Color green = AppColors.success;
  static const Color orange = AppColors.warning;
  static const Color purple = AppColors.purple;

  // ============================================================
  // MASTER DATA
  // ============================================================

  final List<String> _salesmen = ['Omkar', 'Viraj', 'Mahesh'];

  final List<String> _routes = ['Route A', 'Route B', 'Route C'];

  // This UI supports any number of products.
  // Replace/add your actual product master items here or load them from API.
  final List<String> _products = [
    'Full Cream Milk',
    'Toned Milk',
    'Buffalo Milk',
    'Ghee',
    'Curd',
  ];

  // ============================================================
  // ALLOCATION DATA
  // ============================================================

  final List<Map<String, dynamic>> _allocations = AllocationStore.allocations;

  DateTime _selectedDate = DateTime(2026, 8, 20);

  // ============================================================
  // HELPERS / CALCULATIONS
  // ============================================================

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _batchIdOf(Map<String, dynamic> item, int fallbackIndex) {
    final String stored = (item['batchId'] ?? '').toString().trim();
    if (stored.isNotEmpty) return stored;

    // Backward compatibility for older single-product allocations.
    return 'legacy_$fallbackIndex';
  }

  List<Map<String, dynamic>> get _filteredAllocations {
    return _allocations.where((item) {
      final dynamic rawDate = item['date'];

      if (rawDate is! DateTime) {
        return false;
      }

      return rawDate.year == _selectedDate.year &&
          rawDate.month == _selectedDate.month &&
          rawDate.day == _selectedDate.day;
    }).toList();
  }

  List<_AllocationGroup> get _filteredGroups {
    final List<Map<String, dynamic>> items = _filteredAllocations;
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (int i = 0; i < items.length; i++) {
      final Map<String, dynamic> item = items[i];

      String groupKey = (item['batchId'] ?? '').toString().trim();

      if (groupKey.isEmpty) {
        // For old records, group only that individual line so nothing breaks.
        groupKey = _batchIdOf(item, i);
      }

      grouped.putIfAbsent(groupKey, () => <Map<String, dynamic>>[]).add(item);
    }

    return grouped.entries
        .map(
          (entry) => _AllocationGroup(batchId: entry.key, items: entry.value),
        )
        .toList();
  }

  int get _totalAllocated {
    int total = 0;

    for (final item in _allocations) {
      total += _asInt(item['qty']);
    }

    return total;
  }

  int get _totalReturned {
    int total = 0;

    for (final item in _allocations) {
      total += _asInt(item['returnedQty']);
    }

    return total;
  }

  int get _totalPending => _totalAllocated - _totalReturned;

  int get _totalRoutes {
    return _allocations
        .map((e) => (e['route'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;
  }

  int get _totalSalesmen {
    return _allocations
        .map((e) => (e['salesman'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;
  }

  int get _selectedDateQuantity {
    int total = 0;

    for (final item in _filteredAllocations) {
      total += _asInt(item['qty']);
    }

    return total;
  }

  int get _selectedDateRoutes {
    return _filteredAllocations
        .map((e) => (e['route'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;
  }

  int get _selectedDateProductCount {
    return _filteredAllocations
        .map((e) => (e['product'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;
  }

  // ============================================================
  // OPEN ASSIGN ALLOCATION - MULTIPLE PRODUCTS
  // ============================================================

  Future<void> _openAssignAllocation() async {
    final List<Map<String, dynamic>>? result = await Navigator.of(context)
        .push<List<Map<String, dynamic>>>(
          MaterialPageRoute(
            builder: (_) => AssignAllocationPage(
              routes: _routes,
              salesmen: _salesmen,
              products: _products,
            ),
          ),
        );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    setState(() {
      // Insert all selected product lines together.
      // They share the same batchId, route, salesman and date.
      _allocations.insertAll(0, result);

      final dynamic allocationDate = result.first['date'];

      if (allocationDate is DateTime) {
        _selectedDate = allocationDate;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.length} product${result.length == 1 ? '' : 's'} allocated successfully.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // TAKE RETURN FOR INDIVIDUAL PRODUCT
  // ============================================================

  Future<void> _showReturnDialog(Map<String, dynamic> allocation) async {
    final bool hasSettlement = allocation['settlement'] is Map;

    final Map<String, dynamic>? result = await Navigator.of(context)
        .push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => ReturnSettlementScreen(allocation: allocation),
          ),
        );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      allocation['returnedQty'] = _asInt(result['returnedQty']);
      allocation['settlement'] = Map<String, dynamic>.from(result);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasSettlement
              ? 'Allocation settlement updated successfully.'
              : 'Return saved successfully.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickAllocationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PremiumAppBar(
        title: 'Allocation',
        subtitle: 'Daily route and product allocation',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filled(
              tooltip: 'Assign allocation',
              onPressed: _openAssignAllocation,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          children: [
            _buildDateSelector(),
            const SizedBox(height: 14),
            _buildStatistics(),
            const SizedBox(height: 20),
            _buildAllocationSection(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  // Kept for compatibility with the previous design while the simplified
  // layout is evaluated.
  // ignore: unused_element
  Widget _buildHeader() {
    return SizedBox(
      height: 142,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1268F0), Color(0xFF4A9FFF)],
              ),
            ),
          ),
          Positioned(
            right: -6,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.20,
                child: SizedBox(
                  width: 205,
                  height: 115,
                  child: Image.asset(
                    'assets/img/Allocation.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.maybePop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allocation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Manage route-wise product allocations',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFF3F8FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      top: -3,
                      right: -1,
                      child: Container(
                        width: 21,
                        height: 21,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4B45),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
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

  // ============================================================
  // DATE SELECTOR
  // ============================================================

  Widget _buildDateSelector() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _pickAllocationDate,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6EBF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09000000),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: primaryBlue,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dayName(_selectedDate.weekday),
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF536987),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _simpleStatCard(
              width: cardWidth,
              label: 'Allocations',
              value: '${_filteredGroups.length}',
              icon: Icons.assignment_outlined,
              color: primaryBlue,
            ),
            _simpleStatCard(
              width: cardWidth,
              label: 'Total quantity',
              value: '$_selectedDateQuantity Ltr',
              icon: Icons.local_drink_outlined,
              color: green,
            ),
            _simpleStatCard(
              width: cardWidth,
              label: 'Routes',
              value: '$_selectedDateRoutes',
              icon: Icons.route_outlined,
              color: orange,
            ),
            _simpleStatCard(
              width: cardWidth,
              label: 'Products',
              value: '$_selectedDateProductCount',
              icon: Icons.inventory_2_outlined,
              color: purple,
            ),
          ],
        );
      },
    );
  }

  Widget _simpleStatCard({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) => SizedBox(
    width: width,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: textGrey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ignore: unused_element
  Widget _summaryCard({
    required String title,
    required String value,
    required String suffix,
    required String asset,
    required Color accentColor,
    required Color background,
    required Color border,
  }) {
    return Container(
      height: 166,
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 49,
            height: 49,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.inventory_2_outlined,
                  color: accentColor,
                  size: 27,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: suffix,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Selected date',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textGrey,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALLOCATION SECTION - GROUPED BY ONE ASSIGN ACTION
  // ============================================================

  Widget _buildAllocationSection() {
    final List<_AllocationGroup> groups = _filteredGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAllocationHeader(),
        const SizedBox(height: 10),
        if (groups.isEmpty)
          Card(child: _buildEmptyState())
        else
          for (int i = 0; i < groups.length; i++) ...[
            _buildAllocationGroupCard(groups[i]),
            if (i != groups.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildAllocationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allocation List',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'One route can contain multiple products',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationGroupCard(_AllocationGroup group) {
    final Map<String, dynamic> first = group.items.first;

    final DateTime date = first['date'] is DateTime
        ? first['date'] as DateTime
        : DateTime.now();

    final String salesman = (first['salesman'] ?? '').toString();
    final String route = (first['route'] ?? '').toString();

    int totalQty = 0;
    int returnedQty = 0;

    for (final item in group.items) {
      totalQty += _asInt(item['qty']);
      returnedQty += _asInt(item['returnedQty']);
    }

    final int pendingQty = totalQty - returnedQty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1E7F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          iconColor: primaryBlue,
          collapsedIconColor: const Color(0xFF647590),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: primaryBlue,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${group.items.length} item${group.items.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: textGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        salesman,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 13,
                      color: textGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)}',
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _miniMetric(
                      label: 'Allocated',
                      value: '$totalQty L',
                      color: primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    _miniMetric(
                      label: 'Returned',
                      value: '$returnedQty L',
                      color: orange,
                    ),
                    const SizedBox(width: 6),
                    _miniMetric(
                      label: 'Pending',
                      value: '$pendingQty L',
                      color: pendingQty <= 0 ? green : purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'PRODUCT',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 65,
                    child: Text(
                      'QTY',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: 34),
                ],
              ),
            ),
            const SizedBox(height: 6),
            for (int i = 0; i < group.items.length; i++) ...[
              _buildProductAllocationRow(group.items[i]),
              if (i != group.items.length - 1) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textGrey,
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAllocationRow(Map<String, dynamic> item) {
    final String product = (item['product'] ?? '').toString();
    final int qty = _asInt(item['qty']);
    final int returned = _asInt(item['returnedQty']);
    final int pending = qty - returned;

    final bool hasSettlement = item['settlement'] is Map;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(9, 9, 4, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE7EBF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (returned > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Returned $returned • Pending $pending',
                    style: TextStyle(
                      color: pending <= 0 ? green : orange,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 65,
            child: Text(
              '$qty Ltr',
              textAlign: TextAlign.right,
              maxLines: 1,
              style: const TextStyle(
                color: textDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              tooltip: '',
              position: PopupMenuPosition.under,
              iconSize: 19,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF647590),
                size: 19,
              ),
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (String value) {
                if (value == 'return' || value == 'edit_return') {
                  _showReturnDialog(item);
                }
              },
              itemBuilder: (BuildContext context) {
                final String settlementStatus =
                    ((item['settlement'] as Map?)?['status'] ?? '').toString();

                return [
                  PopupMenuItem<String>(
                    value: hasSettlement ? 'edit_return' : 'return',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasSettlement
                              ? Icons.edit_note_rounded
                              : Icons.keyboard_return_rounded,
                          size: 18,
                          color: hasSettlement ? primaryBlue : orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasSettlement
                              ? (settlementStatus == 'completed'
                                    ? 'Edit Settlement'
                                    : 'Edit Saved Return')
                              : 'Take Return',
                          style: TextStyle(
                            color: hasSettlement ? primaryBlue : textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOTAL FOOTER
  // ============================================================

  // ignore: unused_element
  Widget _buildTotalFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFECEFF4))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF4D89F8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.asset(
              'assets/img/TotalQuantityAllocation.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.local_drink_outlined,
                  color: Colors.white,
                  size: 24,
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Quantity Allocated',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_selectedDateQuantity Ltr',
                  maxLines: 1,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: _showAllocationSummary,
              borderRadius: BorderRadius.circular(13),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      color: primaryBlue,
                      size: 18,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Summary',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY SHEET
  // ============================================================

  void _showAllocationSummary() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE2EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Allocation Summary',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _summaryLine(
                  'Selected Date Quantity',
                  '$_selectedDateQuantity Ltr',
                  primaryBlue,
                ),
                const SizedBox(height: 8),
                _summaryLine(
                  'Selected Date Products',
                  '$_selectedDateProductCount',
                  purple,
                ),
                const SizedBox(height: 8),
                _summaryLine(
                  'Total Allocated',
                  '$_totalAllocated Ltr',
                  primaryBlue,
                ),
                const SizedBox(height: 8),
                _summaryLine('Total Returned', '$_totalReturned Ltr', orange),
                const SizedBox(height: 8),
                _summaryLine('Pending Quantity', '$_totalPending Ltr', green),
                const SizedBox(height: 8),
                _summaryLine('Total Routes', '$_totalRoutes', purple),
                const SizedBox(height: 8),
                _summaryLine('Total Salesmen', '$_totalSalesmen', primaryBlue),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryLine(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: primaryBlue,
              size: 31,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No allocations for this date',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Create one allocation and add all required products together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _openAssignAllocation,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Assign Allocation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

  String _monthName(int month) {
    const List<String> months = [
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

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String _dayName(int weekday) {
    const List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (weekday < 1 || weekday > 7) {
      return '';
    }

    return days[weekday - 1];
  }
}

// ============================================================================
// GROUP MODEL FOR DISPLAY
// ============================================================================

class _AllocationGroup {
  const _AllocationGroup({required this.batchId, required this.items});

  final String batchId;
  final List<Map<String, dynamic>> items;
}

// ============================================================================
// ASSIGN ALLOCATION PAGE - MULTIPLE PRODUCTS
// ============================================================================

class LegacyAssignAllocationPage extends StatefulWidget {
  const LegacyAssignAllocationPage({
    super.key,
    required this.routes,
    required this.salesmen,
    required this.products,
  });

  final List<String> routes;
  final List<String> salesmen;
  final List<String> products;

  @override
  State<LegacyAssignAllocationPage> createState() =>
      _AssignAllocationPageState();
}

class _AssignAllocationPageState extends State<LegacyAssignAllocationPage> {
  static const Color primaryBlue = Color(0xFF1665E8);
  static const Color backgroundColor = Color(0xFFF5F7FB);
  static const Color textDark = Color(0xFF102A56);
  static const Color textGrey = Color(0xFF71809D);
  // ignore: unused_field
  static const Color green = Color(0xFF16A765);
  static const Color red = Color(0xFFD94B4B);

  late DateTime _selectedDate;

  String? _selectedRoute;
  String? _selectedSalesman;

  final TextEditingController _searchController = TextEditingController();

  // Product -> quantity controller
  final Map<String, TextEditingController> _qtyControllers = {};

  // Keeps chosen products in display order.
  final List<String> _selectedProducts = [];

  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _selectedDate = DateTime.now();

    if (widget.routes.isNotEmpty) {
      _selectedRoute = widget.routes.first;
    }

    if (widget.salesmen.isNotEmpty) {
      _selectedSalesman = widget.salesmen.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();

    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // PRODUCT SELECTION
  // ============================================================

  // ignore: unused_element
  List<String> get _availableProducts {
    final List<String> unique = widget.products.toSet().toList();

    final String query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return unique;
    }

    return unique
        .where((product) => product.toLowerCase().contains(query))
        .toList();
  }

  int get _enteredTotalQuantity {
    int total = 0;

    for (final product in _selectedProducts) {
      total += int.tryParse(_qtyControllers[product]?.text.trim() ?? '') ?? 0;
    }

    return total;
  }

  // ignore: unused_element
  void _addProduct(String product) {
    if (_selectedProducts.contains(product)) {
      return;
    }

    setState(() {
      _selectedProducts.add(product);
      _qtyControllers[product] = TextEditingController();
    });
  }

  void _removeProduct(String product) {
    setState(() {
      _selectedProducts.remove(product);

      final TextEditingController? controller = _qtyControllers.remove(product);
      controller?.dispose();
    });
  }

  void _selectAllProducts() {
    final List<String> allProducts = widget.products.toSet().toList();

    setState(() {
      for (final product in allProducts) {
        if (!_selectedProducts.contains(product)) {
          _selectedProducts.add(product);
          _qtyControllers[product] = TextEditingController();
        }
      }
    });
  }

  void _clearAllProducts() {
    setState(() {
      for (final controller in _qtyControllers.values) {
        controller.dispose();
      }

      _qtyControllers.clear();
      _selectedProducts.clear();
    });
  }

  Future<void> _showProductPicker() async {
    final Set<String> temporarySelection = _selectedProducts.toSet();
    String bottomSearch = '';

    final Set<String>? selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final List<String> allProducts = widget.products.toSet().toList();

            final List<String> filtered = bottomSearch.trim().isEmpty
                ? allProducts
                : allProducts
                      .where(
                        (product) => product.toLowerCase().contains(
                          bottomSearch.trim().toLowerCase(),
                        ),
                      )
                      .toList();

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.78,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE2EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Products',
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Choose all items required for this route',
                                  style: TextStyle(
                                    color: textGrey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                if (temporarySelection.length ==
                                    allProducts.length) {
                                  temporarySelection.clear();
                                } else {
                                  temporarySelection
                                    ..clear()
                                    ..addAll(allProducts);
                                }
                              });
                            },
                            child: Text(
                              temporarySelection.length == allProducts.length
                                  ? 'Clear'
                                  : 'Select all',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: TextField(
                        onChanged: (value) {
                          setSheetState(() {
                            bottomSearch = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search product...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: primaryBlue,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F9FC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE1E7F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE1E7F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: primaryBlue,
                              width: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No products found',
                                style: TextStyle(
                                  color: textGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 3),
                              itemBuilder: (context, index) {
                                final String product = filtered[index];
                                final bool checked = temporarySelection
                                    .contains(product);

                                return CheckboxListTile(
                                  value: checked,
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: primaryBlue,
                                  title: Text(
                                    product,
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  secondary: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: primaryBlue,
                                      size: 18,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onChanged: (bool? value) {
                                    setSheetState(() {
                                      if (value == true) {
                                        temporarySelection.add(product);
                                      } else {
                                        temporarySelection.remove(product);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(temporarySelection);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Add ${temporarySelection.length} Product${temporarySelection.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      final List<String> existing = List<String>.from(_selectedProducts);

      for (final product in existing) {
        if (!selected.contains(product)) {
          final TextEditingController? controller = _qtyControllers.remove(
            product,
          );
          controller?.dispose();
          _selectedProducts.remove(product);
        }
      }

      for (final product in widget.products.toSet()) {
        if (selected.contains(product) &&
            !_selectedProducts.contains(product)) {
          _selectedProducts.add(product);
          _qtyControllers[product] = TextEditingController();
        }
      }
    });
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  // ============================================================
  // SAVE MULTIPLE PRODUCT LINES
  // ============================================================

  void _save() {
    if (_selectedRoute == null || _selectedSalesman == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route and salesman master data is required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final List<Map<String, dynamic>> lines = [];

    final String batchId =
        '${_selectedDate.millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';

    for (final product in _selectedProducts) {
      final int? qty = int.tryParse(
        _qtyControllers[product]?.text.trim() ?? '',
      );

      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid quantity for $product.'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      lines.add(<String, dynamic>{
        'batchId': batchId,
        'date': _selectedDate,
        'route': _selectedRoute!,
        'salesman': _selectedSalesman!,
        'product': product,
        'qty': qty,
        'returnedQty': 0,
      });
    }

    Navigator.of(context).pop(lines);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
                children: [
                  _buildCommonDetailsCard(),
                  const SizedBox(height: 14),
                  _buildProductsCard(),
                  const SizedBox(height: 14),
                  _buildAllocationTotalCard(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        _selectedProducts.isEmpty
                            ? 'Assign Allocation'
                            : 'Assign ${_selectedProducts.length} Product${_selectedProducts.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1665E8), Color(0xFF4698FF)],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.maybePop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Allocation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Allocate multiple products in one entry',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFE8F1FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMON DETAILS
  // ============================================================

  Widget _buildCommonDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E9F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: primaryBlue, size: 19),
              SizedBox(width: 7),
              Text(
                'Allocation Details',
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _label('Date'),
          _dateField(),
          const SizedBox(height: 14),
          _label('Route'),
          _dropdown(
            value: _selectedRoute,
            items: widget.routes,
            icon: Icons.route_outlined,
            onChanged: (String? value) {
              if (value == null) return;

              setState(() {
                _selectedRoute = value;
              });
            },
          ),
          const SizedBox(height: 14),
          _label('Salesman'),
          _dropdown(
            value: _selectedSalesman,
            items: widget.salesmen,
            icon: Icons.person_outline_rounded,
            onChanged: (String? value) {
              if (value == null) return;

              setState(() {
                _selectedSalesman = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT MULTI-SELECT + QUANTITY GRID
  // ============================================================

  Widget _buildProductsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E9F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products & Quantity',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Select many products and enter quantity for each',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_selectedProducts.length} selected',
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showProductPicker,
              icon: const Icon(Icons.playlist_add_rounded, size: 21),
              label: const Text(
                'Select Products',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: Color(0xFFBFD4F8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          if (widget.products.isNotEmpty) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                TextButton(
                  onPressed: _selectAllProducts,
                  child: const Text(
                    'Select all',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
                const Spacer(),
                if (_selectedProducts.isNotEmpty)
                  TextButton(
                    onPressed: _clearAllProducts,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: red,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (_selectedProducts.isEmpty) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECF3)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF97A5BA),
                    size: 30,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No products selected',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tap Select Products to choose items',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Filter selected products...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: primaryBlue,
                  size: 21,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9FC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
                  borderSide: const BorderSide(color: primaryBlue, width: 1.3),
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final product in _selectedProducts.where(
              (product) => _searchText.trim().isEmpty
                  ? true
                  : product.toLowerCase().contains(
                      _searchText.trim().toLowerCase(),
                    ),
            )) ...[
              _buildSelectedProductRow(product),
              const SizedBox(height: 7),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedProductRow(String product) {
    final TextEditingController controller = _qtyControllers[product]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 7, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              product,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            height: 42,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Qty',
                suffixText: 'L',
                hintStyle: const TextStyle(color: textGrey, fontSize: 11),
                suffixStyle: const TextStyle(
                  color: textGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDDE4EE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDDE4EE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryBlue, width: 1.2),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              tooltip: 'Remove product',
              padding: EdgeInsets.zero,
              onPressed: () {
                _removeProduct(product);
              },
              icon: const Icon(Icons.close_rounded, color: red, size: 19),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationTotalCard() {
    final int totalQty = _enteredTotalQuantity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E6FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allocation Total',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sum of all selected product quantities',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$totalQty Ltr',
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM COMPONENTS
  // ============================================================

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _dateField() {
    return Material(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1E7F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: primaryBlue,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDate(_selectedDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final List<String> uniqueItems = items.toSet().toList();

    String? safeValue;

    if (value != null && uniqueItems.contains(value)) {
      safeValue = value;
    } else if (uniqueItems.isNotEmpty) {
      safeValue = uniqueItems.first;
    }

    if (uniqueItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1E7F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryBlue, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No data available',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryBlue, size: 22),
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E7F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E7F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 1.3),
        ),
      ),
      items: uniqueItems.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

  String _monthName(int month) {
    const List<String> months = [
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

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }
}
