import 'dart:convert';
import 'dart:io';

import 'package:smart_shopping_cart/data/demo_products.dart';
import 'package:smart_shopping_cart/services/product_catalog.dart';
import 'package:smart_shopping_cart/services/product_links.dart';
import 'package:smart_shopping_cart/services/robot_scan_service.dart';

Future<void> main() async {
  // Deliberately non-public fixture; this tool never creates final QR labels.
  final links = ProductLinks(Uri.parse('https://simulation.invalid'));
  final backend = SimulatedRobotBackend(
    ProductCatalog(demoProducts, links: links),
  );
  final alice = backend.createCart('cart-alice', 'simulated-alice');
  final bob = backend.createCart('cart-bob', 'simulated-bob');
  backend.pair(
    robotId: 'robot-1',
    cartId: alice.id,
    authenticatedOwnerId: alice.ownerId,
  );
  backend.pair(
    robotId: 'robot-2',
    cartId: bob.id,
    authenticatedOwnerId: bob.ownerId,
  );
  final simulator = RobotScanSimulator(
    links: links,
    pairing: backend,
    transport: backend,
  );
  final start = DateTime.utc(2026, 9, 17);
  await simulator.scan(
    robotId: 'robot-1',
    qrUrl: links.urlFor('P001'),
    now: start,
  );
  await simulator.scan(
    robotId: 'robot-1',
    qrUrl: links.urlFor('P001'),
    now: start.add(const Duration(milliseconds: 300)),
  );
  await simulator.scan(
    robotId: 'robot-2',
    qrUrl: links.urlFor('P005'),
    now: start,
  );
  stdout.writeln('LOCAL SIMULATOR ONLY — no robot or backend connected.');
  stdout.writeln(
    jsonEncode(RobotScanMessage(cartId: alice.id, productId: 'P001').toJson()),
  );
  stdout.writeln('Alice: ${jsonEncode(alice.quantities)}');
  stdout.writeln('Bob: ${jsonEncode(bob.quantities)}');
  try {
    await backend.send(
      authenticatedRobotId: 'robot-1',
      eventId: 'wrong-cart',
      message: RobotScanMessage(cartId: bob.id, productId: 'P001'),
    );
    throw StateError('A cross-cart scan was incorrectly accepted.');
  } on RobotScanFailure catch (error) {
    if (error.code != 'cart-mismatch') rethrow;
    stdout.writeln('PASS: mismatched cart rejected.');
  }
  if (alice.quantities['P001'] != 1 ||
      bob.quantities['P005'] != 1 ||
      bob.quantities.containsKey('P001')) {
    throw StateError('Robot simulation failed.');
  }
  stdout.writeln('PASS: paired cart routing and duplicate-frame suppression.');
  await backend.dispose();
}
