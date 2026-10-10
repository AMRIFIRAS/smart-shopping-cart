import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Original SmartCart mark: a shopping basket with a checked scan.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _BrandPainter()),
  );
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(26),
      ),
      Paint()..color = forest,
    );
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(23, 29)
        ..lineTo(32, 29)
        ..lineTo(41, 64)
        ..lineTo(68, 64)
        ..lineTo(78, 39)
        ..lineTo(35, 39),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(48, 49)
        ..lineTo(54, 55)
        ..lineTo(65, 44),
      stroke
        ..color = const Color(0xFFD1E69B)
        ..strokeWidth = 3.5,
    );
    final wheel = Paint()..color = const Color(0xFFD1E69B);
    canvas.drawCircle(const Offset(44, 75), 4, wheel);
    canvas.drawCircle(const Offset(66, 75), 4, wheel);
  }

  @override
  bool shouldRepaint(_BrandPainter oldDelegate) => false;
}
