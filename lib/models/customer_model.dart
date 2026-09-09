class CustomerModel {
  const CustomerModel({
    this.id = '',
    this.customerId = '',
    required this.name,
    required this.mobile,
    required this.route,
    required this.balance,
    this.isActive = true,
  });

  /// MongoDB _id
  final String id;

  /// Your application customer ID
  /// Example: CUS000001
  final String customerId;

  final String name;
  final String mobile;
  final String route;
  final double balance;
  final bool isActive;

  factory CustomerModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CustomerModel(
      id: json['_id']?.toString() ?? '',
      customerId:
          json['customerId']?.toString() ?? '',
      name:
          json['name']?.toString() ?? '',
      mobile:
          json['mobile']?.toString() ?? '',
      route:
          json['route']?.toString() ?? '',
      balance:
          double.tryParse(
            json['balance']?.toString() ?? '0',
          ) ??
          0,
      isActive:
          json['isActive'] != false,
    );
  }

  CustomerModel copyWith({
    String? id,
    String? customerId,
    String? name,
    String? mobile,
    String? route,
    double? balance,
    bool? isActive,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      customerId:
          customerId ?? this.customerId,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      route: route ?? this.route,
      balance: balance ?? this.balance,
      isActive:
          isActive ?? this.isActive,
    );
  }
}