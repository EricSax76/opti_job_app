import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(
  Object? data, {
  int statusCode = 200,
  Map<String, String>? headers,
}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      if (headers != null) ...headers,
    },
  );
}

Response jsonError(
  String message, {
  int statusCode = 400,
  Map<String, Object?>? details,
}) {
  return jsonResponse(
    {
      'error': message,
      if (details != null) 'details': details,
    },
    statusCode: statusCode,
  );
}
