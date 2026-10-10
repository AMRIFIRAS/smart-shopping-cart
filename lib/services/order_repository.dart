import 'dart:convert';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'local_store.dart';

/// Replace this repository with a per-user cloud implementation without changing UI.
abstract class OrderRepository {
  List<Order> read(String uid);
  Future<void> write(String uid, List<Order> orders);
}

class LocalOrderRepository implements OrderRepository {
  LocalOrderRepository(this.store);
  final LocalStore store;
  @override
  List<Order> read(String uid) {
    try {
      final raw = store.read('smartcart.orders.$uid');
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map(
            (dynamic data) => Order(
              number: data['number'] as String,
              createdAt: DateTime.parse(data['createdAt'] as String),
              items: (data['items'] as List)
                  .map(
                    (dynamic line) => CartItem(
                      quantity: line['quantity'] as int,
                      product: Product(
                        id: line['id'] as String,
                        barcode: line['barcode'] as String,
                        name: line['name'] as String,
                        nameAr: line['nameAr'] as String,
                        description: '',
                        descriptionAr: '',
                        brand: line['brand'] as String,
                        category: '',
                        size: line['size'] as String,
                        priceHalalas: line['priceHalalas'] as int,
                        calories: 0,
                        protein: 0,
                        carbohydrates: 0,
                        fat: 0,
                        nutritionBasis: '',
                        shape: ProductShape.carton,
                        color: 0xFF176344,
                        backgroundColor: 0xFFF4F3EF,
                        artLabel: '',
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> write(String uid, List<Order> orders) => store.write(
    'smartcart.orders.$uid',
    jsonEncode(
      orders
          .map(
            (order) => {
              'number': order.number,
              'createdAt': order.createdAt.toIso8601String(),
              'items': order.items
                  .map(
                    (line) => {
                      'id': line.product.id,
                      'barcode': line.product.barcode,
                      'name': line.product.name,
                      'nameAr': line.product.nameAr,
                      'brand': line.product.brand,
                      'size': line.product.size,
                      'priceHalalas': line.product.priceHalalas,
                      'quantity': line.quantity,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    ),
  );
}
