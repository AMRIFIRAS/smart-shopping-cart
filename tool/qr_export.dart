import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';

import 'package:smart_shopping_cart/models/product.dart';
import 'package:smart_shopping_cart/services/product_links.dart';

const qrFileNames = <String, String>{
  'P001': '01_Almarai_Full_Fat_Milk_QR.png',
  'P002': '02_Nadec_Orange_Juice_QR.png',
  'P003': '03_Berain_Water_QR.png',
  'P004': '04_Twix_Chocolate_QR.png',
  'P005': '05_Doritos_Chips_QR.png',
};

Uint8List renderProductLabel(Product product, ProductLinks links) {
  final url = links.urlFor(product.id);
  final canvas = img.Image(width: 1400, height: 1700)
    ..clear(img.ColorRgb8(255, 255, 255));
  final green = img.ColorRgb8(23, 99, 68), black = img.ColorRgb8(20, 35, 28);
  img.fillRect(canvas, x1: 0, y1: 0, x2: 1399, y2: 112, color: green);
  img.drawString(
    canvas,
    'SmartCart',
    font: img.arial48,
    x: 72,
    y: 32,
    color: img.ColorRgb8(255, 255, 255),
  );
  img.drawString(
    canvas,
    product.name,
    font: img.arial48,
    x: 72,
    y: 175,
    color: black,
  );
  img.drawString(
    canvas,
    'Product ID: ${product.id}',
    font: img.arial48,
    x: 72,
    y: 255,
    color: green,
  );
  final qr = QrImage(
    QrCode.fromData(data: url, errorCorrectLevel: QrErrorCorrectLevel.M),
  );
  final module = 1080 ~/ (qr.moduleCount + 8);
  final dimension = (qr.moduleCount + 8) * module;
  final left = (1400 - dimension) ~/ 2 + module * 4;
  final top = 370 + (1080 - dimension) ~/ 2 + module * 4;
  for (var row = 0; row < qr.moduleCount; row++) {
    for (var column = 0; column < qr.moduleCount; column++) {
      if (qr.isDark(row, column)) {
        img.fillRect(
          canvas,
          x1: left + column * module,
          y1: top + row * module,
          x2: left + (column + 1) * module - 1,
          y2: top + (row + 1) * module - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
  }
  img.drawString(
    canvas,
    'Scan to view product details',
    font: img.arial48,
    x: 72,
    y: 1470,
    color: green,
  );
  img.drawString(canvas, url, font: img.arial24, x: 72, y: 1570, color: black);
  return Uint8List.fromList(img.encodePng(canvas));
}

Future<Uint8List> renderLabelPdf(
  List<Product> products,
  ProductLinks links,
  ByteData fontBytes, {
  bool arabic = false,
}) async {
  final font = pw.Font.ttf(fontBytes);
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: font, bold: font),
      build: (_) => [
        pw.Text(
          'SmartCart — Product QR Codes',
          style: const pw.TextStyle(fontSize: 18),
        ),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: products.map((product) {
            final url = links.urlFor(product.id);
            return pw.Container(
              width: 260,
              height: 230,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    arabic ? product.nameAr : product.name,
                    textDirection: arabic
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    style: const pw.TextStyle(fontSize: 13),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Product ID: ${product.id}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(
                      errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
                    ),
                    data: url,
                    width: 126,
                    height: 126,
                    padding: const pw.EdgeInsets.all(12),
                    backgroundColor: PdfColors.white,
                    textStyle: pw.TextStyle(font: font),
                  ),
                  pw.SizedBox(height: 7),
                  pw.Text(
                    url,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Scan to view details. Add to cart on the website.',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
  return doc.save();
}
