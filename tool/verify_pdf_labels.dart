import 'dart:convert';
import 'dart:io';

import 'browser_session.dart';

/// Render the actual printable PDF and decode its five vector QR labels.
Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw ArgumentError('Provide final PDF path and public site origin.');
  }
  final encoded = base64Encode(await File(args[0]).readAsBytes());
  final browser = await BrowserSession.connect();
  try {
    final result = await browser.js('''(async () => {
      const pdfjs = await import('https://cdn.jsdelivr.net/npm/pdfjs-dist@4.10.38/build/pdf.min.mjs');
      pdfjs.GlobalWorkerOptions.workerSrc='https://cdn.jsdelivr.net/npm/pdfjs-dist@4.10.38/build/pdf.worker.min.mjs';
      const data=Uint8Array.from(atob('$encoded'),c=>c.charCodeAt(0));
      const pdf=await pdfjs.getDocument({data}).promise;
      if(pdf.numPages!==1) throw new Error('Expected one A4 page, got '+pdf.numPages);
      const page=await pdf.getPage(1), viewport=page.getViewport({scale:2});
      const canvas=document.createElement('canvas'); canvas.width=viewport.width; canvas.height=viewport.height;
      const context=canvas.getContext('2d');
      await page.render({canvasContext:context,viewport}).promise;
      if(!window.ZXingWASM) await new Promise((resolve,reject)=>{
        const script=document.createElement('script');
        script.src='https://cdn.jsdelivr.net/npm/zxing-wasm@3.1.3/dist/iife/reader/index.js';
        script.onload=resolve;script.onerror=reject;document.head.appendChild(script);
      });
      const codes=await ZXingWASM.readBarcodes(context.getImageData(0,0,canvas.width,canvas.height),{formats:['QRCode'],tryHarder:true});
      const text=(await page.getTextContent()).items.map(item=>item.str).join(' ');
      return {codes:codes.map(code=>code.text).sort(),text,png:canvas.toDataURL('image/png').split(',')[1]};
    })()''');
    final expected = List.generate(5, (i) => '${args[1]}/product/P00${i + 1}');
    if (jsonEncode(result['codes']) != jsonEncode(expected)) {
      throw StateError('PDF labels did not decode to all five public URLs.');
    }
    for (var i = 1; i <= 5; i++) {
      if (!(result['text'] as String).contains('Product ID: P00$i')) {
        throw StateError('Missing printable product ID P00$i.');
      }
    }
    await File('build/verification/final-pdf-labels.png')
        .writeAsBytes(base64Decode(result['png'] as String));
    stdout.writeln(
      'PASS one A4 page, all five labeled product IDs and five independently decoded public URL QRs.',
    );
  } finally {
    await browser.close();
  }
}
