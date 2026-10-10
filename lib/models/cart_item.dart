import 'product.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity});
  final Product product;
  final int quantity;
  int get subtotalHalalas => product.priceHalalas * quantity;
}
