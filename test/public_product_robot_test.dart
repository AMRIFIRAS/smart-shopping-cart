import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_shopping_cart/app.dart';
import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/l10n/app_strings.dart';
import 'package:smart_shopping_cart/models/product.dart';
import 'package:smart_shopping_cart/services/app_session.dart';
import 'package:smart_shopping_cart/services/auth_service.dart';
import 'package:smart_shopping_cart/services/cart_controller.dart';
import 'package:smart_shopping_cart/services/local_store.dart';
import 'package:smart_shopping_cart/services/product_catalog.dart';
import 'package:smart_shopping_cart/services/product_links.dart';
import 'package:smart_shopping_cart/services/qr_scan_service.dart';
import 'package:smart_shopping_cart/services/robot_scan_service.dart';

import '../tool/qr_export.dart';
import 'widget_test.dart' show tapVisible;

final links = ProductLinks(Uri.parse('https://fixture.invalid'));
final catalog = ProductCatalog(demoProducts, links: links);
Matcher failure(String code) =>
    throwsA(isA<RobotScanFailure>().having((e) => e.code, 'code', code));

void main() {
  test('canonical QR links uniquely identify each product and reject foreign or malformed URLs', () {
    for (final product in demoProducts) {
      expect(
        links.urlFor(product.id),
        'https://fixture.invalid/product/${product.id}',
      );
      expect(catalog.findByPublicQr(links.urlFor(product.id)), same(product));
    }
    for (final invalid in [
      '',
      'SMARTCART:P001',
      'P001',
      '/product/P001',
      'javascript:alert(1)',
      'http://fixture.invalid/product/P001',
      'https://other.invalid/product/P001',
      'https://fixture.invalid.evil.test/product/P001',
      'https://user@fixture.invalid/product/P001',
      'https://fixture.invalid/product/P001?cart_id=another',
      'https://fixture.invalid/product/P001#add',
      'https://fixture.invalid/product/P001/extra',
      'https://fixture.invalid/product/P999',
      'https://fixture.invalid/product/p001',
      'https://fixture.invalid:444/product/P001',
    ]) {
      expect(catalog.findByPublicQr(invalid), isNull, reason: invalid);
    }
    expect(
      () => ProductLinks(Uri.parse('http://public.example')),
      throwsArgumentError,
    );
  });

  for (final language in ['en', 'ar']) {
    for (final product in demoProducts) {
      testWidgets(
        'direct ${product.id} link previews without adding in $language at 320px',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final session = AppSession(
            store: MemoryStore(),
            auth: GuestAuthService(),
          );
          await session.setLanguage(language);
          final cart = CartController(
            catalog: catalog,
            scanner: LocalQrScanService(),
          );
          addTearDown(cart.dispose);
          addTearDown(session.dispose);
          AppStrings.untranslated.clear();
          await tester.pumpWidget(
            SmartShoppingApp(
              controller: cart,
              session: session,
              initialRoute: '/product/${product.id}',
            ),
          );
          await tester.pumpAndSettle();
          expect(cart.isEmpty, isTrue);
          expect(
            find.text(language == 'ar' ? product.nameAr : product.name),
            findsOneWidget,
          );
          expect(find.image(AssetImage(product.imageAsset!)), findsOneWidget);
          expect(
            find.text(AppStrings(language).t(money(product.priceHalalas))),
            findsOneWidget,
          );
          expect(find.text('${product.calories}'), findsOneWidget);
          expect(find.byType(QrImageView), findsNothing);
          await tapVisible(tester, find.byKey(const Key('details-add')));
          expect(cart.quantityOf(product), 1);
          await tapVisible(tester, find.byKey(const Key('details-cart')));
          expect(cart.totalHalalas, product.priceHalalas);
          expect(find.byKey(const Key('go-checkout')), findsOneWidget);
          expect(AppStrings.untranslated, isEmpty);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets(
    'manual public QR URL opens a preview without altering a saved cart',
    (tester) async {
      final cart = CartController(
        catalog: catalog,
        scanner: LocalQrScanService(),
      )..add(demoProducts[2]);
      addTearDown(cart.dispose);
      await tester.pumpWidget(SmartShoppingApp(controller: cart));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('nav-scan')));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        links.urlFor('P001'),
      );
      await tapVisible(tester, find.byKey(const Key('scan-barcode')));
      expect(find.text('Almarai Full Fat Milk'), findsOneWidget);
      expect(cart.totalHalalas, 100);
      await tapVisible(tester, find.byType(BackButton));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        'https://other.invalid/product/P001',
      );
      await tapVisible(tester, find.byKey(const Key('scan-barcode')));
      expect(cart.totalHalalas, 100);
      expect(cart.scanFeedback?.success, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final path in ['/product/P999', '/product/P001/extra', '/qr-labels']) {
    testWidgets('invalid or removed route $path has a safe localized error', (
      tester,
    ) async {
      final cart = CartController(
        catalog: catalog,
        scanner: LocalQrScanService(),
      );
      addTearDown(cart.dispose);
      await tester.pumpWidget(
        SmartShoppingApp(controller: cart, initialRoute: path),
      );
      await tester.pumpAndSettle();
      expect(find.text('Product not found'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(cart.isEmpty, isTrue);
      await tapVisible(tester, find.text('Explore products'));
      expect(find.byKey(const Key('start-shopping')), findsOneWidget);
    });
  }

  test('robot message matches the three-field contract and rejects invalid JSON fields', () {
    final message = RobotScanMessage(
      cartId: 'active-cart-id',
      productId: 'P001',
    );
    expect(message.toJson(), {
      'cart_id': 'active-cart-id',
      'product_id': 'P001',
      'source': 'raspberry-pi',
    });
    expect(
      RobotScanMessage.fromJson(
        jsonDecode(jsonEncode(message.toJson())) as Map<String, dynamic>,
      ).productId,
      'P001',
    );
    for (final value in [
      {'cart_id': '', 'product_id': 'P001', 'source': 'raspberry-pi'},
      {'cart_id': 'cart-a', 'product_id': 1, 'source': 'raspberry-pi'},
      {'cart_id': 'cart-a', 'product_id': 'P001', 'source': 'phone'},
      {'cart_id': 'cart-a', 'product_id': 'P001'},
      {
        'cart_id': 'cart-a',
        'product_id': 'P001',
        'source': 'raspberry-pi',
        'owner': 'forged',
      },
    ]) {
      expect(
        () => RobotScanMessage.fromJson(value),
        failure('invalid-message'),
      );
    }
  });

  test('paired robot scans add only to the correct cart and filter update subscriptions', () async {
    final backend = SimulatedRobotBackend(catalog);
    final a = backend.createCart('cart-a', 'owner-a'),
        b = backend.createCart('cart-b', 'owner-b');
    final updates = <RobotCartUpdate>[];
    final subscription = backend
        .updatesFor(a.id, authenticatedOwnerId: a.ownerId)
        .listen(updates.add);
    expect(
      () => backend.updatesFor(a.id, authenticatedOwnerId: b.ownerId),
      failure('wrong-owner'),
    );
    backend.pair(
      robotId: 'robot-a',
      cartId: a.id,
      authenticatedOwnerId: a.ownerId,
    );
    backend.pair(
      robotId: 'robot-b',
      cartId: b.id,
      authenticatedOwnerId: b.ownerId,
    );
    final simulator = RobotScanSimulator(
      links: links,
      pairing: backend,
      transport: backend,
    );
    final start = DateTime(2026);
    for (var frame = 0; frame < 50; frame++) {
      await simulator.scan(
        robotId: 'robot-a',
        qrUrl: links.urlFor('P001'),
        now: start.add(Duration(milliseconds: frame * 200)),
      );
    }
    await simulator.scan(
      robotId: 'robot-b',
      qrUrl: links.urlFor('P005'),
      now: start,
    );
    expect(a.quantities, {'P001': 1});
    expect(b.quantities, {'P005': 1});
    expect(updates, hasLength(1));
    await simulator.scan(
      robotId: 'robot-a',
      qrUrl: links.urlFor('P001'),
      now: start.add(const Duration(seconds: 13)),
    );
    expect(a.quantities, {'P001': 2});
    expect(b.quantities, {'P005': 1});
    await subscription.cancel();
    await backend.dispose();
  });

  test('unpaired, wrong-owner, mismatched, invalid and unknown robot scans do not mutate carts', () async {
    final backend = SimulatedRobotBackend(catalog);
    final a = backend.createCart('cart-a', 'owner-a'),
        b = backend.createCart('cart-b', 'owner-b');
    final simulator = RobotScanSimulator(
      links: links,
      pairing: backend,
      transport: backend,
    );
    await expectLater(
      simulator.scan(robotId: 'robot', qrUrl: links.urlFor('P001')),
      failure('robot-not-paired'),
    );
    expect(
      () => backend.pair(
        robotId: 'robot',
        cartId: a.id,
        authenticatedOwnerId: b.ownerId,
      ),
      failure('wrong-owner'),
    );
    backend.pair(
      robotId: 'robot',
      cartId: a.id,
      authenticatedOwnerId: a.ownerId,
    );
    await expectLater(
      backend.send(
        authenticatedRobotId: 'robot',
        eventId: 'one',
        message: RobotScanMessage(cartId: b.id, productId: 'P001'),
      ),
      failure('cart-mismatch'),
    );
    await expectLater(
      simulator.scan(robotId: 'robot', qrUrl: links.urlFor('P999')),
      failure('unknown-product'),
    );
    await expectLater(
      simulator.scan(
        robotId: 'robot',
        qrUrl: 'https://other.invalid/product/P001',
      ),
      failure('invalid-qr'),
    );
    expect(a.quantities, isEmpty);
    expect(b.quantities, isEmpty);
    backend.closeCart(a.id);
    await expectLater(
      simulator.scan(robotId: 'robot', qrUrl: links.urlFor('P001')),
      failure('robot-not-paired'),
    );
    await backend.dispose();
  });

  test('retries are idempotent; re-pairing rejects stale messages and new event IDs add intentionally', () async {
    final backend = SimulatedRobotBackend(catalog);
    final a = backend.createCart('cart-a', 'owner-a'),
        b = backend.createCart('cart-b', 'owner-b');
    backend.pair(
      robotId: 'robot',
      cartId: a.id,
      authenticatedOwnerId: a.ownerId,
    );
    final message = RobotScanMessage(cartId: a.id, productId: 'P002');
    await backend.send(
      authenticatedRobotId: 'robot',
      eventId: 'one',
      message: message,
    );
    await backend.send(
      authenticatedRobotId: 'robot',
      eventId: 'one',
      message: message,
    );
    expect(a.quantities, {'P002': 1});
    await expectLater(
      backend.send(
        authenticatedRobotId: 'robot',
        eventId: 'one',
        message: RobotScanMessage(cartId: a.id, productId: 'P003'),
      ),
      failure('event-conflict'),
    );
    await backend.send(
      authenticatedRobotId: 'robot',
      eventId: 'two',
      message: message,
    );
    expect(a.quantities, {'P002': 2});
    backend.pair(
      robotId: 'robot',
      cartId: b.id,
      authenticatedOwnerId: b.ownerId,
    );
    await expectLater(
      backend.send(
        authenticatedRobotId: 'robot',
        eventId: 'late',
        message: message,
      ),
      failure('cart-mismatch'),
    );
    await backend.send(
      authenticatedRobotId: 'robot',
      eventId: 'three',
      message: RobotScanMessage(cartId: b.id, productId: 'P001'),
    );
    expect(b.quantities, {'P001': 1});
    expect(a.quantities, {'P002': 2});
    await backend.dispose();
  });

  test('external export produces named printable PNG/PDF fixtures outside web assets', () async {
    expect(qrFileNames.length, 5);
    final folder = Directory('build/verification/external-label-fixtures')
      ..createSync(recursive: true);
    for (final product in demoProducts) {
      final bytes = renderProductLabel(product, links);
      final decoded = img.decodePng(bytes)!;
      expect(decoded.width, 1400);
      expect(decoded.height, 1700);
      await File('${folder.path}/${qrFileNames[product.id]}')
          .writeAsBytes(bytes);
    }
    final bytes = await renderLabelPdf(
      demoProducts,
      links,
      ByteData.sublistView(
        await File('assets/fonts/roboto-regular.ttf').readAsBytes(),
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    await File('${folder.path}/fixture-only.pdf').writeAsBytes(bytes);
    expect(Directory('web/SmartCart_QR_Codes').existsSync(), isFalse);
  });
}
