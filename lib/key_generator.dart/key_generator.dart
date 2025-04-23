abstract class KeyGenerator {
  String generateKey({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
  });
}
