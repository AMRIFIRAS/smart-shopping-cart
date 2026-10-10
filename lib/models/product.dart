enum ProductShape { carton, bottle, bar, bag }

/// Prices use whole halalas to avoid floating-point rounding errors.
class Product {
  const Product({
    required this.id,
    required this.nameAr,
    required this.descriptionAr,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.size,
    required this.priceHalalas,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.nutritionBasis,
    required this.description,
    required this.shape,
    required this.color,
    required this.backgroundColor,
    required this.artLabel,
    this.imageAsset,
  });
  final String barcode;
  final String id;
  final String nameAr;
  final String descriptionAr;
  // Historical manual scanner adapter, retained for the original integrations.
  // Never encode this value in final labels: use ProductLinks.urlFor(id).
  String get qrPayload => 'SMARTCART:$id';
  final String name;
  final String brand;
  final String category;
  final String size;
  final int priceHalalas;
  final int calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final String nutritionBasis;
  final String description;
  final ProductShape shape;
  final int color;
  final int backgroundColor;
  final String artLabel;

  /// Set an asset path and register it in pubspec.yaml to replace the illustration.
  final String? imageAsset;
}

String money(int halalas) => 'SAR ${(halalas / 100).toStringAsFixed(2)}';
