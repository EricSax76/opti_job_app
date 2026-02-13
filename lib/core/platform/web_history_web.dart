import 'package:web/web.dart' as web;

void pushBrowserPathImpl(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  final isHashRouting = web.window.location.hash.startsWith('#/');
  if (isHashRouting) {
    // Keep URL updates compatible with Flutter's default hash strategy.
    web.window.history.pushState(null, '', '#$normalizedPath');
    return;
  }
  web.window.history.pushState(null, '', normalizedPath);
}
