import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/cart_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import 'receipt_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.onNewTrip,
  });
  final CartController cart;
  final VoidCallback onNewTrip;
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool completing = false;
  void complete() {
    if (completing || widget.cart.isEmpty) return;
    setState(() => completing = true);
    final order = widget.cart.checkout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptScreen(
          order: order,
          onNewTrip: () {
            widget.cart.startNewTrip();
            widget.onNewTrip();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LText('Checkout')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.cart,
        builder: (context, _) => PageBody(
          maxWidth: 700,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading(
                eyebrow: 'One last look',
                title: 'All set to check out?',
                subtitle:
                    'Review your picks and finish your demo shopping trip.',
              ),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LText(
                      'Order summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    ...widget.cart.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LText(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  LText(
                                    '${item.quantity} × ${money(item.product.priceHalalas)}',
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            LText(
                              money(item.subtotalHalalas),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    SummaryRow('Total items', '${widget.cart.totalQuantity}'),
                    const SummaryRow('Additional charges', 'SAR 0.00'),
                    SummaryRow(
                      'Total',
                      money(widget.cart.totalHalalas),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SurfaceCard(
                color: Color(0xFFECF3E6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_outlined, color: forest),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LText(
                            'Just a demo. All the convenience.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 6),
                          LText(
                            'No payment details needed. Completing this order creates a sample receipt and clears your cart.',
                            style: TextStyle(color: muted, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('complete-checkout'),
                  onPressed: completing || widget.cart.isEmpty
                      ? null
                      : complete,
                  icon: const Icon(Icons.check_rounded),
                  label: const LText('Complete demo checkout'),
                ),
              ),
              const SizedBox(height: 12),
              const InfoNote(
                'This is a simulated purchase. No money will be charged.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
