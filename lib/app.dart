import 'l10n/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/demo_products.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/products_screen.dart';
import 'screens/scanner_screen.dart';
import 'services/qr_scan_service.dart';
import 'services/app_session.dart';
import 'services/local_store.dart';
import 'services/auth_service.dart';
import 'screens/settings_screen.dart';
import 'screens/product_details_screen.dart';
import 'services/product_links.dart';
import 'widgets/common.dart';
import 'services/cart_controller.dart';
import 'services/product_catalog.dart';
import 'widgets/app_theme.dart';
import 'widgets/brand_mark.dart';

class SmartShoppingApp extends StatefulWidget {
  const SmartShoppingApp({
    super.key,
    this.controller,
    this.session,
    this.initialRoute,
  });
  final CartController? controller;
  final AppSession? session;
  final String? initialRoute;
  @override
  State<SmartShoppingApp> createState() => _SmartShoppingAppState();
}

class _SmartShoppingAppState extends State<SmartShoppingApp> {
  late final CartController cart;
  late final AppSession session;
  final messenger = GlobalKey<ScaffoldMessengerState>();
  ScanFeedback? _lastFeedback;
  @override
  void initState() {
    super.initState();
    session =
        widget.session ??
        AppSession(store: MemoryStore(), auth: GuestAuthService());
    cart =
        widget.controller ??
        CartController(
          catalog: ProductCatalog(demoProducts),
          scanner: LocalQrScanService(),
          store: session.store,
        );
    cart.onCheckout = session.rememberOrder;
    cart.addListener(_showScanFeedback);
  }

  void _showScanFeedback() {
    final feedback = cart.scanFeedback;
    if (feedback == null || identical(feedback, _lastFeedback)) return;
    _lastFeedback = feedback;
    messenger.currentState?.hideCurrentSnackBar();
    messenger.currentState?.showSnackBar(
      SnackBar(
        content: LText(feedback.message),
        backgroundColor: feedback.success ? forest : const Color(0xFFAA3737),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    cart.removeListener(_showScanFeedback);
    cart.onCheckout = null;
    if (widget.controller == null) cart.dispose();
    if (widget.session == null) session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => SessionScope(
      session: session,
      child: MaterialApp(
        title: 'Smart Cart | A smarter way to shop',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(arabic: session.locale.languageCode == 'ar'),
        locale: session.locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        scaffoldMessengerKey: messenger,
        initialRoute: widget.initialRoute,
        onGenerateRoute: _route,
        onGenerateInitialRoutes: (path) => [
          _route(const RouteSettings(name: '/')),
          if (path != '/') _route(RouteSettings(name: path)),
        ],
      ),
    ),
  );

  Route<void> _route(RouteSettings settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (context) {
      final path = settings.name ?? '/';
      if (path == '/') return ShoppingShell(cart: cart);
      if (path == '/cart') {
        return Scaffold(
          appBar: AppBar(title: const LText('Cart')),
          body: CartScreen(
            cart: cart,
            onBrowse: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            onNewTrip: cart.startNewTrip,
          ),
        );
      }
      final id = ProductLinks.idFromPath(path);
      final product = id == null ? null : cart.catalog.findById(id);
      if (product != null) {
        return ProductDetailsScreen(product: product, cart: cart);
      }
      return Scaffold(
        appBar: AppBar(title: const LText('Product not found')),
        body: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoNote(
                'This product link is invalid or no longer available.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const LText('Explore products'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ShoppingShell extends StatefulWidget {
  const ShoppingShell({super.key, required this.cart});
  final CartController cart;
  @override
  State<ShoppingShell> createState() => _ShoppingShellState();
}

class _ShoppingShellState extends State<ShoppingShell> {
  int _page = -1;
  void _navigate(int index) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _page = index);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.cart,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigate(-1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(),
              const SizedBox(width: 10),
              const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'SmartCart',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFDF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const LText(
              'DEMO',
              style: TextStyle(
                fontSize: 10,
                color: forest,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _PageEntrance(
          key: ValueKey(_page),
          child: switch (_page) {
            0 => ProductsScreen(cart: widget.cart),
            1 => ScannerScreen(
              cart: widget.cart,
              onViewCart: () => _navigate(2),
            ),
            2 => CartScreen(
              cart: widget.cart,
              onBrowse: () => _navigate(0),
              onNewTrip: () => _navigate(-1),
            ),
            3 => const SettingsScreen(),
            _ => HomeScreen(
              cart: widget.cart,
              onShop: () => _navigate(0),
              onScan: () => _navigate(1),
            ),
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: border)),
        ),
        child: NavigationBar(
          selectedIndex: _page < 0 ? 0 : _page,
          onDestinationSelected: _navigate,
          destinations: [
            NavigationDestination(
              key: Key('nav-products'),
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: context.tr('Products'),
            ),
            NavigationDestination(
              key: Key('nav-scan'),
              icon: Icon(Icons.qr_code_scanner_rounded),
              label: context.tr('Scan'),
            ),
            NavigationDestination(
              key: const Key('nav-cart'),
              icon: Badge(
                isLabelVisible: widget.cart.totalQuantity > 0,
                label: LText('${widget.cart.totalQuantity}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              label: context.tr('Cart'),
            ),
            NavigationDestination(
              key: const Key('nav-settings'),
              icon: const Icon(Icons.tune_rounded),
              label: context.tr('Settings'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Animate the arriving tab while disposing the previous camera immediately.
class _PageEntrance extends StatelessWidget {
  const _PageEntrance({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220),
    child: child,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - value)),
        child: child,
      ),
    ),
  );
}
