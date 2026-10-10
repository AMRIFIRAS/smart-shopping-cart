import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../services/cart_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.cart});
  final CartController cart;
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String category = 'All';
  String query = '';
  @override
  Widget build(BuildContext context) {
    final products = widget.cart.catalog.products
        .where(
          (p) =>
              (category == 'All' || p.category == category) &&
              '${p.name} ${p.nameAr} ${p.brand}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            eyebrow: 'The everyday collection',
            title: 'Fresh picks for your cart',
            subtitle: 'A few familiar favourites. A smarter way to shop.',
          ),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: context.tr('Search your essentials'),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['All', 'Dairy', 'Drinks', 'Snacks']
                .map(
                  (value) => ChoiceChip(
                    label: LText(value == 'All' ? 'All products' : value),
                    selected: category == value,
                    onSelected: (_) => setState(() => category = value),
                    showCheckmark: false,
                    selectedColor: forest,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: category == value ? Colors.white : muted,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: category == value ? forest : border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          LText(
            '${products.length} essentials to explore',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            const SurfaceCard(
              child: InfoNote(
                'No products found. Try another name or category.',
                icon: Icons.search_off_rounded,
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 5
                  : constraints.maxWidth >= 700
                  ? 3
                  : constraints.maxWidth >= 310
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 14) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 18,
                children: products
                    .map(
                      (product) => SizedBox(
                        width: width,
                        child: ProductCard(
                          product: product,
                          onOpen: () =>
                              Navigator.of(context)
                                  .pushNamed('/product/${product.id}'),
                          onAdd: () {
                            widget.cart.add(product);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: LText(
                                  '${product.name} added to cart.',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          const InfoNote(
            'Demo products and prices. Nutrition is illustrative; check the actual package for accurate information.',
          ),
        ],
      ),
    );
  }
}
