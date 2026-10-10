import 'dart:async';

/// A future WebSocket implementation will publish received barcode events here.
abstract class BarcodeScanner {
  Stream<String> get barcodes;
  Future<void> submitBarcode(String barcode);
  void dispose();
}

class MockBarcodeScanner implements BarcodeScanner {
  final _events = StreamController<String>.broadcast(sync: true);
  @override
  Stream<String> get barcodes => _events.stream;
  @override
  Future<void> submitBarcode(String barcode) async => _events.add(barcode);
  @override
  void dispose() => _events.close();
}
