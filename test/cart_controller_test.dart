import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/models/product.dart';
import 'package:smart_shopping_cart/services/barcode_scanner.dart';
import 'package:smart_shopping_cart/services/cart_controller.dart';
import 'package:smart_shopping_cart/services/product_catalog.dart';

void main() {
  late CartController cart;
  setUp(
    () => cart = CartController(
      catalog: ProductCatalog(demoProducts),
      scanner: MockBarcodeScanner(),
    ),
  );
  tearDown(() => cart.dispose());

  test('empty cart has zero totals and cannot check out', () {
    expect(cart.isEmpty, isTrue);
    expect(cart.totalQuantity, 0);
    expect(cart.totalHalalas, 0);
    expect(cart.checkout, throwsStateError);
  });

  test('mixed products have exact line subtotals, quantity and SAR totals', () {
    cart.add(demoProducts[0]);
    cart.add(demoProducts[0]);
    cart.add(demoProducts[3]);
    expect(cart.items.length, 2);
    expect(cart.items.first.subtotalHalalas, 1300);
    expect(cart.totalQuantity, 3);
    expect(cart.totalHalalas, 1650);
    expect(money(cart.totalHalalas), 'SAR 16.50');
  });

  test(
    'decreasing and removing items updates totals without negative quantities',
    () {
      cart.add(demoProducts[0]);
      cart.add(demoProducts[0]);
      cart.add(demoProducts[2]);
      cart.decrease(demoProducts[0]);
      expect(cart.totalHalalas, 750);
      expect(cart.totalQuantity, 2);
      cart.decrease(demoProducts[0]);
      cart.decrease(demoProducts[0]);
      expect(cart.quantityOf(demoProducts[0]), 0);
      expect(cart.totalHalalas, 100);
      cart.remove(demoProducts[2]);
      cart.remove(demoProducts[2]);
      expect(cart.isEmpty, isTrue);
      expect(cart.totalQuantity, 0);
    },
  );

  test('repeated scanner events increase a single matching line', () async {
    await cart.scan('  ${demoProducts[0].barcode}  ');
    await cart.scan(demoProducts[0].barcode);
    expect(cart.items.length, 1);
    expect(cart.quantityOf(demoProducts[0]), 2);
    expect(cart.totalHalalas, 1300);
    expect(cart.scanFeedback?.success, isTrue);
  });

  test(
    'unknown, blank and malformed barcodes leave an existing cart unchanged',
    () async {
      cart.add(demoProducts[0]);
      for (final value in ['9999999999999', '', '   ', '6281', 'letters']) {
        await cart.scan(value);
        expect(cart.scanFeedback?.success, isFalse);
        expect(cart.totalQuantity, 1);
        expect(cart.totalHalalas, 650);
      }
    },
  );

  test('checkout creates an immutable dated receipt and clears the cart', () {
    cart.add(demoProducts[0]);
    cart.add(demoProducts[0]);
    cart.add(demoProducts[2]);
    final date = DateTime(2026, 9, 14, 10, 30);
    final order = cart.checkout(now: date);
    expect(order.createdAt, date);
    expect(order.number, startsWith('SC-'));
    expect(order.totalQuantity, 3);
    expect(order.totalHalalas, 1400);
    expect(cart.isEmpty, isTrue);
    expect(() => order.items.clear(), throwsUnsupportedError);
    cart.add(demoProducts[3]);
    final nextOrder = cart.checkout(now: date);
    expect(nextOrder.number, isNot(order.number));
    expect(order.totalHalalas, 1400);
    expect(order.items.first.quantity, 2);
  });

  test('new trip resets cart and scan feedback', () async {
    await cart.scan(demoProducts[0].barcode);
    cart.startNewTrip();
    expect(cart.isEmpty, isTrue);
    expect(cart.scanFeedback, isNull);
  });

  test(
    'barcode events arriving through the abstraction update the cart',
    () async {
      final scanner = EventScanner();
      final eventCart = CartController(
        catalog: ProductCatalog(demoProducts),
        scanner: scanner,
      );
      scanner.events.add(demoProducts[4].barcode);
      expect(eventCart.totalHalalas, 400);
      scanner.events.addError(StateError('connection lost'));
      expect(eventCart.scanFeedback?.success, isFalse);
      expect(eventCart.totalHalalas, 400);
      eventCart.dispose();
    },
  );
}

class EventScanner implements BarcodeScanner {
  final events = StreamController<String>.broadcast(sync: true);
  @override
  Stream<String> get barcodes => events.stream;
  @override
  Future<void> submitBarcode(String barcode) async => events.add(barcode);
  @override
  void dispose() => events.close();
}
