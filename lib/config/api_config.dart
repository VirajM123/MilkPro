class ApiConfig {
  // ============================================================
  // BASE URL
  // ============================================================

  // Local development:
  static const String baseUrl = 'http://localhost:5000';

  // Production:
  // static const String baseUrl =
  //     'https://milkpro.onrender.com';


  // ============================================================
  // AUTHENTICATION
  // ============================================================

  static const String register =
      '$baseUrl/api/auth/register';

  static const String login =
      '$baseUrl/api/auth/login';


  // ============================================================
  // CURRENT USER PROFILE
  // ============================================================

  static const String profile =
      '$baseUrl/api/profile';

  static const String profilePassword =
      '$baseUrl/api/profile/password';


  // ============================================================
  // CUSTOMERS
  // ============================================================

  static const String customers =
      '$baseUrl/api/customers';

  static String customerById(
    String id,
  ) =>
      '$customers/$id';


  // ============================================================
  // ROUTES
  // ============================================================

  static const String routes =
      '$baseUrl/api/routes';

  static String routeById(
    String id,
  ) =>
      '$routes/$id';


  // ============================================================
  // SALESMEN
  // ============================================================

  static const String salesmen =
      '$baseUrl/api/salesmen';

  static String salesmanById(
    String salesmanId,
  ) =>
      '$salesmen/$salesmanId';


  // ============================================================
  // PRODUCTS
  // ============================================================

  static const String products =
      '$baseUrl/api/products';

  static String productById(
    String id,
  ) =>
      '$products/$id';


  // ============================================================
  // SUPPLIERS
  // ============================================================

  static const String suppliers =
      '$baseUrl/api/suppliers';


  // ============================================================
  // PURCHASES
  // ============================================================

  static const String purchases =
      '$baseUrl/api/purchases';


  // ============================================================
  // STOCK
  // ============================================================

  static const String stock =
      '$baseUrl/api/stock';


  // ============================================================
  // CUSTOMER RATES
  // ============================================================

  static const String customerRates =
      '$baseUrl/api/customer-rates';


  // ============================================================
  // SALES
  // ============================================================

  static const String sales =
      '$baseUrl/api/sales';

  static String saleById(
    String saleId,
  ) =>
      '$sales/$saleId';


  // ============================================================
  // SALESMAN STOCK
  // IMPORTANT:
  // This now represents current business-day allocation stock.
  // ============================================================

  static const String salesmanStockMy =
      '$baseUrl/api/salesman-stock/my';


  // ============================================================
  // ALLOCATIONS
  // ============================================================

  static const String allocations =
      '$baseUrl/api/allocations';

  static String allocationById(
    String allocationId,
  ) =>
      '$allocations/$allocationId';

  static String allocationCancel(
    String allocationId,
  ) =>
      '$allocations/$allocationId/cancel';

  static String allocationReturn(
    String allocationId,
  ) =>
      '$allocations/$allocationId/return';


  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String collections =
      '$baseUrl/api/collections';


  // ============================================================
  // LEDGER
  // ============================================================

  static const String ledger =
      '$baseUrl/api/ledger';


  // ============================================================
  // CUSTOMER RELATED TRANSACTIONS
  // ============================================================

  static String customerSales(
    String customerId,
  ) =>
      '$sales?customerId=$customerId';

  static String customerCollections(
    String customerId,
  ) =>
      '$collections?customerId=$customerId';

  static String customerLedger(
    String customerId,
  ) =>
      '$ledger?type=customer&partyId=$customerId';


  // ============================================================
  // SALESMAN DEFAULT PERMISSIONS
  // ============================================================

  static const String salesmanDefaultPermissions =
      '$baseUrl/api/settings/salesman-permissions';


  // ============================================================
  // SALES & COLLECTION HISTORY
  // ============================================================

  static const String historySummary =
      '$baseUrl/api/history/sales-collection-summary';

  static const String historySalesmanDetails =
      '$baseUrl/api/history/salesman-details';


  // ============================================================
  // CURRENT SESSION
  // ============================================================

  static String token = '';

  static String farmId = '';


  // ============================================================
  // COMMON AUTH HEADERS
  //
  // Use this instead of repeating Authorization + Content-Type
  // throughout every screen.
  // ============================================================

  static Map<String, String> get authHeaders =>
      <String, String>{
        'Content-Type': 'application/json',
        if (token.trim().isNotEmpty)
          'Authorization':
              'Bearer ${token.trim()}',
      };
}