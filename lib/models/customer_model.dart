class CustomerModel {
  const CustomerModel({
    required this.name,
    required this.mobile,
    required this.route,
    this.balance = 0,
    this.isActive = true,
  });

  final String name;
  final String mobile;
  final String route;
  final double balance;
  final bool isActive;
}
