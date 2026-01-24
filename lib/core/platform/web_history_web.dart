import 'package:web/web.dart' as web;

void pushBrowserPathImpl(String path) {
  web.window.history.pushState(null, '', path);
}
