import '../models/product.dart';
import 'product_links.dart';

class ProductCatalog {
  ProductCatalog(List<Product> products, {ProductLinks? links})
    : products = List.unmodifiable(products),
      links = links ?? ProductLinks.forApplication();
  final List<Product> products;
  final ProductLinks links;
  Product? findByPublicQr(String payload) {
    final id = links.idFromUrl(payload);
    return id == null ? null : findById(id);
  }

  Product? findById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Product? findByQr(String payload) {
    // Original internal-code adapter retained for the existing regression tests.
    // Public URL scans use findByPublicQr and never auto-add through this adapter.
    final value = payload.trim();
    if (!RegExp(r'^SMARTCART:P\d{3}$').hasMatch(value)) return null;
    return findById(value.substring(10));
  }

  Product? findByBarcode(String barcode) {
    final normalized = barcode.trim();
    for (final product in products) {
      if (product.barcode == normalized) return product;
    }
    return null;
  }
}
