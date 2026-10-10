import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import 'auth_screen.dart';
import '../services/app_session.dart';

import '../services/cart_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_art.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.cart,
    required this.onShop,
    required this.onScan,
  });
  final CartController cart;
  final VoidCallback onShop;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => PageBody(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (SessionScope.of(context).isGuest)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onShop,
                  child: const LText('Continue as Guest'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AuthScreen(create: true),
                    ),
                  ),
                  child: const LText('Create Account'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
                  ),
                  child: const LText('Sign In'),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 24 : 44,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEAF1E1), Color(0xFFDDEAD5)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('A little smarter. A lot easier.'),
                  const SizedBox(height: 20),
                  LText(
                    'Your everyday shop,\nreimagined.',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: constraints.maxWidth < 400 ? 34 : 46,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const LText(
                    'Pick your favourites. Scan as you go.\nEnjoy a simpler way to fill your cart.',
                    style: TextStyle(
                      color: Color(0xFF536C5B),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        key: const Key('start-shopping'),
                        onPressed: onShop,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const LText('Start shopping'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onScan,
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                        ),
                        label: const LText('Try the scanner'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: forest),
                      SizedBox(width: 6),
                      Expanded(
                        child: LText(
                          'A fresh take on your grocery trip',
                          style: TextStyle(color: forest, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              );
              final art = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, i == 1 ? -12 : 8),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: forest.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ProductArt(
                              product: cart.catalog.products[i],
                              fit: BoxFit.cover,
                              height: i == 1 ? 220 : 180,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
              return constraints.maxWidth > 660
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: copy),
                        Expanded(flex: 2, child: art),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [copy, const SizedBox(height: 20), art],
                    );
            },
          ),
        ),
        const SizedBox(height: 32),
        const Eyebrow('Less waiting, more living'),
        const SizedBox(height: 8),
        LText(
          'Good shopping. Three simple steps.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 700
                ? (constraints.maxWidth - 28) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                _step(
                  width,
                  '01',
                  Icons.storefront_outlined,
                  'Discover your essentials',
                  'Browse familiar favourites and see what is inside.',
                ),
                _step(
                  width,
                  '02',
                  Icons.qr_code_scanner_rounded,
                  'Scan. Add. Keep going.',
                  'Scan a product label to explore its details.',
                ),
                _step(
                  width,
                  '03',
                  Icons.receipt_long_outlined,
                  'Leave with a little ease',
                  'Review your total and get an instant demo receipt.',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const InfoNote(
          'Graduation project prototype. Prices and nutrition are editable demo data. Checkout is simulated.',
        ),
        const SizedBox(height: 12),
      ],
    ),
  );

  Widget _step(
    double width,
    String number,
    IconData icon,
    String title,
    String detail,
  ) => SizedBox(
    width: width,
    child: SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: forest),
              const Spacer(),
              LText(
                number,
                style: const TextStyle(
                  color: Color(0xFFA4B49E),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LText(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LText(detail, style: const TextStyle(color: muted, height: 1.5)),
        ],
      ),
    ),
  );
}
