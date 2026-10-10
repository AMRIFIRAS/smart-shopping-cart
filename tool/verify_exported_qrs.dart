import 'dart:convert';
import 'dart:io';

import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/services/product_links.dart';

import 'browser_session.dart';
import 'qr_export.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw ArgumentError('Provide export folder and exact site origin.');
  }
  final folder = Directory(args[0]);
  final links = ProductLinks(Uri.parse(args[1]));
  final fixtureOnly = links.origin.host == 'fixture.invalid';
  final browser = await BrowserSession.connect();
  try {
    for (final product in demoProducts) {
      final bytes = await File('${folder.path}/${qrFileNames[product.id]}')
          .readAsBytes();
      final codes = await browser.js('''(async () => {
        if (!window.ZXingWASM) await new Promise((resolve,reject) => {
          const script=document.createElement('script');
          script.src='https://cdn.jsdelivr.net/npm/zxing-wasm@3.1.3/dist/iife/reader/index.js';
          script.onload=resolve; script.onerror=reject; document.head.appendChild(script);
        });
        const photo=new Image(); photo.src='data:image/png;base64,${base64Encode(bytes)}';
        await photo.decode(); const canvas=document.createElement('canvas');
        canvas.width=photo.width; canvas.height=photo.height;
        const context=canvas.getContext('2d'); context.drawImage(photo,0,0);
        const codes=await ZXingWASM.readBarcodes(context.getImageData(0,0,canvas.width,canvas.height),{formats:['QRCode'],tryHarder:true});
        return codes.map(code=>code.text);
      })()''');
      final expected = links.urlFor(product.id);
      if (jsonEncode(codes) != jsonEncode([expected])) {
        throw StateError('Wrong QR payload for ${product.id}: $codes');
      }
      if (!fixtureOnly) {
        await browser.clearStorage(links.origin.origin);
        await browser.viewport(320, 568);
        await browser.load(expected);
        await browser.expectText(product.name);
        await browser.expectText('Add to cart');
        await browser.button('Cart');
        await browser.expectText('Your cart is feeling light');
      }
      stdout.writeln('PASS ${qrFileNames[product.id]} → $expected');
    }
    if (browser.errors.isNotEmpty) throw StateError(jsonEncode(browser.errors));
    stdout.writeln(
      fixtureOnly
          ? 'Fixture-only label decode verified; no final public QR files generated.'
          : 'All final QR PNGs decode to verified product pages; no automatic cart changes.',
    );
  } finally {
    await browser.close();
  }
}
