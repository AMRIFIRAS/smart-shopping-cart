import 'dart:async';

import 'product_catalog.dart';
import 'product_links.dart';

class RobotScanFailure implements Exception {
  const RobotScanFailure(this.code);
  final String code;
  @override
  String toString() => 'RobotScanFailure($code)';
}

/// Exact future FastAPI request body. Robot identity and idempotency are carried
/// by authenticated transport metadata, never trusted from this JSON body.
class RobotScanMessage {
  RobotScanMessage({
    required this.cartId,
    required this.productId,
    this.source = 'raspberry-pi',
  }) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(cartId) ||
        !RegExp(r'^P\d{3}$').hasMatch(productId) ||
        source != 'raspberry-pi') {
      throw const RobotScanFailure('invalid-message');
    }
  }
  final String cartId;
  final String productId;
  final String source;
  factory RobotScanMessage.fromJson(Map<String, dynamic> json) {
    if (json.length != 3 ||
        json['cart_id'] is! String ||
        json['product_id'] is! String ||
        json['source'] is! String) {
      throw const RobotScanFailure('invalid-message');
    }
    return RobotScanMessage(
      cartId: json['cart_id'] as String,
      productId: json['product_id'] as String,
      source: json['source'] as String,
    );
  }
  Map<String, String> toJson() => {
    'cart_id': cartId,
    'product_id': productId,
    'source': source,
  };
}

class RobotCartUpdate {
  RobotCartUpdate({
    required this.cartId,
    required this.productId,
    required this.eventId,
    required Map<String, int> quantities,
  }) : quantities = Map.unmodifiable(quantities);
  final String cartId, productId, eventId;
  final Map<String, int> quantities;
}

abstract class RobotScanService {
  Stream<RobotCartUpdate> updatesFor(
    String cartId, {
    required String authenticatedOwnerId,
  });
  Future<RobotCartUpdate> send({
    required String authenticatedRobotId,
    required String eventId,
    required RobotScanMessage message,
  });
}

abstract class CartPairingService {
  void pair({
    required String robotId,
    required String cartId,
    required String authenticatedOwnerId,
  });
  void unpair(String robotId);
  String? pairedCartId(String robotId);
}

class SimulatedCart {
  SimulatedCart({required this.id, required this.ownerId});
  final String id, ownerId;
  bool _active = true;
  final Map<String, int> _quantities = {};
  bool get active => _active;
  Map<String, int> get quantities => Map.unmodifiable(_quantities);
}

/// Local contract simulator only. These owner/robot strings are trusted test
/// identities, NOT a substitute for authentication or a connected backend.
class SimulatedRobotBackend implements RobotScanService, CartPairingService {
  SimulatedRobotBackend(this.catalog);
  final ProductCatalog catalog;
  final Map<String, SimulatedCart> _carts = {};
  final Map<String, String> _pairings = {};
  final Map<(String, String), RobotCartUpdate> _events = {};
  final _updates = StreamController<RobotCartUpdate>.broadcast(sync: true);

  SimulatedCart createCart(String id, String ownerId) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id) ||
        ownerId.isEmpty ||
        _carts.containsKey(id)) {
      throw const RobotScanFailure('invalid-cart');
    }
    return _carts[id] = SimulatedCart(id: id, ownerId: ownerId);
  }

  @override
  void pair({
    required String robotId,
    required String cartId,
    required String authenticatedOwnerId,
  }) {
    final cart = _carts[cartId];
    if (robotId.isEmpty || cart == null || !cart.active) {
      throw const RobotScanFailure('inactive-cart');
    }
    if (cart.ownerId != authenticatedOwnerId) {
      throw const RobotScanFailure('wrong-owner');
    }
    // One robot per cart, one active cart per robot. Re-pairing revokes the old
    // association so a late scan cannot be credited to a previous shopper.
    _pairings.removeWhere((key, value) => value == cartId);
    _pairings[robotId] = cartId;
  }

  @override
  void unpair(String robotId) => _pairings.remove(robotId);
  @override
  String? pairedCartId(String robotId) => _pairings[robotId];
  void closeCart(String cartId) {
    final cart = _carts[cartId];
    if (cart == null) throw const RobotScanFailure('unknown-cart');
    cart._active = false;
    _pairings.removeWhere((_, value) => value == cartId);
  }

  @override
  Stream<RobotCartUpdate> updatesFor(
    String cartId, {
    required String authenticatedOwnerId,
  }) {
    if (_carts[cartId]?.ownerId != authenticatedOwnerId) {
      throw const RobotScanFailure('wrong-owner');
    }
    return _updates.stream.where((event) => event.cartId == cartId);
  }

  @override
  Future<RobotCartUpdate> send({
    required String authenticatedRobotId,
    required String eventId,
    required RobotScanMessage message,
  }) async {
    if (eventId.isEmpty || eventId.length > 128) {
      throw const RobotScanFailure('invalid-event');
    }
    final paired = _pairings[authenticatedRobotId];
    if (paired == null) throw const RobotScanFailure('robot-not-paired');
    if (paired != message.cartId) throw const RobotScanFailure('cart-mismatch');
    final cart = _carts[paired]!;
    if (!cart.active) throw const RobotScanFailure('inactive-cart');
    if (catalog.findById(message.productId) == null) {
      throw const RobotScanFailure('unknown-product');
    }
    final key = (authenticatedRobotId, eventId);
    final previous = _events[key];
    if (previous != null) {
      if (previous.cartId != message.cartId ||
          previous.productId != message.productId) {
        throw const RobotScanFailure('event-conflict');
      }
      return previous; // Same request retry, no extra quantity or broadcast.
    }
    cart._quantities.update(
      message.productId,
      (quantity) => quantity + 1,
      ifAbsent: () => 1,
    );
    final update = RobotCartUpdate(
      cartId: paired,
      productId: message.productId,
      eventId: eventId,
      quantities: cart.quantities,
    );
    _events[key] = update;
    _updates.add(update);
    return update;
  }

  Future<void> dispose() => _updates.close();
}

/// Simulates the Pi QR decoder and its raw-frame debounce before the transport.
class RobotScanSimulator {
  RobotScanSimulator({
    required this.links,
    required this.pairing,
    required this.transport,
  });
  final ProductLinks links;
  final CartPairingService pairing;
  final RobotScanService transport;
  final Map<String, DateTime> _lastSeen = {};
  int _sequence = 0;
  Future<RobotCartUpdate?> scan({
    required String robotId,
    required String qrUrl,
    DateTime? now,
  }) async {
    final productId = links.idFromUrl(qrUrl);
    if (productId == null) throw const RobotScanFailure('invalid-qr');
    final cartId = pairing.pairedCartId(robotId);
    if (cartId == null) throw const RobotScanFailure('robot-not-paired');
    final time = now ?? DateTime.now();
    final key = '$robotId:$cartId:$productId';
    final previous = _lastSeen[key];
    _lastSeen[key] = time;
    _lastSeen.removeWhere(
      (_, last) => time.difference(last) > const Duration(minutes: 1),
    );
    if (previous != null &&
        time.difference(previous) < const Duration(seconds: 2)) {
      return null;
    }
    final update = await transport.send(
      authenticatedRobotId: robotId,
      eventId: 'simulation-${time.microsecondsSinceEpoch}-${++_sequence}',
      message: RobotScanMessage(cartId: cartId, productId: productId),
    );
    return update;
  }
}
