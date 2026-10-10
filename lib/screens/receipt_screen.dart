import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({
    super.key,
    required this.order,
    required this.onNewTrip,
    this.history = false,
  });
  final Order order;
  final VoidCallback onNewTrip;
  final bool history;
  String get formattedDate {
    final date = order.createdAt;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LText('Your receipt'),
      automaticallyImplyLeading: history,
    ),
    body: SafeArea(
      child: PageBody(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFFE3EEDB),
                child: Icon(Icons.check_rounded, color: forest, size: 42),
              ),
            ),
            const SizedBox(height: 20),
            LText(
              'You’re good to go!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const LText(
              'A smarter shop, from first scan to last item.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 26),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: Eyebrow('Smart Cart / Demo receipt')),
                  const SizedBox(height: 20),
                  const LText(
                    'ORDER NUMBER',
                    style: TextStyle(
                      fontSize: 10,
                      color: muted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    order.number,
                    key: const Key('receipt-number'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LText(
                    '${DateFormat('d MMM yyyy, HH:mm', Localizations.localeOf(context).languageCode).format(order.createdAt)} (${context.tr('local time')})',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const Divider(),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
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
                                const SizedBox(height: 4),
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
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  SummaryRow('Total items', '${order.totalQuantity}'),
                  const SummaryRow('Additional charges', 'SAR 0.00'),
                  SummaryRow(
                    'Total',
                    money(order.totalHalalas),
                    emphasized: true,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: LText(
                      'SIMULATED · NO PAYMENT TAKEN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: forest,
                      ),
                    ),
                  ),
                  const Divider(),
                  const LText(
                    'Thank you for shopping a little smarter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('new-trip'),
              onPressed: () {
                if (history) {
                  Navigator.of(context).pop();
                  return;
                }
                onNewTrip();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              label: LText(history ? 'Close' : 'Start New Shopping Trip'),
            ),
            const SizedBox(height: 16),
            const InfoNote(
              'Keep a screenshot if you need a copy. Your signed-in orders are saved in Order history.',
            ),
          ],
        ),
      ),
    ),
  );
}
