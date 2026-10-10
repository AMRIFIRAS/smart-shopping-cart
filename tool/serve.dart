import 'dart:io';

/// Dependency-free static server for the built prototype. No application backend.
Future<void> main(List<String> arguments) async {
  final port = arguments.isEmpty ? 8080 : int.parse(arguments.first);
  final root = Directory('build/web').absolute;
  if (!File('${root.path}/index.html').existsSync()) {
    stderr.writeln('Build first: flutter build web --no-web-resources-cdn');
    exitCode = 1;
    return;
  }
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Smart Cart: http://localhost:$port');
  for (final interface in await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  )) {
    for (final address in interface.addresses) {
      stdout.writeln('LAN: http://${address.address}:$port');
    }
  }
  const types = {
    'html': 'text/html; charset=utf-8',
    'js': 'application/javascript',
    'json': 'application/json',
    'css': 'text/css',
    'wasm': 'application/wasm',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'pdf': 'application/pdf',
    'svg': 'image/svg+xml',
    'ttf': 'font/ttf',
    'otf': 'font/otf',
    'woff2': 'font/woff2',
  };
  await for (final request in server) {
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        continue;
      }
      final segments = request.uri.pathSegments;
      if (segments.any(
        (s) => s == '..' || s.contains('\\') || s.contains(':'),
      )) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        continue;
      }
      final path = segments.where((s) => s.isNotEmpty).join('/');
      var file = File('${root.path}/${path.isEmpty ? 'index.html' : path}');
      if (!await file.exists() && !path.split('/').last.contains('.')) {
        file = File('${root.path}/index.html');
      }
      if (!await file.exists()) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        continue;
      }
      request.response.headers.set(
        'Content-Type',
        types[file.path.split('.').last] ?? 'application/octet-stream',
      );
      request.response.headers.set('Cache-Control', 'no-cache');
      request.response.headers.set('X-Content-Type-Options', 'nosniff');
      if (request.method == 'GET') {
        await request.response.addStream(file.openRead());
      }
      await request.response.close();
    } catch (error) {
      stderr.writeln('Request error: $error');
      await request.response.close();
    }
  }
}
