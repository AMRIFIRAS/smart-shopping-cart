import 'package:web/web.dart' as web;

void updateDocumentLocale(String language) {
  final root = web.document.documentElement;
  root?.setAttribute('lang', language);
  // Flutter handles RTL internally. A second RTL transform on the host document
  // moves accessibility hit targets outside the canvas after switching language.
  root?.setAttribute('dir', 'ltr');
}
