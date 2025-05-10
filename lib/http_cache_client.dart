/// A Flutter package that provides a simple HTTP client with caching capabilities.
///
/// This library builds on top of the standard `http` package to provide automatic
/// caching of network requests with configurable timeout. It supports all common
/// HTTP methods and provides utilities for cache management.
library http_cache_client;

import 'dart:convert';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:http_cached_client/key_generator/default_key_generator.dart';
import 'package:http_cached_client/key_generator/key_generator.dart';
import 'package:http_cached_client/utils.dart';

/// A simple HTTP client with caching support.
///
/// Wraps the standard `http` client and provides in-memory caching for HTTP requests.
/// By default, GET and POST requests are cached, while PUT and DELETE requests are not.
class HttpCacheClient {
  /// The base URL for all HTTP requests.
  ///
  /// This will be prepended to all request URIs.
  final String baseUrl;

  /// The duration for which cached responses remain valid.
  ///
  /// Default is 5 minutes.
  final Duration cacheTimeout;

  /// The underlying HTTP client used to make network requests.
  final http.Client _httpClient;

  /// The key generator used to create cache keys.
  final KeyGenerator _keyGenerator;

  /// Internal cache storage that maps cache keys to cached responses.
  final _cache = HashMap<String, _CachedResponse>();

  /// Creates a new HTTP client with caching support.
  ///
  /// - [baseUrl]: The base URL for all requests
  /// - [cacheTimeout]: How long cached responses remain valid (default: 5 minutes)
  /// - [keyGenerator]: Optional custom cache key generator
  /// - [httpClient]: Optional custom HTTP client implementation
  HttpCacheClient(
      {required this.baseUrl,
      this.cacheTimeout = const Duration(minutes: 5),
      KeyGenerator? keyGenerator,
      http.Client? httpClient})
      : _keyGenerator = keyGenerator ?? DefaultKeyGenerator(),
        _httpClient = httpClient ?? http.Client();

  /// Performs a GET request with optional caching.
  ///
  /// - [uri]: The URI path to request (appended to [baseUrl])
  /// - [headers]: Optional HTTP headers for the request
  /// - [queryParams]: Optional query parameters to add to the URL
  /// - [cacheResult]: Whether to cache the response (default: true)
  ///
  /// Returns a Future that completes with the Response.
  Future<http.Response> get(String uri,
      {Map<String, String>? headers,
      Map<String, String>? queryParams,
      bool cacheResult = true}) async {
    return _handleRequest(
      method: REQUEST_METHODS.GET,
      uri: uri,
      headers: headers,
      queryParams: queryParams,
      cacheResult: cacheResult,
    );
  }

  /// Performs a POST request with optional caching.
  ///
  /// - [uri]: The URI path to request (appended to [baseUrl])
  /// - [headers]: Optional HTTP headers for the request
  /// - [queryParams]: Optional query parameters to add to the URL
  /// - [body]: The request body (will be JSON-encoded if it's a Map)
  /// - [cacheResult]: Whether to cache the response (default: true)
  ///
  /// Returns a Future that completes with the Response.
  Future<http.Response> post(String uri,
      {Map<String, String>? headers,
      Map<String, String>? queryParams,
      Object? body,
      bool cacheResult = true}) async {
    return _handleRequest(
      method: REQUEST_METHODS.POST,
      uri: uri,
      headers: headers,
      queryParams: queryParams,
      body: body,
      cacheResult: cacheResult,
    );
  }

  /// Performs a PUT request (not cached by default).
  ///
  /// - [uri]: The URI path to request (appended to [baseUrl])
  /// - [headers]: Optional HTTP headers for the request
  /// - [queryParams]: Optional query parameters to add to the URL
  /// - [body]: The request body (will be JSON-encoded if it's a Map)
  ///
  /// Returns a Future that completes with the Response.
  Future<http.Response> put(String uri,
      {Map<String, String>? headers,
      Map<String, String>? queryParams,
      Object? body}) {
    return _handleRequest(
      method: REQUEST_METHODS.PUT,
      uri: uri,
      headers: headers,
      queryParams: queryParams,
      body: body,
    );
  }

  /// Performs a DELETE request (not cached by default).
  ///
  /// - [uri]: The URI path to request (appended to [baseUrl])
  /// - [headers]: Optional HTTP headers for the request
  /// - [queryParams]: Optional query parameters to add to the URL
  ///
  /// Returns a Future that completes with the Response.
  Future<http.Response> delete(String uri,
      {Map<String, String>? headers, Map<String, String>? queryParams}) {
    return _handleRequest(
        method: REQUEST_METHODS.DELETE,
        uri: uri,
        headers: headers,
        queryParams: queryParams);
  }

  Future<http.Response> _handleRequest(
      {required REQUEST_METHODS method,
      required String uri,
      Map<String, String>? headers,
      Map<String, String>? queryParams,
      Object? body,
      bool cacheResult = true}) async {
    final fullUrl =
        Uri.parse('$baseUrl$uri').replace(queryParameters: queryParams);

    late http.Response? response;
    if (isMethodCacheble(method) && cacheResult) {
      final cacheKey = _keyGenerator.generateKey(
        method: method,
        url: fullUrl,
        body: body,
      );
      response = _getFromCache(
          cacheKey: cacheKey, url: fullUrl, method: method, body: body);
      if (response != null) {
        return response;
      } else {
        response = await _makeHttpRequest(
          method: method,
          url: fullUrl,
          headers: headers,
          body: body,
        );
        _cache[cacheKey] = _CachedResponse(response, DateTime.now());
        return response;
      }
    } else {
      return _makeHttpRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
      );
    }
  }

  http.Response? _getFromCache({
    required String cacheKey,
    required Uri url,
    required REQUEST_METHODS method,
    Object? body,
  }) {
    final now = DateTime.now();
    final cached = _cache[cacheKey];
    if (cached != null && now.difference(cached.timestamp) < cacheTimeout) {
      return cached.response;
    }
    return null;
  }

  Future<http.Response> _makeHttpRequest({
    required REQUEST_METHODS method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
  }) async {
    switch (method) {
      case REQUEST_METHODS.GET:
        return _httpClient.get(url, headers: headers);
      case REQUEST_METHODS.POST:
        final response = await _httpClient.post(url,
            headers: headers, body: body is Map ? jsonEncode(body) : body);
        return handleRedirects(response);
      case REQUEST_METHODS.PUT:
        return _httpClient.put(url,
            headers: headers, body: body is Map ? jsonEncode(body) : body);
      case REQUEST_METHODS.DELETE:
        return _httpClient.delete(url, headers: headers);
      default:
        throw Exception('Unsupported HTTP method');
    }
  }

  /// Clears all cached responses.
  ///
  /// This removes all entries from the cache, requiring fresh network requests
  /// for subsequent calls.
  void clearCache() {
    _cache.clear();
  }

  /// Invalidates a specific cached response.
  ///
  /// - [uri]: The URI path of the request to invalidate
  /// - [method]: The HTTP method of the request to invalidate
  /// - [body]: The body of the request to invalidate (for POST/PUT requests)
  ///
  /// This removes a specific entry from the cache, requiring a fresh network request
  /// for subsequent calls with the same parameters.
  void invalidateCache({
    required String uri,
    required REQUEST_METHODS method,
    Object? body,
  }) {
    final fullUrl = Uri.parse('$baseUrl$uri');

    final key = _keyGenerator.generateKey(
      method: method,
      url: fullUrl,
      body: body,
    );

    _cache.remove(key);
  }

  /// Handles HTTP redirects for responses with 301 or 302 status codes.
  ///
  /// - [response]: The original HTTP response
  ///
  /// Returns a new response after following the redirect, or the original response
  /// if it's not a redirect or if the 'location' header is missing.
  Future<http.Response> handleRedirects(http.Response response) async {
    if (response.statusCode == 302 || response.statusCode == 301) {
      final location = response.headers['location'];
      if (location != null) {
        final newUrl = Uri.parse(location);
        return await _httpClient.get(newUrl);
      }
    }
    return response;
  }
}

/// Internal class that stores a cached HTTP response along with its timestamp.
///
/// Used to determine if a cached response has expired based on the [cacheTimeout].
class _CachedResponse {
  /// The cached HTTP response.
  final http.Response response;
  
  /// The time when the response was cached.
  final DateTime timestamp;

  _CachedResponse(this.response, this.timestamp);
}
