// ignore_for_file: camel_case_types, constant_identifier_names

/// Enum representing the supported HTTP methods.
///
/// These methods correspond to the standard HTTP verbs used in RESTful APIs.
enum REQUEST_METHODS {
  /// HTTP GET method - Used to retrieve resources
  GET,

  /// HTTP POST method - Used to create new resources
  POST,

  /// HTTP PUT method - Used to update existing resources
  PUT,

  /// HTTP DELETE method - Used to delete resources
  DELETE,
}

/// Determines if a given HTTP method should have its responses cached.
///
/// By default, only GET and POST methods have their responses cached.
///
/// - [method]: The HTTP method to check
///
/// Returns true if the method's responses should be cached, false otherwise.
bool isMethodCacheble(REQUEST_METHODS method) {
  return method == REQUEST_METHODS.GET || method == REQUEST_METHODS.POST;
}

/// Determines if a given HTTP method should NOT have its responses cached.
///
/// This is the inverse of [isMethodCacheble].
///
/// - [method]: The HTTP method to check
///
/// Returns true if the method's responses should NOT be cached, false otherwise.
bool isMethodNotCacheble(REQUEST_METHODS method) {
  return !isMethodCacheble(method);
}
