import 'dart:math';

String generateTraceId() {
  final random = Random();
  return 'trace-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
}

String generateIdempotencyKey() {
  final random = Random();
  return 'idem-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
}
