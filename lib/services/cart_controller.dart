import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'barcode_scanner.dart';
import 'product_catalog.dart';
import 'local_store.dart';
import 'qr_scan_service.dart';

class ScanFeedback {
  const ScanFeedback(this.message, {required this.success});
  final String message;
  final bool success;
}

/// Single source of truth for cart quantities and incoming barcode events.
class CartController extends ChangeNotifier {
  CartController({required this.catalog, required this.scanner, this.store}) {
    _restore();
    _subscription = scanner.barcodes.listen(
      _handleBarcode,
      onError: (Object error) {
        scanFeedback = const ScanFeedback(
          'Scanner unavailable. Please try again.',
          success: false,
        );
        notifyListeners();
      },
    );
  }
  final ProductCatalog catalog;
  final BarcodeScanner scanner;
  final LocalStore? store;
  final QrScanCooldown cameraCooldown = QrScanCooldown();
  void Function(Order)? onCheckout;
  bool storageFailed = false;
  Future<void> _pendingSave = Future.value();
  Future<void> get saved => _pendingSave;

  void _restore() {
    try {
      final encoded = store?.read('smartcart.cart.v1');
      if (encoded == null) return;
      final data = jsonDecode(encoded) as List;
      for (final row in data) {
        final product = catalog.findById(row['id'] as String);
        final quantity = row['quantity'];
        if (product != null &&
            quantity is int &&
            quantity > 0 &&
            quantity <= 9999) {
          _items[product.barcode] = CartItem(
            product: product,
            quantity: quantity,
          );
        }
      }
    } catch (_) {
      _items.clear();
    }
  }

  @override
  void notifyListeners() {
    if (store != null) {
      final snapshot = jsonEncode(
        items
            .map((item) => {'id': item.product.id, 'quantity': item.quantity})
            .toList(),
      );
      _pendingSave = _pendingSave
          .then((_) => store!.write('smartcart.cart.v1', snapshot))
          .catchError((Object error) {
            storageFailed = true;
          });
    }
    super.notifyListeners();
  }

  Future<bool> scanCamera(String payload, {DateTime? now}) async {
    if (!cameraCooldown.accept(payload, now ?? DateTime.now())) return false;
    // Camera and robot inputs use QR exclusively; legacy codes stay available only
    // through the original manual adapter for backward compatibility with the demo.
    if (catalog.findByQr(payload) == null) {
      scanFeedback = const ScanFeedback(
        'Unknown or invalid QR code. Use a SmartCart product label.',
        success: false,
      );
      notifyListeners();
      return false;
    }
    await scan(payload);
    return true;
  }

  void reportInvalidQr(String payload) {
    scanFeedback = ScanFeedback(
      payload.trim().isEmpty
          ? 'Enter a product URL or ID.'
          : 'Unknown or invalid QR code. Use a SmartCart product label.',
      success: false,
    );
    notifyListeners();
  }

  final Map<String, CartItem> _items = {};
  late final StreamSubscription<String> _subscription;
  int _orderSequence = 0;
  ScanFeedback? scanFeedback;
  List<CartItem> get items => List.unmodifiable(_items.values);
  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  int get totalHalalas =>
      _items.values.fold(0, (sum, item) => sum + item.subtotalHalalas);
  bool get isEmpty => _items.isEmpty;
  int quantityOf(Product product) => _items[product.barcode]?.quantity ?? 0;

  void add(Product product) {
    _items[product.barcode] = CartItem(
      product: product,
      quantity: quantityOf(product) + 1,
    );
    notifyListeners();
  }

  void decrease(Product product) {
    final quantity = quantityOf(product);
    if (quantity == 0) return;
    if (quantity == 1) {
      _items.remove(product.barcode);
    } else {
      _items[product.barcode] = CartItem(
        product: product,
        quantity: quantity - 1,
      );
    }
    notifyListeners();
  }

  void remove(Product product) {
    if (_items.remove(product.barcode) != null) notifyListeners();
  }

  Future<void> scan(String barcode) async {
    try {
      await scanner.submitBarcode(barcode);
    } catch (_) {
      scanFeedback = const ScanFeedback(
        'Scanner unavailable. Please try again.',
        success: false,
      );
      notifyListeners();
    }
  }

  void _handleBarcode(String barcode) {
    final product = catalog.findByQr(barcode) ?? catalog.findByBarcode(barcode);
    if (product == null) {
      scanFeedback = ScanFeedback(
        barcode.trim().isEmpty
            ? 'Enter a QR payload to scan.'
            : 'Unknown or invalid QR code. Use a SmartCart product label.',
        success: false,
      );
      notifyListeners();
      return;
    }
    _items[product.barcode] = CartItem(
      product: product,
      quantity: quantityOf(product) + 1,
    );
    scanFeedback = ScanFeedback(
      '${product.name} added to cart.',
      success: true,
    );
    notifyListeners();
  }

  Order checkout({DateTime? now}) {
    if (isEmpty) throw StateError('Add a product before checking out.');
    final createdAt = now ?? DateTime.now();
    _orderSequence++;
    final order = Order(
      number: 'SC-${createdAt.microsecondsSinceEpoch}-$_orderSequence',
      createdAt: createdAt,
      items: items,
    );
    _items.clear();
    scanFeedback = null;
    onCheckout?.call(order);
    notifyListeners();
    return order;
  }

  void startNewTrip() {
    _items.clear();
    scanFeedback = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    scanner.dispose();
    super.dispose();
  }
}
