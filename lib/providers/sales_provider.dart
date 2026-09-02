import '../models/sale_model.dart';

/// Lightweight in-memory sales store used by the current local-data screens.
/// It can be replaced by an API-backed repository without changing the UI.
class SalesStore {
  SalesStore._();

  static final List<SaleModel> sales = <SaleModel>[];

  static void add(SaleModel sale) {
    sales.insert(0, sale);
  }
}
