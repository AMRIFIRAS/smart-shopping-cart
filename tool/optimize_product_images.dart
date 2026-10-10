import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  for (final name in ['almarai', 'nadec', 'berain', 'twix', 'doritos']) {
    final decoded = img.decodeImage(
      File('.dart_tool/raw-images/$name').readAsBytesSync(),
    )!;
    // Flatten transparent official packshots onto a consistent warm white canvas.
    final fitted = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? 700 : null,
      height: decoded.height > decoded.width ? 700 : null,
      interpolation: img.Interpolation.average,
    );
    final square = img.Image(width: 768, height: 768)
      ..clear(img.ColorRgb8(255, 255, 255));
    img.compositeImage(
      square,
      fitted,
      dstX: (768 - fitted.width) ~/ 2,
      dstY: (768 - fitted.height) ~/ 2,
    );
    final encoded = img.encodeJpg(square, quality: 88);
    File('assets/products/$name.jpg').writeAsBytesSync(encoded);
    stdout.writeln(
      '$name: ${decoded.width}x${decoded.height} -> 768x768, ${encoded.length} bytes',
    );
  }
}
