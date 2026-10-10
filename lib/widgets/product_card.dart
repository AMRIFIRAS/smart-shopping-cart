import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../models/product.dart';
import 'app_theme.dart';
import 'product_art.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onOpen,
    required this.onAdd,
  });
  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: ink.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: Key('product-${product.barcode}'),
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      ProductArt(product: product, height: 150),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: LText(
                            product.size,
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LText(
                  product.brand.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: muted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: AppStrings.of(context).isArabic ? 62 : 44,
                  child: LText(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                LText(
                  money(product.priceHalalas),
                  style: const TextStyle(
                    color: forest,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: FilledButton.tonalIcon(
            key: Key('add-${product.barcode}'),
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              backgroundColor: const Color(0xFFECF3E8),
              foregroundColor: forest,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const LText('Add to cart', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    ),
  );
}
