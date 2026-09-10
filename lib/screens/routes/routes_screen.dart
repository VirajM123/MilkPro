import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/access_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  static const Color primaryBlue = AppColors.primary;
  static const Color backgroundColor = AppColors.background;
  static const Color textDark = AppColors.textPrimary;
  static const Color textGrey = AppColors.textSecondary;

  final TextEditingController _searchController = TextEditingController();

  // ============================================================
  // EXISTING ROUTE DATA
  // ============================================================
final List<RouteItem> _routes = [];

final List<SalesmanOption> _salesmen = [];

bool _loading = true;

bool _loadingSalesmen = false;

  String _searchText = '';

  // ============================================================
  // ROUTE CARD COLORS
  // ============================================================
  static const List<Color> _routeColors = [
    Color(0xFF2563EB),
    Color(0xFF22C55E),
    Color(0xFFF97316),
    Color(0xFF7C3AED),
  ];

  static const List<Color> _routeLightColors = [
    Color(0xFFEFF6FF),
    Color(0xFFECFDF3),
    Color(0xFFFFF7ED),
    Color(0xFFF5F3FF),
  ];
@override
void initState() {
  super.initState();

  _loadRoutes();
  _loadSalesmen();
}
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCH LOGIC - UNCHANGED
  // ============================================================
  List<RouteItem> get _filteredRoutes {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return _routes;
    }

    return _routes.where((route) {
      return route.name.toLowerCase().contains(query) ||
          route.salesman.toLowerCase().contains(query) ||
          route.areas.join(' ').toLowerCase().contains(query);
    }).toList();
  }

  int get _activeRoutes {
    return _routes.where((route) => route.isActive).length;
  }

  int get _inactiveRoutes {
    return _routes.where((route) => !route.isActive).length;
  }

  int get _totalAreas {
    final Set<String> areas = {};

    for (final route in _routes) {
      areas.addAll(route.areas);
    }

    return areas.length;
  }

  // ============================================================
  // SCREEN
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        leadingWidth: 50,

        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF334155),
            size: 21,
          ),
        ),

        centerTitle: true,

        title: const Text(
          'Routes',
          style: TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          if (UiSession.instance.role == UserRole.admin)
            Padding(
            padding: const EdgeInsets.only(right: 12, top: 9, bottom: 9),
            child: Material(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _showAddRouteDialog,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Add Route',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          children: [
            // ==================================================
            // HERO BANNER
            // ==================================================
            _buildHeroBanner(),

            const SizedBox(height: 10),

            // ==================================================
            // SEARCH
            // ==================================================
            _buildSearchBar(),

            const SizedBox(height: 9),

            // ==================================================
            // SUMMARY
            // ==================================================
            _buildSummarySection(),

            const SizedBox(height: 10),

            // ==================================================
            // ROUTE LIST
            // ==================================================
       if (_loading)
  const Padding(
    padding:
        EdgeInsets.symmetric(
          vertical: 40,
        ),
    child: Center(
      child:
          CircularProgressIndicator(),
    ),
  )
else if (_filteredRoutes.isEmpty)
  _buildEmptyState()
else
  ...List.generate(
    _filteredRoutes.length,
    (index) {
      final route =
          _filteredRoutes[index];

      final originalIndex =
          _routes.indexOf(route);

      return Padding(
        padding:
            const EdgeInsets.only(
              bottom: 8,
            ),
        child: _buildRouteCard(
          route,
          originalIndex == -1
              ? index
              : originalIndex,
        ),
      );
    },
  ),
           
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO BANNER
  // ============================================================
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      height: 144,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5EDF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ====================================================
          // ROUTES IMAGE
          // ====================================================
          Image.asset(
            'assets/img/Routes.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: const Color(0xFFEFF6FF));
            },
          ),

          // ====================================================
          // LEFT GRADIENT
          // ====================================================
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFF0F6FF),
                  Color(0xEDF0F6FF),
                  Color(0xA5F0F6FF),
                  Color(0x20FFFFFF),
                ],
                stops: [0.0, 0.35, 0.58, 1.0],
              ),
            ),
          ),

          // ====================================================
          // HERO TEXT
          // ====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 18, 100, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Efficient Routes,\nStronger Distribution',
                  style: TextStyle(
                    color: Color(0xFF172554),
                    fontSize: 13,
                    height: 1.17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Manage your delivery routes\nand sales areas effectively.',
                  style: TextStyle(
                    color: const Color(0xFF475569).withValues(alpha: 0.95),
                    fontSize: 8.5,
                    height: 1.35,
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
  // SEARCH BAR
  // ============================================================
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFE6EBF2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,

              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },

              style: const TextStyle(
                fontSize: 11,
                color: textDark,
                fontWeight: FontWeight.w500,
              ),

              decoration: InputDecoration(
                hintText: 'Search Route',

                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),

                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 17,
                ),

                suffixIcon: _searchText.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchText = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: textGrey,
                        ),
                      ),

                border: InputBorder.none,

                enabledBorder: InputBorder.none,

                focusedBorder: InputBorder.none,

                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ======================================================
        // FILTER UI BUTTON
        // ======================================================
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFE6EBF2)),
          ),
          child: const Icon(
            Icons.filter_alt_outlined,
            color: Color(0xFF64748B),
            size: 18,
          ),
        ),
      ],
    );
  }


  // ============================================================
  // SUMMARY SECTION
  // ============================================================
  Widget _buildSummarySection() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.route_rounded,
            value: _routes.length.toString().padLeft(2, '0'),
            title: 'Total Routes',
            color: const Color(0xFF2563EB),
            lightColor: const Color(0xFFEFF6FF),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: _buildSummaryCard(
            icon: Icons.people_outline_rounded,
            value: _activeRoutes.toString().padLeft(2, '0'),
            title: 'Active',
            color: const Color(0xFF16A34A),
            lightColor: const Color(0xFFF0FDF4),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: _buildSummaryCard(
            icon: Icons.pause_circle_outline_rounded,
            value: _inactiveRoutes.toString().padLeft(2, '0'),
            title: 'Inactive',
            color: const Color(0xFFF97316),
            lightColor: const Color(0xFFFFF7ED),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: _buildSummaryCard(
            icon: Icons.map_outlined,
            value: _totalAreas.toString().padLeft(2, '0'),
            title: 'Total Areas',
            color: const Color(0xFF7C3AED),
            lightColor: const Color(0xFFF5F3FF),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================
  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String title,
    required Color color,
    required Color lightColor,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFEDF1F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),

              const SizedBox(width: 5),

              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROUTE CARD
  // ============================================================
  Widget _buildRouteCard(RouteItem route, int index) {
    final Color routeColor = _routeColors[index % _routeColors.length];

    final Color lightColor =
        _routeLightColors[index % _routeLightColors.length];

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () {
          _showEditRouteDialog(route);
        },

        borderRadius: BorderRadius.circular(13),

        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 124),

          clipBehavior: Clip.antiAlias,

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(13),

            border: Border.all(color: const Color(0xFFEDF1F6)),

            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),

          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==============================================
                // LEFT COLOR LINE
                // ==============================================
                Container(width: 3, color: routeColor),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 7, 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ======================================
                        // ROUTE ICON
                        // ======================================
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: lightColor,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.route_outlined,
                            size: 18,
                            color: routeColor,
                          ),
                        ),

                        const SizedBox(width: 10),

                        // ======================================
                        // DETAILS
                        // ======================================
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ==================================
                              // NAME + MENU
                              // ==================================
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      route.name,
                                      style: const TextStyle(
                                        color: textDark,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),

                                  if (UiSession.instance.role == UserRole.admin)
                                    SizedBox(
                                    width: 28,
                                    height: 20,
                                    child: PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,

                                      iconSize: 17,

                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        size: 17,
                                        color: Color(0xFF64748B),
                                      ),

                                    onSelected: (value) {
  if (value == 'edit') {
    _showEditRouteDialog(
      route,
    );
  }

  if (value == 'delete') {
    _deleteRoute(
      route,
    );
  }
},

                                    itemBuilder: (context) {
  return const [
    PopupMenuItem<String>(
      value: 'edit',
      child: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            size: 17,
            color:
                AppColors.primary,
          ),
          SizedBox(
            width: 8,
          ),
          Text(
            'Edit Route',
          ),
        ],
      ),
    ),

    PopupMenuDivider(),

    PopupMenuItem<String>(
      value: 'delete',
      child: Row(
        children: [
          Icon(
            Icons
                .delete_outline_rounded,
            size: 17,
            color:
                AppColors.error,
          ),
          SizedBox(
            width: 8,
          ),
          Text(
            'Delete Route',
            style: TextStyle(
              color:
                  AppColors.error,
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

                              // ==================================
                              // AREAS
                              // ==================================
                              Text(
                                route.areas.join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 8,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ==================================
                              // SALESMAN + STATUS
                              // ==================================
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Salesman',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 7,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        const SizedBox(height: 1),

                                        Text(
                                          route.salesman,
                                          style: const TextStyle(
                                            color: textDark,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildStatusChip(route.isActive),

                                      const SizedBox(height: 6),

                                      _buildAreaChip(
                                        route: route,
                                        routeColor: routeColor,
                                        lightColor: lightColor,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _deleteRoute(
  RouteItem route,
) async {
  if (route.id.trim().isEmpty) {
    _showMessage(
      'Route database ID is missing.',
    );
    return;
  }

  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Delete Route?',
        ),

        content: Text(
          'Are you sure you want to delete "${route.name}"?\n\n'
          'A route assigned to customers or used in transactions cannot be deleted.',
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child:
                const Text(
              'Cancel',
            ),
          ),

          ElevatedButton.icon(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.error,
              foregroundColor:
                  Colors.white,
            ),
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            icon: const Icon(
              Icons
                  .delete_outline_rounded,
            ),
            label:
                const Text(
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

  try {
    final response =
        await http.delete(
      Uri.parse(
        ApiConfig.routeById(
          route.id,
        ),
      ),

      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer ${ApiConfig.token}',
      },
    );

    final data =
        jsonDecode(
          response.body,
        ) as Map<String, dynamic>;

    if (!mounted) return;

    if (response.statusCode ==
            200 &&
        data['success'] == true) {
      _showMessage(
        data['message']
                ?.toString() ??
            'Route deleted successfully.',
      );

      await _loadRoutes();
    } else {
      _showMessage(
        data['message']
                ?.toString() ??
            'Unable to delete route.',
      );
    }
  } catch (error) {
    if (!mounted) return;

    _showMessage(
      'Unable to connect to backend.',
    );
  }
}

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
  // STATUS CHIP
  // ============================================================
  Widget _buildStatusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF3) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? const Color(0xFF22C55E) : const Color(0xFF64748B),
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // AREA CHIP
  // ============================================================
  Widget _buildAreaChip({
    required RouteItem route,
    required Color routeColor,
    required Color lightColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 10, color: routeColor),

          const SizedBox(width: 3),

          Text(
            '${route.areas.length} Areas',
            style: TextStyle(
              color: routeColor,
              fontSize: 7,
              fontWeight: FontWeight.w700,
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
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.route_outlined,
              color: primaryBlue,
              size: 27,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'No routes found',
            style: TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Try another search or add a new route.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textGrey, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD ROUTE
  // ORIGINAL LOGIC PRESERVED
  // ============================================================
Future<void> _showAddRouteDialog() async {
  if (_salesmen.isEmpty) {
    await _loadSalesmen();

    if (_salesmen.isEmpty) {
      if (!mounted) return;

      _showMessage(
        'No active salesman found. Please register a salesman first.',
      );

      return;
    }
  }


  final result =
      await showDialog<RouteItem>(
    context: context,
    builder: (context) =>
        _RouteFormDialog(
      salesmen: _salesmen,
    ),
  );


  if (result == null ||
      !mounted) {
    return;
  }


  await _saveRoute(result);
}

Future<void> _saveRoute(
  RouteItem route,
) async {
  try {
    final response =
        await http.post(
      Uri.parse(
        ApiConfig.routes,
      ),

      headers: {
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer ${ApiConfig.token}',
      },

      body: jsonEncode({
        'routeName':
            route.name,

        'areas':
            route.areas,

        'salesmanId':
            route.salesmanId,

        'isActive':
            route.isActive,
      }),
    );


    final data =
        jsonDecode(response.body)
            as Map<String, dynamic>;


    if (!mounted) return;


    if (
        response.statusCode == 200 ||
        response.statusCode == 201
    ) {
      _showMessage(
        data['message']?.toString() ??
            'Route added successfully.',
      );


      await _loadRoutes();

    } else {
      _showMessage(
        data['message']?.toString() ??
            'Unable to add route.',
      );
    }

  } catch (error) {
    if (!mounted) return;

    _showMessage(
      'Unable to connect to backend.',
    );
  }
}
Future<void> _showEditRouteDialog(
  RouteItem route,
) async {
  if (_salesmen.isEmpty) {
  await _loadSalesmen();

  if (!mounted) return;

  if (_salesmen.isEmpty) {
    _showMessage(
      'No active salesman found.',
    );
    return;
  }
}
  final result =
      await showDialog<RouteItem>(
    context: context,
    builder: (context) =>
        _RouteFormDialog(
      route: route,
      salesmen: _salesmen,
    ),
  );


  if (result == null ||
      !mounted) {
    return;
  }


  try {
    final response =
        await http.put(
      Uri.parse(
        '${ApiConfig.routes}/${route.id}',
      ),

      headers: {
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer ${ApiConfig.token}',
      },

      body: jsonEncode({
        'routeName':
            result.name,

        'areas':
            result.areas,

        'salesmanId':
            result.salesmanId,

        'isActive':
            result.isActive,
      }),
    );


    final data =
        jsonDecode(response.body)
            as Map<String, dynamic>;


    if (!mounted) return;


    if (
        response.statusCode == 200 &&
        data['success'] == true
    ) {
      _showMessage(
        'Route updated successfully.',
      );

      await _loadRoutes();

    } else {
      _showMessage(
        data['message']?.toString() ??
            'Unable to update route.',
      );
    }

  } catch (_) {
    if (!mounted) return;

    _showMessage(
      'Unable to update route.',
    );
  }
}

Future<void> _loadRoutes() async {
  if (mounted) {
    setState(() {
      _loading = true;
    });
  }

  try {
    final response =
        await http.get(
      Uri.parse(
        ApiConfig.routes,
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


    if (
        response.statusCode == 200 &&
        data['success'] == true
    ) {
      final records =
          data['data']
              as List<dynamic>? ??
          [];


      final routes =
          records.map((item) {
        final map =
            item as Map<String, dynamic>;

        return RouteItem(
          id:
              map['_id']?.toString() ??
                  '',

          routeId:
              map['routeId']
                      ?.toString() ??
                  '',

          name:
              map['routeName']
                      ?.toString() ??
                  '',

          areas:
              (map['areas']
                          as List<dynamic>? ??
                      [])
                  .map(
                    (area) =>
                        area.toString(),
                  )
                  .toList(),

          salesmanId:
              map['salesmanId']
                      ?.toString() ??
                  '',

          salesman:
              map['salesmanName']
                      ?.toString() ??
                  '',

          isActive:
              map['isActive'] !=
                  false,
        );
      }).toList();


      setState(() {
        _routes
          ..clear()
          ..addAll(routes);
      });

    } else {
      _showMessage(
        data['message']?.toString() ??
            'Unable to load routes.',
      );
    }

  } catch (error) {
    if (!mounted) return;

    _showMessage(
      'Unable to load routes from server.',
    );

  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}
Future<void> _loadSalesmen() async {
  if (mounted) {
    setState(() {
      _loadingSalesmen = true;
    });
  }

  try {
    final response =
        await http.get(
      Uri.parse(
        ApiConfig.salesmen,
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


    if (
        response.statusCode == 200 &&
        data['success'] == true
    ) {
      final records =
          data['data']
              as List<dynamic>? ??
          [];


      final salesmen =
          records.map((item) {
        final map =
            item as Map<String, dynamic>;

        return SalesmanOption(
          id:
              map['_id']?.toString() ??
                  '',

          salesmanId:
              map['salesmanId']
                      ?.toString() ??
                  '',

          name:
              map['name']?.toString() ??
                  '',
        );
      }).toList();


      setState(() {
        _salesmen
          ..clear()
          ..addAll(salesmen);
      });
    }

  } catch (_) {
    if (!mounted) return;

    _showMessage(
      'Unable to load salesmen.',
    );

  } finally {
    if (mounted) {
      setState(() {
        _loadingSalesmen =
            false;
      });
    }
  }
}
  // ============================================================
  // EDIT ROUTE
  // ORIGINAL LOGIC PRESERVED
  // ============================================================
 
}

// ============================================================
// ROUTE FORM DIALOG
// ORIGINAL ADD / EDIT LOGIC PRESERVED
// ============================================================
class _RouteFormDialog extends StatefulWidget {
final RouteItem? route;

final List<SalesmanOption> salesmen;

const _RouteFormDialog({
  this.route,
  required this.salesmen,
});

  @override
  State<_RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends State<_RouteFormDialog> {
  late final TextEditingController _routeController;

  late final TextEditingController _areasController;

String? _selectedSalesmanId;

  late bool _isActive;


  @override
  void initState() {
    super.initState();

    _routeController = TextEditingController(text: widget.route?.name ?? '');

    _areasController = TextEditingController(
      text: widget.route?.areas.join(', ') ?? '',
    );

final routeSalesmanId =
    widget.route?.salesmanId ?? '';

final salesmanExists =
    widget.salesmen.any(
  (salesman) =>
      salesman.salesmanId ==
      routeSalesmanId,
);

_selectedSalesmanId =
    salesmanExists
        ? routeSalesmanId
        : null;

    _isActive = widget.route?.isActive ?? true;
  }

  @override
  void dispose() {
    _routeController.dispose();
    _areasController.dispose();


    super.dispose();
  }

  // ============================================================
  // SAVE LOGIC
  // ============================================================
void _save() {
  final name =
      _routeController.text.trim();

  final areas =
      _areasController.text
          .split(',')
          .map(
            (area) => area.trim(),
          )
          .where(
            (area) => area.isNotEmpty,
          )
          .toList();

  if (name.isEmpty) {
    _showMessage(
      'Please enter route name',
    );
    return;
  }

  if (areas.isEmpty) {
    _showMessage(
      'Please enter at least one area',
    );
    return;
  }

  if (_selectedSalesmanId == null ||
      _selectedSalesmanId!.isEmpty) {
    _showMessage(
      'Please select salesman',
    );
    return;
  }

  final selectedSalesman =
      widget.salesmen.firstWhere(
    (salesman) =>
        salesman.salesmanId ==
        _selectedSalesmanId,
  );

  Navigator.of(context).pop(
    RouteItem(
      id: widget.route?.id ?? '',
      routeId:
          widget.route?.routeId ?? '',
      name: name,
      areas: areas,
      salesmanId:
          selectedSalesman.salesmanId,
      salesman:
          selectedSalesman.name,
      isActive:
          _isActive,
    ),
  );
}
  // ============================================================
  // MESSAGE
  // ============================================================
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // DIALOG
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.route != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),

      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 6),

      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),

      title: Text(
        isEdit ? 'Edit Route' : 'Add Route',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111827),
        ),
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(
              controller: _routeController,
              label: 'Route Name',
              hint: 'Example: Route A',
            ),

            const SizedBox(height: 12),

            _field(
              controller: _areasController,
              label: 'Areas',
              hint: 'Area 1, Area 2, Area 3',
            ),

            const SizedBox(height: 12),

      DropdownButtonFormField<String>(
  value: _selectedSalesmanId,

  isExpanded: true,

  decoration: InputDecoration(
    labelText: 'Salesman',

    prefixIcon:
        const Icon(
      Icons.badge_outlined,
    ),

    filled: true,

    fillColor:
        const Color(
          0xFFF8FAFC,
        ),

    border:
        OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(
            10,
          ),
    ),
  ),

  items:
      widget.salesmen.map(
    (salesman) {
      return DropdownMenuItem<String>(
        value:
            salesman.salesmanId,

        child: Text(
          '${salesman.name} (${salesman.salesmanId})',
          overflow:
              TextOverflow.ellipsis,
        ),
      );
    },
  ).toList(),

  onChanged: (value) {
    setState(() {
      _selectedSalesmanId =
          value;
    });
  },
),

            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,

              activeThumbColor: const Color(0xFF2563EB),

              title: const Text(
                'Active Route',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),

              value: _isActive,

              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: _save,

          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),

          child: Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================
  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        isDense: true,

        filled: true,

        fillColor: const Color(0xFFF8FAFC),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
        ),
      ),
    );
  }
}

// ============================================================
// ROUTE MODEL
// REQUIRED BY ROUTES SCREEN + DIALOG
// ============================================================
class RouteItem {
  final String id;

  final String routeId;

  final String name;

  final List<String> areas;

  final String salesmanId;

  final String salesman;

  final bool isActive;


  const RouteItem({
    this.id = '',

    this.routeId = '',

    required this.name,

    required this.areas,

    this.salesmanId = '',

    required this.salesman,

    required this.isActive,
  });
}
class SalesmanOption {
  final String id;

  final String salesmanId;

  final String name;


  const SalesmanOption({
    required this.id,

    required this.salesmanId,

    required this.name,
  });
}