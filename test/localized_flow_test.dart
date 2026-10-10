import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_shopping_cart/app.dart';
import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/l10n/app_strings.dart';
import 'package:smart_shopping_cart/services/app_session.dart';
import 'package:smart_shopping_cart/services/local_store.dart';
import 'package:smart_shopping_cart/services/qr_labels_pdf.dart';

import 'qr_session_test.dart' show makeCart;
import 'support/fake_auth.dart';
import 'widget_test.dart' show tapVisible;

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 1000),
  ]) {
    testWidgets('Arabic RTL full guest flow and all product details at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      AppStrings.untranslated.clear();
      final store = MemoryStore();
      final session = AppSession(store: store, auth: FakeAuth());
      final cart = makeCart(store);
      addTearDown(session.dispose);
      addTearDown(cart.dispose);
      await tester.pumpWidget(
        SmartShoppingApp(session: session, controller: cart),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('nav-settings')));
      await tapVisible(tester, find.byKey(const Key('language-ar')));
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('nav-settings'))),
        ),
        TextDirection.rtl,
      );
      expect(session.locale.languageCode, 'ar');
      await tapVisible(tester, find.byKey(const Key('nav-cart')));
      expect(find.text('عربتك فارغة حالياً'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('nav-products')));
      for (final product in demoProducts) {
        await tapVisible(tester, find.byKey(Key('product-${product.barcode}')));
        expect(find.text(product.nameAr), findsOneWidget);
        expect(find.byType(QrImageView), findsNothing);
        await tapVisible(tester, find.byKey(const Key('details-add')));
        await tapVisible(tester, find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      await tapVisible(tester, find.byKey(const Key('nav-scan')));
      await tester.ensureVisible(find.byKey(const Key('barcode-input')));
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        'SMARTCART:P999',
      );
      await tapVisible(tester, find.byKey(const Key('scan-barcode')));
      expect(cart.scanFeedback?.success, isFalse);
      await tester.enterText(
        find.byKey(const Key('barcode-input')),
        'SMARTCART:P001',
      );
      await tapVisible(tester, find.byKey(const Key('scan-barcode')));
      await tapVisible(tester, find.byKey(const Key('scan-barcode')));
      expect(cart.quantityOf(demoProducts[0]), 3);
      await tapVisible(tester, find.byKey(const Key('nav-cart')));
      await tapVisible(tester, find.byKey(const Key('go-checkout')));
      await tapVisible(tester, find.byKey(const Key('complete-checkout')));
      expect(find.byKey(const Key('receipt-number')), findsOneWidget);
      expect(find.text('ر.س 35.00'), findsNWidgets(1));
      expect(cart.isEmpty, isTrue);
      await tapVisible(tester, find.byKey(const Key('new-trip')));
      // Superseding requirement: QR labels are external files, never public UI.
      expect(find.byTooltip('ملصقات رموز المنتجات'), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
      await tapVisible(tester, find.byKey(const Key('nav-settings')));
      await tapVisible(tester, find.byKey(const Key('language-en')));
      expect(find.text('Guest shopping'), findsOneWidget);
      expect(
        AppStrings.untranslated,
        isEmpty,
        reason: AppStrings.untranslated.join('\n'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final language in ['en', 'ar']) {
    testWidgets(
      'optional account validation, errors, reset, profile and history in $language',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        AppStrings.untranslated.clear();
        final auth = FakeAuth();
        final session = AppSession(store: MemoryStore(), auth: auth);
        await session.setLanguage(language);
        final cart = makeCart();
        addTearDown(session.dispose);
        addTearDown(cart.dispose);
        final strings = AppStrings(language);
        await tester.pumpWidget(
          SmartShoppingApp(session: session, controller: cart),
        );
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text(strings.t('Create Account')));
        await tapVisible(tester, find.byKey(const Key('auth-submit')));
        expect(
          find.text(strings.t('Please enter a valid email address.')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('auth-email')),
          'sara@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('auth-password')),
          'strong-password',
        );
        await tester.enterText(find.byKey(const Key('auth-name')), 'Sara');
        auth.failureCode = 'email-already-in-use';
        await tapVisible(tester, find.byKey(const Key('auth-submit')));
        expect(
          find.text(
            strings.t('This email already has an account. Try signing in.'),
          ),
          findsOneWidget,
        );
        auth.failureCode = null;
        await tapVisible(tester, find.byKey(const Key('auth-submit')));
        expect(session.account?.displayName, 'Sara');
        await tapVisible(tester, find.byKey(const Key('nav-settings')));
        await tester.enterText(find.byKey(const Key('profile-name')), 'Sarah');
        await tapVisible(tester, find.text(strings.t('Save profile')));
        expect(session.account?.displayName, 'Sarah');
        cart.add(demoProducts[0]);
        cart.checkout();
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text(session.orders.single.number));
        expect(find.byKey(const Key('receipt-number')), findsOneWidget);
        await tapVisible(tester, find.text(strings.t('Close')));
        await tapVisible(tester, find.text(strings.t('Sign Out')));
        expect(session.isGuest, isTrue);
        await tapVisible(tester, find.byKey(const Key('settings-sign-in')));
        await tapVisible(tester, find.text(strings.t('Forgot Password')));
        await tester.enterText(
          find.byKey(const Key('auth-email')),
          'sara@example.com',
        );
        await tapVisible(tester, find.byKey(const Key('auth-submit')));
        expect(auth.resetEmail, 'sara@example.com');
        expect(
          find.text(
            strings.t(
              'If an account exists for this email, a reset link has been sent.',
            ),
          ),
          findsOneWidget,
        );
        await tapVisible(tester, find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('auth-email')),
          'sara@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('auth-password')),
          'strong-password',
        );
        await tapVisible(tester, find.byKey(const Key('auth-submit')));
        expect(session.isGuest, isFalse);
        expect(session.orders, hasLength(1));
        expect(
          AppStrings.untranslated,
          isEmpty,
          reason: AppStrings.untranslated.join('\n'),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('printable English and Arabic PDFs contain all five labels', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final arabic in [false, true]) {
        final bytes = await buildQrLabelsPdf(demoProducts, arabic: arabic);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(20000));
        final file = File(
          'build/verification/qr-labels-${arabic ? 'ar' : 'en'}.pdf',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
      }
    });
  });
}
