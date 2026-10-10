import 'package:flutter_test/flutter_test.dart';
import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/models/account.dart';
import 'package:smart_shopping_cart/services/app_session.dart';
import 'package:smart_shopping_cart/services/auth_service.dart';
import 'package:smart_shopping_cart/services/cart_controller.dart';
import 'package:smart_shopping_cart/services/local_store.dart';
import 'package:smart_shopping_cart/services/product_catalog.dart';
import 'package:smart_shopping_cart/services/qr_scan_service.dart';

import 'support/fake_auth.dart';

CartController makeCart([LocalStore? store]) => CartController(
  catalog: ProductCatalog(demoProducts),
  scanner: LocalQrScanService(),
  store: store,
);

void main() {
  test(
    'five unique QR payloads match exactly; malformed codes never match',
    () {
      final catalog = ProductCatalog(demoProducts);
      expect(demoProducts.map((p) => p.id).toSet().length, 5);
      for (var i = 0; i < 5; i++) {
        final product = demoProducts[i];
        expect(product.qrPayload, 'SMARTCART:P00${i + 1}');
        expect(catalog.findByQr(' ${product.qrPayload}\n'), same(product));
      }
      for (final invalid in [
        '',
        'SMARTCART:P999',
        'smartcart:P001',
        'SMARTCART:P01',
        'https://example.com',
        'SMARTCART:P001extra',
        demoProducts[0].barcode,
      ]) {
        expect(catalog.findByQr(invalid), isNull, reason: invalid);
      }
    },
  );

  test(
    'continuous camera frames add once, absence permits another scan',
    () async {
      final cart = makeCart();
      addTearDown(cart.dispose);
      final start = DateTime(2026);
      for (var frame = 0; frame < 100; frame++) {
        await cart.scanCamera(
          'SMARTCART:P001',
          now: start.add(Duration(milliseconds: frame * 200)),
        );
      }
      expect(cart.totalQuantity, 1);
      expect(
        await cart.scanCamera(
          'SMARTCART:P002',
          now: start.add(const Duration(seconds: 20)),
        ),
        isTrue,
      );
      expect(
        await cart.scanCamera(
          'SMARTCART:P001',
          now: start.add(const Duration(seconds: 22)),
        ),
        isTrue,
      );
      expect(cart.quantityOf(demoProducts[0]), 2);
      expect(cart.totalHalalas, 2000);
    },
  );

  test(
    'manual QR repeat is immediate; invalid camera payload changes no totals',
    () async {
      final cart = makeCart();
      addTearDown(cart.dispose);
      await cart.scan('SMARTCART:P004');
      await cart.scan('SMARTCART:P004');
      expect(cart.totalQuantity, 2);
      expect(cart.totalHalalas, 700);
      expect(await cart.scanCamera(demoProducts[0].barcode), isFalse);
      expect(await cart.scanCamera('SMARTCART:P999'), isFalse);
      expect(cart.scanFeedback?.success, isFalse);
      expect(cart.totalHalalas, 700);
    },
  );

  test(
    'guest cart survives reload and checkout persists an empty cart',
    () async {
      final store = MemoryStore();
      final cart = makeCart(store);
      await cart.scan('SMARTCART:P001');
      await cart.scan('SMARTCART:P005');
      await cart.saved;
      cart.dispose();
      final restored = makeCart(store);
      expect(restored.totalHalalas, 1050);
      final receipt = restored.checkout(now: DateTime(2026, 9, 14));
      await restored.saved;
      restored.dispose();
      expect(receipt.totalQuantity, 2);
      expect(receipt.totalHalalas, 1050);
      final empty = makeCart(store);
      expect(empty.isEmpty, isTrue);
      empty.dispose();
    },
  );

  test(
    'corrupt local cart is ignored and cannot inject invalid quantities',
    () async {
      final store = MemoryStore();
      await store.write(
        'smartcart.cart.v1',
        '[{"id":"P001","quantity":-5},{"id":"P999","quantity":1}]',
      );
      final cart = makeCart(store);
      expect(cart.isEmpty, isTrue);
      cart.dispose();
      await store.write('smartcart.cart.v1', '{invalid');
      final corrupt = makeCart(store);
      expect(corrupt.isEmpty, isTrue);
      corrupt.dispose();
    },
  );

  test(
    'guest is the default; missing Firebase never creates a fake account',
    () async {
      final session = AppSession(
        store: MemoryStore(),
        auth: GuestAuthService(),
      );
      addTearDown(session.dispose);
      expect(session.isGuest, isTrue);
      expect(session.auth.isConfigured, isFalse);
      await expectLater(
        session.auth.signIn('guest@example.com', 'password'),
        throwsA(isA<AuthFailure>()),
      );
      expect(session.isGuest, isTrue);
      final cart = makeCart()..onCheckout = session.rememberOrder;
      cart.add(demoProducts[0]);
      expect(cart.checkout().totalHalalas, 650);
      expect(session.orders, isEmpty);
      cart.dispose();
    },
  );

  test(
    'auth changes, profile updates and sign-out keep order histories isolated',
    () async {
      final store = MemoryStore();
      final auth = FakeAuth();
      final session = AppSession(store: store, auth: auth);
      final cart = makeCart()..onCheckout = session.rememberOrder;
      addTearDown(cart.dispose);
      addTearDown(session.dispose);
      await auth.createAccount('a@example.com', 'password', 'Sara');
      expect(session.account?.displayName, 'Sara');
      cart.add(demoProducts[0]);
      cart.add(demoProducts[0]);
      final order = cart.checkout();
      expect(session.orders.single.totalHalalas, 1300);
      // Firebase may refresh a profile/token before the queued local write finishes.
      await auth.updateDisplayName('Sarah');
      expect(session.account?.displayName, 'Sarah');
      expect(session.orders.single.number, order.number);
      await session.saved;
      await auth.signOut();
      expect(session.isGuest, isTrue);
      expect(session.orders, isEmpty);
      await auth.signIn('b@example.com', 'password');
      expect(session.orders, isEmpty);
      await auth.signIn('a@example.com', 'password');
      expect(session.orders.single.number, order.number);
      expect(session.orders.single.items.single.quantity, 2);
    },
  );

  test('existing auth state is restored and stream errors are recoverable', () {
    final auth = FakeAuth()
      ..account = const Account(
        uid: 'one',
        email: 'one@example.com',
        displayName: 'One',
      );
    final session = AppSession(store: MemoryStore(), auth: auth);
    addTearDown(session.dispose);
    expect(session.isGuest, isFalse);
    auth.events.addError(StateError('offline'));
    expect(session.authError, isNotNull);
    auth.emit(null);
    expect(session.authError, isNull);
    expect(session.isGuest, isTrue);
  });

  test('language preference survives session reload and rejects unsupported locale', () async {
    final store = MemoryStore();
    final session = AppSession(store: store, auth: GuestAuthService());
    expect(session.locale.languageCode, 'en');
    await session.setLanguage('ar');
    session.dispose();
    final restored = AppSession(store: store, auth: GuestAuthService());
    expect(restored.locale.languageCode, 'ar');
    await restored.setLanguage('unsupported');
    expect(restored.locale.languageCode, 'en');
    restored.dispose();
  });
}
