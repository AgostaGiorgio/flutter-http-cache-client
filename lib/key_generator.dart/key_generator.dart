import 'package:http_cache_client/utils.dart';

abstract class KeyGenerator {
  String generateKey({
    required REQUEST_METHODS method,
    required Uri url,
    Object? body,
  });
}
