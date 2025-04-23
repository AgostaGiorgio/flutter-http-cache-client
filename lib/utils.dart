// ignore_for_file: camel_case_types, constant_identifier_names

enum REQUEST_METHODS {
  GET,
  POST,
  PUT,
  DELETE,
}

bool isMethodCacheble(REQUEST_METHODS method) {
  return method == REQUEST_METHODS.GET || method == REQUEST_METHODS.POST;
}

bool isMethodNotCacheble(REQUEST_METHODS method) {
  return !isMethodCacheble(method);
}
