import '../models/customer_model.dart';
import '../models/customer_product_rate_model.dart';
import '../models/product_model.dart';
import 'customer_provider.dart';
import 'product_provider.dart';

abstract final class CustomerRateStore {
  static final Map<String, CustomerProductRateModel> _rates = {};

  static String customerKey(CustomerModel customer) => customer.mobile;

  static String productKey(ProductModel product) =>
      '${product.name}|${product.variant}';

  static String _key(String customerKey, String productKey) =>
      '$customerKey::$productKey';

  static void syncCatalogue() {
    for (final customer in CustomerStore.customers) {
      for (final product in ProductStore.products) {
        final customerId = customerKey(customer);
        final productId = productKey(product);
        _rates.putIfAbsent(
          _key(customerId, productId),
          () => CustomerProductRateModel(
            customerKey: customerId,
            productKey: productId,
          ),
        );
      }
    }
  }

  static CustomerProductRateModel rateFor(
    CustomerModel customer,
    ProductModel product,
  ) {
    syncCatalogue();
    return _rates[_key(customerKey(customer), productKey(product))]!;
  }

  static void setCustomRate(
    CustomerModel customer,
    ProductModel product,
    double rate,
  ) {
    final current = rateFor(customer, product);
    _rates[_key(current.customerKey, current.productKey)] = current.copyWith(
      customRate: rate,
      updatedAt: DateTime.now(),
    );
  }

  static void useDefaultRate(CustomerModel customer, ProductModel product) {
    final current = rateFor(customer, product);
    _rates[_key(current.customerKey, current.productKey)] = current.copyWith(
      clearCustomRate: true,
      updatedAt: DateTime.now(),
    );
  }

  static int customRateCountFor(CustomerModel customer) {
    syncCatalogue();
    return ProductStore.products
        .where((product) => !rateFor(customer, product).usesDefaultRate)
        .length;
  }
}
