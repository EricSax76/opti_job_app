import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUtils {
  /// Safely converts a Firestore value (Timestamp, String, etc.) to [DateTime].
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Safely converts a dynamic ID to [int].
  /// Handles Strings, nums, and nulls.
  static int parseIntId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
  
  /// Recursively transforms Firestore data to JSON-encodable Maps (e.g. converting Timestamps to Strings).
  /// This is useful if your domain models rely on standard JSON (DateTime as String).
  static Map<String, dynamic> transformFirestoreData(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = transformFirestoreData(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return transformFirestoreData(item);
          }
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}
