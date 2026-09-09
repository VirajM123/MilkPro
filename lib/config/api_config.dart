class ApiConfig {
  static const String baseUrl =
      'https://milkpro.onrender.com';


// static const String baseUrl =
//       'http://localhost:5000';
  // Authentication
  static const String register =
      '$baseUrl/api/auth/register';

  static const String login =
      '$baseUrl/api/auth/login';

  // Customer
  static const String customers =
      '$baseUrl/api/customers';

  static String customerById(
    String id,
  ) =>
      '$customers/$id';

  // Routes
  static const String routes =
      '$baseUrl/api/routes';
      static String routeById(
  String id,
) =>
    '$routes/$id';

  // Salesmen
// Salesmen
static const String salesmen =
    '$baseUrl/api/salesmen';

static String salesmanById(
  String salesmanId,
) =>
    '$salesmen/$salesmanId';

// Current User Profile
static const String profile =
    '$baseUrl/api/profile';

static const String profilePassword =
    '$baseUrl/api/profile/password';

  // Products
  static const String products =
      '$baseUrl/api/products';

static String productById(
  String id,
) =>
    '$products/$id';
  // Suppliers
  static const String suppliers =
      '$baseUrl/api/suppliers';

  // Purchases
  static const String purchases =
      '$baseUrl/api/purchases';

  // Stock
  static const String stock =
      '$baseUrl/api/stock';

  // Customer Rates
  static const String customerRates =
      '$baseUrl/api/customer-rates';

  // Sales
  static const String sales =
      '$baseUrl/api/sales';

  // Collections
  static const String collections =
      '$baseUrl/api/collections';

  // Ledger
  static const String ledger =
      '$baseUrl/api/ledger';

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

  // Current session
  static String token = '';
  static String farmId = '';
}