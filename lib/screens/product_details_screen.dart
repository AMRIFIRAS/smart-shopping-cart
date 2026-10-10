import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/cart_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_art.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.cart,
  });
  final Product product;
  final CartController cart;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LText('Product details'),
      actions: [
        IconButton(
          key: const Key('details-cart'),
          tooltip: context.tr('Cart'),
          onPressed: () => Navigator.of(context).pushNamed('/cart'),
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
      ],
    ),
    body: SafeArea(
      child: PageBody(
        maxWidth: 900,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artwork = SurfaceCard(
              color: Color(product.backgroundColor),
              child: ProductArt(product: product, height: 270),
            );
            final detail = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('${product.brand} / ${product.category}'),
                const SizedBox(height: 10),
                LText(
                  product.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                LText(product.size, style: const TextStyle(color: muted)),
                const SizedBox(height: 14),
                LText(
                  money(product.priceHalalas),
                  style: const TextStyle(
                    color: forest,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                LText(
                  product.description,
                  style: const TextStyle(color: muted, height: 1.6),
                ),
                const SizedBox(height: 24),
                LText(
                  'A look inside',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                LText(
                  'Demo nutrition • ${product.nutritionBasis}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, box) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _nutrition(
                        (box.maxWidth - 10) / 2,
                        '${product.calories}',
                        'Calories (kcal)',
                      ),
                      _nutrition(
                        (box.maxWidth - 10) / 2,
                        '${product.protein} g',
                        'Protein',
                      ),
                      _nutrition(
                        (box.maxWidth - 10) / 2,
                        '${product.carbohydrates} g',
                        'Carbohydrates',
                      ),
                      _nutrition(
                        (box.maxWidth - 10) / 2,
                        '${product.fat} g',
                        'Fat',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                ListenableBuilder(
                  listenable: cart,
                  builder: (context, _) => SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('details-add'),
                      onPressed: () {
                        cart.add(product);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: LText('${product.name} added to cart.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: LText(
                        cart.quantityOf(product) == 0
                            ? 'Add to cart'
                            : 'Add another · ${cart.quantityOf(product)} in cart',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const InfoNote(
                  'Illustrative nutrition and packaging. Refer to the real product label for dietary decisions.',
                ),
              ],
            );
            return constraints.maxWidth >= 700
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: artwork),
                      const SizedBox(width: 32),
                      Expanded(child: detail),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [artwork, const SizedBox(height: 26), detail],
                  );
          },
        ),
      ),
    ),
  );
  Widget _nutrition(double width, String value, String label) => SizedBox(
    width: width,
    child: SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LText(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          LText(label, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    ),
  );
}
