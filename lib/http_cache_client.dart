library http_cache_client;

import 'dart:convert';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:http_cache_client/key_generator.dart/default_key_generator.dart';
import 'package:http_cache_client/key_generator.dart/key_generator.dart';
import 'package:http_cache_client/utils.dart';

/// A simple HTTP client with caching support.
class HttpCacheClient {
  final String baseUrl;
  final Duration cacheTimeout;
  final http.Client _httpClient;

  final KeyGenerator _keyGenerator;
  final _cache = HashMap<String, _CachedResponse>();

  HttpCacheClient(
      {required this.baseUrl,
      this.cacheTimeout = const Duration(minutes: 5),
      KeyGenerator? keyGenerator,
      http.Client? httpClient})
      : _keyGenerator = keyGenerator ?? DefaultKeyGenerator(),
        _httpClient = httpClient ?? http.Client();

  Future<http.Response> get(String uri,
      {Map<String, String>? headers, Map<String, String>? queryParams}) async {
    return _handleRequest(
      method: REQUEST_METHODS.GET,
      uri: uri,
      headers: headers,
      queryParams: queryParams,
    );
  }

  Future<http.Response> post(String uri,
      {Map<String, String>? headers,
      Map<String, String>? queryParams,
      Object? body}) async {
    return _handleRequest(
      method: REQUEST_METHODS.POST,
      uri: uri,
      headers: headers,
      queryParams: queryParams,
      body: body,
    );
  }

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

  Future<http.Response> delete(String uri,
      {Map<String, String>? headers,
      Map<String, String>? queryParams,
      Object? body}) {
    return _handleRequest(
      method: REQUEST_METHODS.DELETE,
      uri: uri,
      headers: headers,
      queryParams: queryParams,
      body: body,
    );
  }

  Future<http.Response> _handleRequest(
      {required REQUEST_METHODS method,
      required String uri,
      Map<String, String>? headers,
      Map<String, String>? queryParams,
      Object? body}) async {
    final fullUrl =
        Uri.parse('$baseUrl$uri').replace(queryParameters: queryParams);

    if (isMethodNotCacheble(method)) {
      if (method == REQUEST_METHODS.PUT) {
        return await _httpClient.put(
          fullUrl,
          headers: headers,
          body: body is Map ? jsonEncode(body) : body,
        );
      } else if (method == REQUEST_METHODS.DELETE) {
        return await _httpClient.delete(
          fullUrl,
          headers: headers,
          body: body is Map ? jsonEncode(body) : body,
        );
      }
      throw UnsupportedError('Method $method not supported');
    }

    final cacheKey = _keyGenerator.generateKey(
      method: method,
      url: fullUrl,
      body: body,
    );
    final now = DateTime.now();
    final cached = _cache[cacheKey];
    if (cached != null && now.difference(cached.timestamp) < cacheTimeout) {
      return cached.response;
    }

    late http.Response response;
    if (method == REQUEST_METHODS.GET) {
      response = await _httpClient.get(fullUrl, headers: headers);
    } else if (method == REQUEST_METHODS.POST) {
      response = await _httpClient.post(
        fullUrl,
        headers: headers,
        body: body is Map ? jsonEncode(body) : body,
      );
    } else {
      throw UnsupportedError('Method $method not supported');
    }

    _cache[cacheKey] = _CachedResponse(response, now);
    return response;
  }

  void clearCache() {
    _cache.clear();
  }

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
}

class _CachedResponse {
  final http.Response response;
  final DateTime timestamp;

  _CachedResponse(this.response, this.timestamp);
}
