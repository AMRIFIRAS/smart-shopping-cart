import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_shopping_cart/app.dart';
import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/services/barcode_scanner.dart';
import 'package:smart_shopping_cart/services/cart_controller.dart';
import 'package:smart_shopping_cart/services/product_catalog.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
    const Size(1440, 1000),
  ]) {
    testWidgets('Complete shopping flow at ${size.width} x ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cart = CartController(
        catalog: ProductCatalog(demoProducts),
        scanner: MockBarcodeScanner(),
      );
      addTearDown(cart.dispose);
      await tester.pumpWidget(SmartShoppingApp(controller: cart));
      await tester.pumpAndSettle();
      expect(find.text('Your everyday shop,\nreimagined.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.byKey(const Key('nav-cart')));
      expect(find.text('Your cart is feeling light'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('nav-products')));
      expect(find.text('5 essentials to explore'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(Key('product-${demoProducts[0].barcode}')),
      );
      expect(find.text('A look inside'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('details-add')));
      expect(cart.totalHalalas, 650);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('nav-scan')));
      await tester.ensureVisible(find.byKey(const Key('barcode-input')));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        '9999999999999',
      );
      await tapVisible(tester, find.byKey(const Key('scan-barcode')));
      expect(cart.scanFeedback?.success, isFalse);
      expect(cart.totalQuantity, 1);
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        demoProducts[0].barcode,
      );
      await tapVisible(tester, find.byKey(const Key('scan-barcode')));
      expect(cart.totalQuantity, 2);
      await tapVisible(
        tester,
        find.byKey(Key('scan-${demoProducts[0].barcode}')),
      );
      expect(cart.totalQuantity, 3);
      await tapVisible(
        tester,
        find.byKey(Key('scan-${demoProducts[2].barcode}')),
      );
      expect(cart.totalHalalas, 2050);
      await tapVisible(tester, find.byKey(const Key('nav-cart')));
      await tapVisible(
        tester,
        find.byKey(Key('increase-${demoProducts[0].barcode}')),
      );
      expect(cart.totalHalalas, 2700);
      await tapVisible(
        tester,
        find.byKey(Key('decrease-${demoProducts[0].barcode}')),
      );
      expect(cart.totalHalalas, 2050);
      await tapVisible(
        tester,
        find.byKey(Key('remove-${demoProducts[2].barcode}')),
      );
      expect(cart.totalHalalas, 1950);
      await tapVisible(tester, find.byKey(const Key('go-checkout')));
      expect(find.text('Order summary'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('complete-checkout')));
      expect(find.byKey(const Key('receipt-number')), findsOneWidget);
      expect(find.text('SAR 19.50'), findsNWidgets(2));
      expect(find.text('3 × SAR 6.50'), findsOneWidget);
      expect(cart.isEmpty, isTrue);
      await tapVisible(tester, find.byKey(const Key('new-trip')));
      expect(find.byKey(const Key('start-shopping')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('nav-cart')));
      expect(find.text('Your cart is feeling light'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('search and category filters show the expected products', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartShoppingApp());
    await tapVisible(tester, find.byKey(const Key('nav-products')));
    await tester.enterText(find.byType(TextField), 'water');
    await tester.pumpAndSettle();
    expect(find.text('1 essentials to explore'), findsOneWidget);
    expect(find.text('Berain Water'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'unavailable');
    await tester.pumpAndSettle();
    expect(
      find.text('No products found. Try another name or category.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '');
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Snacks'));
    expect(find.text('2 essentials to explore'), findsOneWidget);
    expect(find.text('Twix Chocolate'), findsOneWidget);
    expect(find.text('Doritos Chips'), findsOneWidget);
  });
}
