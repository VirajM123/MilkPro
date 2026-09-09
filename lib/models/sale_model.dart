class SaleProductModel {
  const SaleProductModel({
    required this.productId,
    required this.productName,
    required this.variant,
    required this.unit,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.defaultRate = 0,
    this.rateSource = 'PRODUCT_RATE',
  });

  final String productId;
  final String productName;
  final String variant;
  final String unit;

  final int quantity;

  final double defaultRate;
  final double rate;

  final String rateSource;

  final double amount;

  bool get hasSpecialRate =>
      rateSource.toUpperCase() == 'CUSTOMER_RATE';
}


// ============================================================
// SALE MODEL
// ============================================================

class SaleModel {
  const SaleModel({
    required this.id,
    required this.saleId,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.route,
    required this.salesman,
    required this.products,
    required this.paymentMode,
    required this.grandTotal,
    required this.status,
    this.payments = const <Map<String, dynamic>>[],
    this.paidAmount = 0,
    this.outstandingAmount = 0,
    this.paymentStatus = 'PAID',
    this.godown = '',
  });

  // ============================================================
  // SALE / BILL REFERENCE
  // ============================================================

  final String id;
  final String saleId;

  final DateTime date;

  // ============================================================
  // CUSTOMER
  // ============================================================

  final String customerId;
  final String customerName;
  final String customerMobile;

  final String route;
  final String salesman;

  // ============================================================
  // PRODUCTS
  // ============================================================

  final List<SaleProductModel> products;

  // ============================================================
  // PAYMENT
  // ============================================================

  final String paymentMode;

  final List<Map<String, dynamic>> payments;

  final double paidAmount;

  final double outstandingAmount;

  final String paymentStatus;

  // ============================================================
  // TOTALS
  // ============================================================

  final double grandTotal;

  final String status;

  final String godown;

  // ============================================================
  // BILL TOTAL HELPERS
  // ============================================================

  int get itemCount => products.length;

  int get totalQuantity {
    return products.fold<int>(
      0,
      (int sum, SaleProductModel item) {
        return sum + item.quantity;
      },
    );
  }

  double get total => grandTotal;

  bool get isCancelled =>
      status.toUpperCase() == 'CANCELLED';

  // ============================================================
  // PAYMENT HELPERS
  // ============================================================

  double paymentAmountFor(String mode) {
    for (final Map<String, dynamic> payment in payments) {
      final String paymentModeValue =
          payment['mode']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (paymentModeValue ==
          mode.trim().toLowerCase()) {
        return double.tryParse(
              payment['amount']?.toString() ?? '0',
            ) ??
            0.0;
      }
    }

    return 0.0;
  }

  double get cashAmount =>
      paymentAmountFor('Cash');

  double get upiAmount =>
      paymentAmountFor('UPI');

  double get bankTransferAmount =>
      paymentAmountFor('Bank Transfer');

  bool get isPaid =>
      paymentStatus.toUpperCase() == 'PAID';

  bool get isPartial =>
      paymentStatus.toUpperCase() == 'PARTIAL';

  bool get isCredit =>
      paymentStatus.toUpperCase() == 'CREDIT';

  // ============================================================
  // PRODUCT DISPLAY
  // ============================================================

  String get productSummary {
    if (products.isEmpty) {
      return 'No Products';
    }

    final String firstProduct =
        products.first.productName.trim();

    if (products.length == 1) {
      return firstProduct;
    }

    return '$firstProduct + ${products.length - 1} more';
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  //
  // Existing PDF / other screens may still use:
  //
  // sale.product
  // sale.quantity
  // sale.rate
  // ============================================================

  String get product {
    if (products.isEmpty) {
      return '';
    }

    return products.first.productName;
  }

  int get quantity => totalQuantity;

  double get rate {
    if (products.isEmpty) {
      return 0.0;
    }

    return products.first.rate;
  }
}