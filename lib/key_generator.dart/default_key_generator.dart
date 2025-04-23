import 'dart:convert';
import 'key_generator.dart';

class DefaultKeyGenerator implements KeyGenerator {
  @override
  String generateKey({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
  }) {
    final keyParts = [
      method.toUpperCase(),
      url.toString(),
      jsonEncode(headers ?? {}),
      jsonEncode(body ?? {}),
    ];
    return keyParts.join('|');
  }
}
