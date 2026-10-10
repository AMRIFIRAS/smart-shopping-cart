import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';

class ProductArt extends StatelessWidget {
  const ProductArt({
    super.key,
    required this.product,
    this.height = 160,
    this.fit = BoxFit.contain,
  });
  final Product product;
  final double height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ClipRect(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          product.imageAsset!,
          width: double.infinity,
          height: double.infinity,
          fit: fit,
          semanticLabel: context.tr(product.name),
          errorBuilder: (_, _, _) =>
              const Icon(Icons.shopping_bag_outlined, size: 44),
        ),
      ),
    ),
  );
}
