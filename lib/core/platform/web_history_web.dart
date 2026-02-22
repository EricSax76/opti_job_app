import 'package:web/web.dart' as web;

void pushBrowserPathImpl(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  final isHashRouting = web.window.location.hash.startsWith('#/');
  if (isHashRouting) {
    // replaceState instead of pushState: avoids creating browser history entries
    // that GoRouter doesn't know about, which was causing navigation desync.
    web.window.history.replaceState(null, '', '#$normalizedPath');
    return;
  }
  web.window.history.replaceState(null, '', normalizedPath);
}
