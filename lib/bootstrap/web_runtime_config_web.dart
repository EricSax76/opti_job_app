import 'package:web/web.dart' as web;

String? readWebRuntimeConfigValueImpl(String key) {
  final normalizedKey = key.trim().toLowerCase().replaceAll('_', '-');
  if (normalizedKey.isEmpty) return null;

  final metaName = 'opti-$normalizedKey';
  final element = web.document.querySelector('meta[name="$metaName"]');
  if (element == null) return null;

  final value = (element as web.HTMLMetaElement).content.trim();
  return value.isEmpty ? null : value;
}
