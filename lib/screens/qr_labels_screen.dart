import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/qr_labels_pdf.dart';
import '../widgets/common.dart';
import '../widgets/product_art.dart';

class QrLabelsScreen extends StatefulWidget {
  const QrLabelsScreen({super.key, required this.products});
  final List<Product> products;
  @override
  State<QrLabelsScreen> createState() => _QrLabelsScreenState();
}

class _QrLabelsScreenState extends State<QrLabelsScreen> {
  bool busy = false;
  String? error;
  Future<void> export(bool print) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final bytes = await buildQrLabelsPdf(
        widget.products,
        arabic: AppStrings.of(context).isArabic,
      );
      if (print) {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: 'SmartCart product QR labels',
        );
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'smartcart-product-qr-labels.pdf',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Unable to prepare the labels. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LText('Product QR Labels')),
    body: SafeArea(
      child: PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              eyebrow: 'Ready for your demo',
              title: 'Product QR Labels',
              subtitle: 'Print these labels or save a PDF, then scan them with another device.',
            ),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : () => export(true),
                  icon: const Icon(Icons.print_outlined),
                  label: const LText('Print labels'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => export(false),
                  icon: const Icon(Icons.download_outlined),
                  label: const LText('Save PDF'),
                ),
              ],
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LText('Preparing labels…'),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LText(error!),
              ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: widget.products
                    .map(
                      (product) => SizedBox(
                        width: constraints.maxWidth >= 650
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth,
                        child: SurfaceCard(
                          child: Column(
                            children: [
                              LText(
                                product.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              ProductArt(product: product, height: 100),
                              QrImageView(
                                key: ValueKey('qr-${product.id}'),
                                data: product.qrPayload,
                                size: 176,
                                padding: const EdgeInsets.all(16),
                                backgroundColor: Colors.white,
                                semanticsLabel: product.qrPayload,
                              ),
                              LText(product.id),
                              SelectableText(
                                product.qrPayload,
                                textDirection: TextDirection.ltr,
                              ),
                              const SizedBox(height: 8),
                              const LText('Scan to add to your cart'),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
