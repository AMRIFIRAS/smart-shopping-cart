import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import 'app_theme.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 1120});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
          ),
          child: child,
        ),
      ),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: ink.withValues(alpha: 0.035),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = forest});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    AppStrings.of(context).isArabic ? context.tr(text) : text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: AppStrings.of(context).isArabic ? 0 : 1.8,
      color: color,
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow(eyebrow),
      const SizedBox(height: 10),
      LText(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      LText(subtitle, style: const TextStyle(color: muted, height: 1.5)),
      const SizedBox(height: 24),
    ],
  );
}

class InfoNote extends StatelessWidget {
  const InfoNote(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
  });
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: muted),
      const SizedBox(width: 9),
      Expanded(
        child: LText(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    ],
  );
}

class SummaryRow extends StatelessWidget {
  const SummaryRow(
    this.label,
    this.value, {
    super.key,
    this.emphasized = false,
  });
  final String label;
  final String value;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LText(
            label,
            style: TextStyle(
              color: emphasized ? ink : muted,
              fontSize: emphasized ? 18 : 14,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: LText(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: ink,
              fontSize: emphasized ? 20 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
