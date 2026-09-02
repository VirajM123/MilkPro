import '../models/product_model.dart';

abstract final class ProductStore {
  // Kept in memory until a product API/database is connected. Making the
  // catalogue mutable lets the product screen add and edit items while
  // preserving the existing ProductModel and all current consumers.
  static final List<ProductModel> products = <ProductModel>[
    ProductModel(
      name: 'Full Cream Milk',
      variant: '500 ml pouch',
      unit: 'Ltr',
      stock: 120,
      price: 32,
      assetPath: 'assets/img/product_full_cream_milk.png',
      category: 'Milk',
    ),
    ProductModel(
      name: 'Toned Milk',
      variant: '500 ml pouch',
      unit: 'Ltr',
      stock: 95,
      price: 28,
      assetPath: 'assets/img/product_toned_milk.png',
      category: 'Milk',
    ),
    ProductModel(
      name: 'Buffalo Milk',
      variant: '500 ml pouch',
      unit: 'Ltr',
      stock: 80,
      price: 38,
      assetPath: 'assets/img/product_buffalo_milk.png',
      category: 'Milk',
    ),
    ProductModel(
      name: 'Ghee',
      variant: '200 ml jar',
      unit: 'Pcs',
      stock: 40,
      price: 180,
      assetPath: 'assets/img/product_ghee.png',
    ),
    ProductModel(
      name: 'Curd',
      variant: '200 gm cup',
      unit: 'Pcs',
      stock: 60,
      price: 25,
      assetPath: 'assets/img/product_curd.png',
    ),
  ];
}
