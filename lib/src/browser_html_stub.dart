// Minimal stub to allow mobile builds when code conditionally imports `dart:html`.
// The real `dart:html` is only available when building for web.
// This file provides tiny no-op implementations of the few symbols used
// (Blob, Url.createObjectUrlFromBlob, AnchorElement, document.body.children).

class Blob {
  final List<dynamic>? data;
  final String? type;
  Blob([this.data, this.type]);
}

class Url {
  // Return a dummy string on non-web platforms.
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String? url) {}
}

class _Style {
  String display = '';
}

class AnchorElement {
  String? href;
  final _Style style = _Style();
  AnchorElement({this.href});
  void setAttribute(String name, String value) {}
  void click() {}
}

class _Body {
  final List<dynamic> children = [];
}

class _Document {
  final _Body body = _Body();
}

final _Document document = _Document();

// Keep an alias so code importing as `html` can call html.Blob, html.Url, etc.
// Usage example in web-only code will still compile on mobile but will be no-ops.
