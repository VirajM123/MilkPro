class ApiConfig {
  static const String baseUrl = 'http://localhost:5000';

  // Authentication
  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';

  // Customer Master
  static const String customers = '$baseUrl/api/customers';

// Route Master
static const String routes = '$baseUrl/api/routes';

// Salesmen list for dropdown
static const String salesmen = '$baseUrl/api/salesmen';
// Product Master
static const String products = '$baseUrl/api/products';
static const String suppliers =
    '$baseUrl/api/suppliers';
    static const String purchases =
    '$baseUrl/api/purchases';

static const String stock =
    '$baseUrl/api/stock';
    // Customer Rate Master
static const String customerRates =
    '$baseUrl/api/customer-rates';
    // Sales
static const String sales =
    '$baseUrl/api/sales';
  // Current logged-in session
  static String token = '';
  static String farmId = '';
}