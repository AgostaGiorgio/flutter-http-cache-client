import 'dart:convert';
import 'key_generator.dart';

class DefaultKeyGenerator implements KeyGenerator {
  @override
  String generateKey({
    required String method,
    required Uri url,
    Object? body,
  }) {
    final keyParts = [
      method.toUpperCase(),
      url.toString(),
      jsonEncode(body ?? {}),
    ];
    return keyParts.join('|');
  }
}
