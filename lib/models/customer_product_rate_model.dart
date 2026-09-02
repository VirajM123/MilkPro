class CustomerProductRateModel {
  const CustomerProductRateModel({
    required this.customerKey,
    required this.productKey,
    this.customRate,
    this.updatedAt,
  });

  final String customerKey;
  final String productKey;
  final double? customRate;
  final DateTime? updatedAt;

  bool get usesDefaultRate => customRate == null;

  double effectiveRate(double defaultRate) => customRate ?? defaultRate;

  CustomerProductRateModel copyWith({
    double? customRate,
    bool clearCustomRate = false,
    DateTime? updatedAt,
  }) {
    return CustomerProductRateModel(
      customerKey: customerKey,
      productKey: productKey,
      customRate: clearCustomRate ? null : customRate ?? this.customRate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
