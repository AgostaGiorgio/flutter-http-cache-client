import 'dart:convert';
import 'package:http_cached_client/utils.dart';

import 'key_generator.dart';

/// Default implementation of [KeyGenerator] that creates cache keys
/// by combining the HTTP method, URL, and request body.
///
/// This generator creates keys in the format: "METHOD|URL|ENCODED_BODY"
class DefaultKeyGenerator implements KeyGenerator {
  /// Creates a new default key generator.
  const DefaultKeyGenerator();

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
