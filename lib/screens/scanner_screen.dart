import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/cart_controller.dart';
import '../services/camera_environment.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_art.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    required this.cart,
    required this.onViewCart,
  });
  final CartController cart;
  final VoidCallback onViewCart;
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final input = TextEditingController();
  MobileScannerController? camera;
  bool showingCamera = false;
  bool starting = false;
  bool submitting = false;
  bool openingProduct = false;
  String? cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  String describeCameraError(MobileScannerException error) {
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
      return 'Camera access was denied. Allow Camera in Safari website settings, then try again.';
    }
    if (error.errorCode == MobileScannerErrorCode.unsupported) {
      return 'No camera is available. Use manual QR entry or select a product below.';
    }
    return 'Unable to start the camera. Close other camera apps and try again, or use manual entry.';
  }

  Future<void> startCamera() async {
    if (!cameraIsSecure) {
      setState(
        () => cameraError = 'Camera needs HTTPS. Open the public website to scan on your iPhone. Manual entry still works here.',
      );
      return;
    }
    if (starting) return;
    if (kIsWeb) {
      MobileScannerPlatform.instance.setWebBarcodeReader(
        WebBarcodeReader.zxingWasm,
      );
    }
    camera ??= MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 200,
    );
    setState(() {
      showingCamera = true;
      starting = true;
      cameraError = null;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      await camera!.start();
    } on MobileScannerException catch (error) {
      if (mounted) setState(() => cameraError = describeCameraError(error));
    } catch (_) {
      if (mounted) {
        setState(
          () => cameraError = 'Unable to start the camera. Close other camera apps and try again, or use manual entry.',
        );
      }
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  Future<void> stopCamera() async {
    if (camera != null) await camera!.stop();
    if (mounted) {
      setState(() {
        showingCamera = false;
        starting = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        camera?.value.hasCameraPermission == true) {
      unawaited(stopCamera());
    }
  }

  Future<void> submit(String payload, {bool fromCamera = false}) async {
    if (submitting || openingProduct) return;
    if (fromCamera &&
        !widget.cart.cameraCooldown.accept(payload, DateTime.now())) {
      return;
    }
    setState(() => submitting = true);
    final catalog = widget.cart.catalog;
    final product =
        catalog.findByPublicQr(payload) ??
        (fromCamera ? null : catalog.findById(payload.trim()));
    if (product == null) {
      // Compatibility for existing manual integrations/tests only. Final QR
      // labels contain public URLs and always take the preview-only path above.
      if (!fromCamera &&
          (catalog.findByQr(payload) != null ||
              catalog.findByBarcode(payload) != null)) {
        await widget.cart.scan(payload);
      } else {
        widget.cart.reportInvalidQr(payload);
      }
      if (mounted) setState(() => submitting = false);
      return;
    }
    openingProduct = true;
    if (showingCamera) await stopCamera();
    if (!mounted) return;
    setState(() => submitting = false);
    await Navigator.of(context).pushNamed('/product/${product.id}');
    openingProduct = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    input.dispose();
    unawaited(camera?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageBody(
    maxWidth: 800,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          eyebrow: 'Your shopping companion',
          title: 'Explore with a scan.',
          subtitle: 'Scan a product label to view its details. Add it to your cart when you are ready.',
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF173F30),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            children: [
              const Eyebrow('Camera QR scanner', color: Color(0xFFDAE6BB)),
              const SizedBox(height: 16),
              if (showingCamera)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 250,
                    child: MobileScanner(
                      controller: camera,
                      onDetect: (capture) {
                        if (!showingCamera || !mounted) return;
                        for (final code in capture.barcodes) {
                          if (code.rawValue != null) {
                            unawaited(submit(code.rawValue!, fromCamera: true));
                            break;
                          }
                        }
                      },
                      errorBuilder: (context, error) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LText(
                            describeCameraError(error),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFFE8EEDB),
                    size: 76,
                  ),
                ),
              const SizedBox(height: 14),
              LText(
                showingCamera
                    ? 'Point the camera at a product QR label.'
                    : 'Camera permission',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              LText(
                showingCamera
                    ? 'Scanning opens product details. It does not add the product to your cart.'
                    : 'Allow camera access to scan product QR labels. Video stays on your device and is never uploaded.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC7D7C8),
                  height: 1.6,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                key: const Key('camera-toggle'),
                onPressed: starting
                    ? null
                    : showingCamera
                    ? stopCamera
                    : startCamera,
                icon: Icon(
                  showingCamera
                      ? Icons.stop_circle_outlined
                      : Icons.camera_alt_outlined,
                ),
                label: LText(
                  starting
                      ? 'Starting camera…'
                      : showingCamera
                      ? 'Stop camera'
                      : 'Start camera',
                ),
              ),
            ],
          ),
        ),
        if (cameraError != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SurfaceCard(
              color: const Color(0xFFFFF0E8),
              child: InfoNote(cameraError!),
            ),
          ),
        const SizedBox(height: 24),
        LText(
          'Enter a product URL or ID.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('barcode-input'),
          controller: input,
          textDirection: TextDirection.ltr,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => submit(value),
          decoration: InputDecoration(
            labelText: context.tr('Product URL or ID'),
            hintText: 'P001',
            prefixIcon: const Icon(Icons.qr_code_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('scan-barcode'),
            onPressed: submitting ? null : () => submit(input.text),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: LText(submitting ? 'Scanning…' : 'View product'),
          ),
        ),
        ListenableBuilder(
          listenable: widget.cart,
          builder: (context, _) {
            final feedback = widget.cart.scanFeedback;
            if (feedback == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Semantics(
                liveRegion: true,
                child: SurfaceCard(
                  color: feedback.success
                      ? const Color(0xFFEDF3E5)
                      : const Color(0xFFFFEEEA),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            feedback.success
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: feedback.success
                                ? forest
                                : Colors.red.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LText(
                              feedback.message,
                              key: const Key('scan-feedback'),
                            ),
                          ),
                        ],
                      ),
                      if (feedback.success)
                        TextButton(
                          onPressed: widget.onViewCart,
                          child: LText(
                            'View cart · ${widget.cart.totalQuantity} items',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        LText(
          'Or, choose a product',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const LText(
          'Use the Add button to put a product in your cart.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...widget.cart.catalog.products.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurfaceCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 54,
                    child: ProductArt(product: product, height: 68),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LText(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.id,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                        LText(
                          money(product.priceHalalas),
                          style: const TextStyle(
                            color: forest,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('scan-${product.barcode}'),
                    tooltip: context.tr('Add to cart'),
                    onPressed: submitting
                        ? null
                        : () => widget.cart.scan(product.qrPayload),
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const InfoNote(
          'Your phone opens product details. Only the Add button changes your cart.',
        ),
      ],
    ),
  );
}
