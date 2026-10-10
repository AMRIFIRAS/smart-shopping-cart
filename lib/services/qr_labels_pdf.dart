import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/product.dart';
import 'product_links.dart';

Future<Uint8List> buildQrLabelsPdf(
  List<Product> products, {
  bool arabic = false,
  ProductLinks? links,
}) async {
  final productLinks = links ?? ProductLinks.forApplication();
  final font = pw.Font.ttf(
    await rootBundle.load(
      arabic
          ? 'assets/fonts/NotoSansArabic.ttf'
          : 'assets/fonts/roboto-regular.ttf',
    ),
  );
  final cards = <pw.Widget>[];
  for (final product in products) {
    final photo = pw.MemoryImage(
      (await rootBundle.load(product.imageAsset!)).buffer.asUint8List(),
    );
    cards.add(
      pw.Container(
        width: 260,
        height: 218,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              arabic ? product.nameAr : product.name,
              textDirection: arabic
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              style: pw.TextStyle(font: font, fontSize: 13),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Image(photo, width: 75, height: 105, fit: pw.BoxFit.contain),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  textStyle: pw.TextStyle(font: font),
                  data: productLinks.urlFor(product.id),
                  width: 110,
                  height: 110,
                  padding: const pw.EdgeInsets.all(8),
                  backgroundColor: PdfColors.white,
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(product.id, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text(
              productLinks.urlFor(product.id),
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: font),
      build: (_) => [
        pw.Text(
          arabic
              ? 'SmartCart — ملصقات المنتجات'
              : 'SmartCart — Product QR Labels',
          textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          style: const pw.TextStyle(fontSize: 20),
        ),
        pw.SizedBox(height: 14),
        pw.Wrap(spacing: 12, runSpacing: 12, children: cards),
      ],
    ),
  );
  return document.save();
}
