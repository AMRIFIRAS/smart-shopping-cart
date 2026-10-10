import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/services/product_links.dart';

import 'qr_export.dart';

/// Produces a REVIEWABLE workspace-only staging folder after deployment checks.
/// Copy to Desktop/SmartCart_QR_Codes only after the owner's explicit permission.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw ArgumentError(
      'Usage: dart run tool/export_product_qrs.dart https://ACTUAL_SITE.web.app',
    );
  }
  final origin = Uri.parse(args.single);
  final links = ProductLinks(origin);
  if ((!origin.host.endsWith('.web.app') &&
          !origin.host.endsWith('.firebaseapp.com')) ||
      origin.hasPort) {
    throw ArgumentError(
      'Use the final, deployed Firebase Hosting HTTPS origin.',
    );
  }
  final verified = File('build/verification/public-products.json');
  if (!verified.existsSync()) {
    throw StateError(
      'Verify every deployed product route with tool/verify_public_products.dart first.',
    );
  }
  final report =
      jsonDecode(await verified.readAsString()) as Map<String, dynamic>;
  if (report['origin'] != origin.origin ||
      report['passed'] != true ||
      (report['productIds'] as List).join(',') !=
          demoProducts.map((p) => p.id).join(',')) {
    throw StateError(
      'Public verification report does not match this site and all five products.',
    );
  }
  // Recheck HTTP reachability; rendered details/no-auto-add were browser-tested
  // by verify_public_products before this report was written.
  final client = HttpClient();
  try {
    for (final product in demoProducts) {
      final response = await (await client.getUrl(
        Uri.parse(links.urlFor(product.id)),
      )).close();
      final html = await utf8.decoder.bind(response).join();
      if (response.statusCode != 200 ||
          !html.contains('flutter_bootstrap.js')) {
        throw StateError(
          'Deployed product URL unavailable: ${links.urlFor(product.id)}',
        );
      }
    }
  } finally {
    client.close();
  }
  final output = Directory('build/qr-export/SmartCart_QR_Codes');
  await output.create(recursive: true);
  for (final product in demoProducts) {
    await File('${output.path}/${qrFileNames[product.id]}')
        .writeAsBytes(renderProductLabel(product, links));
  }
  final font = ByteData.sublistView(
    await File('assets/fonts/roboto-regular.ttf').readAsBytes(),
  );
  await File('${output.path}/SmartCart_Product_QR_Codes.pdf')
      .writeAsBytes(await renderLabelPdf(demoProducts, links, font));
  await File('${output.path}/QR_CODE_MAPPING.txt').writeAsString(
    [
      'SmartCart final product QR codes',
      'Public site: ${origin.origin}',
      'Phone: opens product details; never adds automatically.',
      'Future paired robot: extracts product_id and sends it with the active cart_id.',
      'Physical robot and backend are not connected.',
      '',
      for (final product in demoProducts)
        '${qrFileNames[product.id]}\n${product.name}\nProduct ID: ${product.id}\n${links.urlFor(product.id)}\n',
    ].join('\r\n'),
  );
  stdout.writeln(
    'Staged seven files inside workspace: ${output.absolute.path}',
  );
  stdout.writeln(
    'Ask the owner before copying this folder to the Windows Desktop.',
  );
}
