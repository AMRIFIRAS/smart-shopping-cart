import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final icon = img.Image(width: 800, height: 800)
    ..clear(img.ColorRgb8(23, 99, 68));
  final white = img.ColorRgb8(255, 255, 255);
  final lime = img.ColorRgb8(209, 230, 155);
  void line(int x1, int y1, int x2, int y2, img.Color color, int width) {
    img.drawLine(
      icon,
      x1: x1 * 8,
      y1: y1 * 8,
      x2: x2 * 8,
      y2: y2 * 8,
      color: color,
      thickness: width * 8,
    );
    img.fillCircle(icon, x: x1 * 8, y: y1 * 8, radius: width * 4, color: color);
    img.fillCircle(icon, x: x2 * 8, y: y2 * 8, radius: width * 4, color: color);
  }

  line(23, 29, 32, 29, white, 5);
  line(32, 29, 41, 64, white, 5);
  line(41, 64, 68, 64, white, 5);
  line(68, 64, 78, 39, white, 5);
  line(78, 39, 35, 39, white, 5);
  line(48, 49, 54, 55, lime, 3);
  line(54, 55, 65, 44, lime, 3);
  for (final x in [44, 66]) {
    img.fillCircle(icon, x: x * 8, y: 75 * 8, radius: 32, color: lime);
  }
  for (final size in [192, 512]) {
    final bytes = img.encodePng(
      img.copyResize(
        icon,
        width: size,
        interpolation: img.Interpolation.average,
      ),
    );
    File('web/icons/Icon-$size.png').writeAsBytesSync(bytes);
    File('web/icons/Icon-maskable-$size.png').writeAsBytesSync(bytes);
  }
  File('web/favicon.png').writeAsBytesSync(
    img.encodePng(
      img.copyResize(icon, width: 48, interpolation: img.Interpolation.average),
    ),
  );
}
