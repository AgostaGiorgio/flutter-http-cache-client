import 'package:simple_http_cache_client/utils.dart';

/// Interface for cache key generation strategies.
///
/// Implementations of this class are responsible for generating unique cache keys
/// based on the HTTP request parameters (method, URL, and body).
abstract class KeyGenerator {
  /// Generates a unique cache key for a specific HTTP request.
  ///
  /// - [method]: The HTTP method (GET, POST, PUT, DELETE)
  /// - [url]: The complete request URL including query parameters
  /// - [body]: The request body (for POST and PUT requests)
  ///
  /// Returns a string that uniquely identifies this request for caching purposes.
  String generateKey({
    required REQUEST_METHODS method,
    required Uri url,
    Object? body,
  });
}
