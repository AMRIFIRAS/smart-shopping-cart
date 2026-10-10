import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Reproducible camera input for the real web scanner; not a production asset.
void main(List<String> args) {
  const width = 640, height = 480, module = 8;
  final qr = QrImage(
    QrCode.fromData(
      data: args.isEmpty ? 'http://localhost:8080/product/P001' : args.single,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    ),
  );
  final image = img.Image(width: width, height: height)
    ..clear(img.ColorRgb8(255, 255, 255));
  final left = (width - qr.moduleCount * module) ~/ 2;
  final top = (height - qr.moduleCount * module) ~/ 2;
  for (var y = 0; y < qr.moduleCount; y++) {
    for (var x = 0; x < qr.moduleCount; x++) {
      if (qr.isDark(y, x)) {
        img.fillRect(
          image,
          x1: left + x * module,
          y1: top + y * module,
          x2: left + (x + 1) * module - 1,
          y2: top + (y + 1) * module - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
  }
  final folder = Directory('.dart_tool/camera-fixture')
    ..createSync(recursive: true);
  File('${folder.path}/qr.png').writeAsBytesSync(img.encodePng(image));
  final frame = Uint8List(width * height * 3 ~/ 2);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      frame[y * width + x] = image.getPixel(x, y).r > 128 ? 235 : 16;
    }
  }
  frame.fillRange(width * height, frame.length, 128);
  final file = File('${folder.path}/qr.y4m').openSync(mode: FileMode.write);
  file.writeStringSync('YUV4MPEG2 W640 H480 F30:1 Ip A1:1 C420jpeg\nFRAME\n');
  file.writeFromSync(frame);
  file.closeSync();
  stdout.writeln('Created QR camera fixture: ${folder.path}/qr.y4m');
}
