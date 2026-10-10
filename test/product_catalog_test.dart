import 'package:flutter_test/flutter_test.dart';
import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/services/product_catalog.dart';

void main() {
  final catalog = ProductCatalog(demoProducts);
  test('all five demo barcodes match their exact products', () {
    expect(catalog.products.length, 5);
    expect(catalog.products.map((p) => p.barcode).toSet().length, 5);
    for (final product in demoProducts) {
      expect(catalog.findByBarcode(product.barcode), same(product));
      expect(catalog.findByBarcode(' ${product.barcode}\n'), same(product));
    }
  });
  test('unknown or partial barcodes do not match', () {
    expect(catalog.findByBarcode('6281000000000'), isNull);
    expect(catalog.findByBarcode('628100000001'), isNull);
    expect(catalog.findByBarcode(''), isNull);
  });
  test('demo codes are valid EAN-13 examples', () {
    for (final product in demoProducts) {
      expect(product.barcode, matches(RegExp(r'^\d{13}$')));
      final digits = product.barcode.split('').map(int.parse).toList();
      var sum = 0;
      for (var i = 0; i < 12; i++) {
        sum += digits[i] * (i.isEven ? 1 : 3);
      }
      expect((10 - sum % 10) % 10, digits.last);
    }
  });
}
