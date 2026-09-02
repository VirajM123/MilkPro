class ProductModel {
  const ProductModel({
    required this.name,
    required this.variant,
    required this.unit,
    required this.stock,
    required this.price,
    required this.assetPath,
    this.category = 'Dairy',
    this.lowStockLevel = 20,
    this.isActive = true,
  });

  final String name;
  final String variant;
  final String unit;
  final double stock;
  final double price;
  final String assetPath;
  final String category;
  final double lowStockLevel;
  final bool isActive;

  bool get isLowStock => stock <= lowStockLevel;
}
