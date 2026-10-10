import 'dart:convert';
import 'dart:io';

import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/models/product.dart';

import 'browser_session.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw ArgumentError(
      'Provide the deployed HTTPS origin, or localhost for local verification.',
    );
  }
  final origin = Uri.parse(args.single);
  final isPublic =
      origin.isScheme('https') &&
      (origin.host.endsWith('.web.app') ||
          origin.host.endsWith('.firebaseapp.com'));
  if (!isPublic && origin.host != 'localhost') {
    throw ArgumentError('Expected Firebase HTTPS site or localhost preview.');
  }
  final browser = await BrowserSession.connect();
  final http = HttpClient();
  try {
    await browser.clearStorage(origin.origin);
    for (final width in [320, 1440]) {
      await browser.viewport(width, width == 320 ? 568 : 1000);
      for (final product in demoProducts) {
        final url = '${origin.origin}/product/${product.id}';
        final response = await (await http.getUrl(Uri.parse(url))).close();
        await response.drain<void>();
        if (response.statusCode != 200) {
          throw StateError('Route HTTP status ${response.statusCode}: $url');
        }
        await browser.load(url);
        await browser.expectText(product.name);
        await browser.expectText(money(product.priceHalalas));
        await browser.expectText('Calories (kcal)');
        await browser.expectText('Protein');
        await browser.expectText('Add to cart');
        await browser.expectText('Product QR Labels', present: false);
        final actualPath = await browser.js('location.pathname');
        if (actualPath != '/product/${product.id}') {
          throw StateError('Wrong route: $actualPath');
        }
        final saved = await browser.js(
          "localStorage.getItem('flutter.smartcart.cart.v1')",
        );
        if (saved != null && !['[]', '"[]"'].contains(saved)) {
          throw StateError('Opening a product changed the cart: $saved');
        }
        await browser.screenshot('direct-${product.id}-$width');
        // Refresh is another native camera-style visit. It must be safe too.
        await browser.load(url);
        await browser.button('Cart');
        await browser.expectText('Your cart is feeling light');
        stdout.writeln(
          'PASS $url at $width px: details visible, cart unchanged',
        );
      }
    }
    for (final path in ['/product/P999', '/product/P001/extra', '/qr-labels']) {
      await browser.load('${origin.origin}$path');
      await browser.expectText('Product not found');
    }
    if (browser.errors.isNotEmpty) throw StateError(jsonEncode(browser.errors));
    final report = {
      'origin': origin.origin,
      'passed': true,
      'productIds': demoProducts.map((p) => p.id).toList(),
      'verifiedAt': DateTime.now().toUtc().toIso8601String(),
      'viewportWidths': [320, 1440],
      'cartUnchanged': true,
      'runtimeErrors': browser.errors,
      'physicalIphoneTest': false,
    };
    await File(
      'build/verification/${isPublic ? 'public-products' : 'local-product-routes'}.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    stdout.writeln(
      'All product routes verified. Physical iPhone camera acceptance remains a device check.',
    );
  } finally {
    http.close();
    await browser.close();
  }
}
