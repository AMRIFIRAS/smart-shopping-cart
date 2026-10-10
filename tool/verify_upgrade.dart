import 'dart:convert';
import 'dart:io';

import 'browser_session.dart';

Future<void> main(List<String> args) async {
  final origin = args.isEmpty ? 'http://localhost:8080' : args.first;
  final browser = await BrowserSession.connect();
  try {
    await browser.clearStorage(origin);
    await browser.viewport(390, 844);
    await browser.load(origin);
    await browser.screenshot('url-home-en');
    await browser.expectText('Product QR Labels', present: false);
    await browser.nav(0);
    await browser.enter('water');
    await browser.expectText('1 essentials to explore');
    await browser.enter('');
    await browser.nav(1);
    await browser.button('Start camera');
    await browser.waitText('Product details');
    await browser.expectText('Almarai Full Fat Milk');
    await browser.expectText('Add to cart');
    await browser.screenshot('url-camera-product-preview');
    final live = await browser.js(
      "Array.from(document.querySelectorAll('video')).filter(v=>v.srcObject && v.srcObject.getTracks().some(t=>t.readyState==='live')).length",
    );
    if (live != 0) {
      throw StateError('Camera remained active behind product details.');
    }
    await browser.button('Cart');
    await browser.expectText('Your cart is feeling light');
    stdout.writeln(
      'PASS real camera URL decode opens details without adding; camera stops.',
    );
    await browser.load(origin);
    await browser.nav(1);
    await browser.enter('https://unrelated.invalid/product/P001');
    await browser.button('View product');
    await browser.expectText(
      'Unknown or invalid QR code. Use a SmartCart product label.',
    );
    await browser.enter('$origin/product/P004');
    await browser.button('View product');
    await browser.expectText('Twix Chocolate');
    await browser.button('Add to cart');
    await browser.button('Cart');
    await browser.expectText('SAR 3.50');
    await browser.button('Continue to checkout');
    await browser.button('Complete demo checkout');
    await browser.expectText('1 × SAR 3.50');
    await browser.expectText('SIMULATED · NO PAYMENT TAKEN');
    await browser.screenshot('url-receipt-en');
    await browser.button('Start New Shopping Trip');
    await browser.nav(3);
    await browser.button('Sign In');
    await browser.expectText('Forgot Password');
    await browser.button('Forgot Password');
    await browser.expectText('Send reset link');
    await browser.button('Continue as Guest');
    await browser.nav(3);
    await browser.button('Arabic');
    await browser.load('$origin/product/P005');
    await browser.expectText('شيبس دوريتوس');
    await browser.viewport(320, 568);
    await browser.screenshot('url-product-ar-320');
    await browser.button('أضف إلى العربة');
    await browser.button('العربة');
    await browser.expectText('ر.س 4.00');
    await browser.button('المتابعة لإتمام الشراء');
    await browser.button('إتمام الشراء التجريبي');
    await browser.screenshot('url-receipt-ar-320');
    await browser.button('ابدأ رحلة تسوّق جديدة');
    await browser.nav(3, arabic: true, width: 320, height: 568);
    await browser.button('الإنجليزية');
    await browser.viewport(1440, 1000);
    await browser.load('$origin/product/P002');
    await browser.screenshot('url-product-desktop');
    await browser.expectText('Nadec Orange Juice');
    await browser.button('Cart');
    await browser.expectText('Your cart is feeling light');
    if (browser.errors.isNotEmpty) throw StateError(jsonEncode(browser.errors));
    await File('build/verification/browser-report.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'origin': origin,
        'passed': true,
        'runtimeErrors': browser.errors,
        'cameraBehavior': 'URL previews product without adding',
        'guestCheckout': true,
        'languages': ['en', 'ar'],
        'viewportWidths': [320, 390, 1440],
        'qrCodesVisibleOnWebsite': false,
        'physicalIphoneTest': false,
      }),
    );
    stdout.writeln(
      'PASS URL scanner, invalid URLs, explicit Add, guest checkout, account paths and bilingual responsive layouts. Runtime errors: 0',
    );
  } catch (error) {
    await browser.screenshot('url-browser-failure');
    await File('build/verification/failure-dom.html').writeAsString(
      await browser.js('document.documentElement.outerHTML') as String,
    );
    stderr.writeln(error);
    stderr.writeln(jsonEncode(browser.errors));
    exitCode = 1;
  } finally {
    await browser.close();
  }
}
