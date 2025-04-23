import 'dart:convert';
import 'package:http_cache_client/utils.dart';

import 'key_generator.dart';

class DefaultKeyGenerator implements KeyGenerator {
  @override
  String generateKey({
    required REQUEST_METHODS method,
    required Uri url,
    Object? body,
  }) {
    final keyParts = [
      method.toString(),
      url.toString(),
      jsonEncode(body ?? {}),
    ];
    return keyParts.join('|');
  }
}
