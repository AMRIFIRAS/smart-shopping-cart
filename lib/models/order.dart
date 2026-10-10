import 'cart_item.dart';

/// An immutable receipt snapshot, independent of the next shopping trip.
class Order {
  Order({
    required this.number,
    required this.createdAt,
    required List<CartItem> items,
  }) : items = List.unmodifiable(items);
  final String number;
  final DateTime createdAt;
  final List<CartItem> items;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  int get totalHalalas =>
      items.fold(0, (sum, item) => sum + item.subtotalHalalas);
}
