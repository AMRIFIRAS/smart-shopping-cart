import 'dart:async';

import 'barcode_scanner.dart';

/// UI and future FastAPI/WebSocket transports exchange these same QR payloads.
abstract class QrScanService implements BarcodeScanner {
  Stream<String> get payloads;
  Future<void> submit(String payload);
  @override
  Stream<String> get barcodes => payloads;
  @override
  Future<void> submitBarcode(String barcode) => submit(barcode);
}

class LocalQrScanService extends QrScanService {
  final _events = StreamController<String>.broadcast(sync: true);
  @override
  Stream<String> get payloads => _events.stream;
  @override
  Future<void> submit(String payload) async => _events.add(payload);
  @override
  void dispose() => _events.close();
}

/// Sliding cooldown: every observed frame extends the quiet period. A continuously
/// visible code is added once, even after many seconds. Remove it for 2 seconds
/// before presenting it again. Manual submissions intentionally bypass this gate.
class QrScanCooldown {
  QrScanCooldown({this.quietPeriod = const Duration(seconds: 2)});
  final Duration quietPeriod;
  final Map<String, DateTime> _lastSeen = {};
  bool accept(String payload, DateTime now) {
    final key = payload.trim();
    final previous = _lastSeen[key];
    _lastSeen[key] = now;
    _lastSeen.removeWhere(
      (key, value) => now.difference(value) > const Duration(minutes: 1),
    );
    return previous == null || now.difference(previous) >= quietPeriod;
  }
}
