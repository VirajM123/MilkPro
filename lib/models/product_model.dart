class ProductModel {
  const ProductModel({
    this.id = '',
    this.productId = '',
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

  // MongoDB document _id
  final String id;

  // Our generated product ID, for example PRD123456
  final String productId;

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