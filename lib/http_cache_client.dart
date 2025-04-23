library http_cache_client;

import 'dart:convert';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:http_cache_client/key_generator.dart/default_key_generator.dart';
import 'package:http_cache_client/key_generator.dart/key_generator.dart';

/// A simple HTTP client with caching support.
class HttpCacheClient {
  final String baseUrl;
  final Duration cacheTimeout;
  final http.Client _httpClient;

  final KeyGenerator _keyGenerator;
  final _cache = HashMap<String, _CachedResponse>();

  HttpCacheClient({
    required this.baseUrl,
    this.cacheTimeout = const Duration(minutes: 5),
    KeyGenerator? keyGenerator,
    http.Client? httpClient,
  })  : _keyGenerator = keyGenerator ?? DefaultKeyGenerator(),
        _httpClient = httpClient ?? http.Client();

  Future<http.Response> get(String uri, {Map<String, String>? headers}) async {
    return _handleRequest(
      method: 'GET',
      uri: uri,
      headers: headers,
    );
  }

  Future<http.Response> post(String uri,
      {Map<String, String>? headers, Object? body}) async {
    return _handleRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
    );
  }

  Future<http.Response> _handleRequest(
      {required String method,
      required String uri,
      Map<String, String>? headers,
      Object? body}) async {
    final fullUrl = Uri.parse('$baseUrl$uri');
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
    if (method == 'GET') {
      response = await _httpClient.get(fullUrl, headers: headers);
    } else if (method == 'POST') {
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
    required String method,
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
