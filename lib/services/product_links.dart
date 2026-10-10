/// Canonical product links shared by the website, external labels and robot.
/// No placeholder public URL is generated: deployment supplies PUBLIC_SITE_URL.
class ProductLinks {
  ProductLinks(this.origin, {bool allowLocalHttp = false}) {
    final local = ['localhost', '127.0.0.1'].contains(origin.host);
    if ((!origin.isScheme('https') &&
            !(allowLocalHttp && local && origin.isScheme('http'))) ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw ArgumentError('A canonical HTTPS site origin is required.');
    }
  }
  final Uri origin;

  factory ProductLinks.forApplication() {
    const configured = String.fromEnvironment('PUBLIC_SITE_URL');
    if (configured.isNotEmpty) return ProductLinks(Uri.parse(configured));
    // Local preview only. Production will be built with its actual HTTPS origin.
    final base = Uri.base;
    if (base.isScheme('https')) return ProductLinks(Uri.parse(base.origin));
    return ProductLinks(
      Uri.parse('http://localhost:8080'),
      allowLocalHttp: true,
    );
  }

  String urlFor(String id) {
    if (!RegExp(r'^P\d{3}$').hasMatch(id)) {
      throw ArgumentError('Invalid product ID.');
    }
    return origin.resolve('/product/$id').toString();
  }

  String? idFromUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.scheme != origin.scheme ||
        uri.host != origin.host ||
        uri.port != origin.port ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return idFromPath(uri.path);
  }

  static String? idFromPath(String path) =>
      RegExp(r'^/product/(P\d{3})$').firstMatch(path)?.group(1);
}
