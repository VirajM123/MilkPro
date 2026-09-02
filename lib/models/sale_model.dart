class SaleModel {
  const SaleModel({
    required this.id,
    required this.date,
    required this.customerName,
    required this.route,
    required this.salesman,
    required this.product,
    required this.quantity,
    required this.rate,
    required this.paymentMode,
  });

  final String id;
  final DateTime date;
  final String customerName;
  final String route;
  final String salesman;
  final String product;
  final int quantity;
  final double rate;
  final String paymentMode;

  double get total => quantity * rate;
}
