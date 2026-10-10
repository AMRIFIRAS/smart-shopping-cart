import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/cart_controller.dart';
import 'app_theme.dart';
import 'common.dart';
import 'product_art.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({super.key, required this.item, required this.cart});
  final CartItem item;
  final CartController cart;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 68,
              decoration: BoxDecoration(
                color: Color(item.product.backgroundColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ProductArt(product: item.product, height: 78),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LText(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  LText(
                    '${item.product.size} · ${money(item.product.priceHalalas)} each',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              key: Key('remove-${item.product.barcode}'),
              tooltip: context.tr('Remove ${item.product.name}'),
              onPressed: () => cart.remove(item.product),
              icon: const Icon(Icons.close_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: Key('decrease-${item.product.barcode}'),
                    tooltip: context.tr('Decrease ${item.product.name}'),
                    onPressed: () => cart.decrease(item.product),
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  LText(
                    '${item.quantity}',
                    key: Key('quantity-${item.product.barcode}'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    key: Key('increase-${item.product.barcode}'),
                    tooltip: context.tr('Increase ${item.product.name}'),
                    onPressed: () => cart.add(item.product),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LText(
                money(item.subtotalHalalas),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
