import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/cart_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/common.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.cart,
    required this.onBrowse,
    required this.onNewTrip,
  });
  final CartController cart;
  final VoidCallback onBrowse;
  final VoidCallback onNewTrip;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: cart,
    builder: (context, _) => PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            eyebrow: 'Your shopping trip',
            title: 'A cart full of good things',
            subtitle: cart.isEmpty
                ? 'Your next favourite is just a scan away.'
                : '${cart.totalQuantity} items picked. Looking good!',
          ),
          if (cart.isEmpty)
            SizedBox(
              width: double.infinity,
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 48,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECF3E6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: forest,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LText(
                      'Your cart is feeling light',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    const LText(
                      'Browse the essentials or scan a demo product\nto start your shopping trip.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onBrowse,
                      icon: const Icon(Icons.storefront_outlined),
                      label: const LText('Explore products'),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final items = Column(
                  children: cart.items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CartItemTile(item: item, cart: cart),
                        ),
                      )
                      .toList(),
                );
                final summary = SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LText(
                        'Your trip at a glance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      SummaryRow('Items', '${cart.totalQuantity}'),
                      SummaryRow('Subtotal', money(cart.totalHalalas)),
                      const SummaryRow('Additional charges', 'SAR 0.00'),
                      const Divider(),
                      SummaryRow(
                        'Total',
                        money(cart.totalHalalas),
                        emphasized: true,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('go-checkout'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CheckoutScreen(
                              cart: cart,
                              onNewTrip: onNewTrip,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const LText('Continue to checkout'),
                      ),
                      const SizedBox(height: 16),
                      const InfoNote(
                        'Demo checkout. No real payment or additional charges.',
                      ),
                    ],
                  ),
                );
                return constraints.maxWidth > 780
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: items),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: summary),
                        ],
                      )
                    : Column(
                        children: [items, const SizedBox(height: 8), summary],
                      );
              },
            ),
        ],
      ),
    ),
  );
}
