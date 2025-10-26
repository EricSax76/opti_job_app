import 'dart:math';

String generateTraceId() {
  final random = Random();
  // Use 31-bit max because JS runtimes cap ints to 32 bits and shift overflow would return 0
  return 'trace-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 31)}';
}

String generateIdempotencyKey() {
  final random = Random();
  return 'idem-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 31)}';
}
