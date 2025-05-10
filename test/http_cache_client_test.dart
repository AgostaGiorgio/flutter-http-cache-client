// ignore_for_file: unused_local_variable, prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_cached_client/http_cache_client.dart';
import 'package:http_cached_client/utils.dart';

void main() {
  test('Should cache GET response and skip second network call', () async {
    int callCount = 0;

    final mockClient = MockClient((request) async {
      callCount++;
      return http.Response('{"name": "Alice"}', 200);
    });

    final client = HttpCacheClient(
      baseUrl: 'https://api.example.com',
      cacheTimeout: Duration(minutes: 1),
      httpClient: mockClient, // ✅ use the mock client!
    );

    // First request — should hit network
    final response1 = await client.get('/user', headers: {});
    expect(response1.statusCode, 200);
    expect(response1.body, contains('Alice'));
    expect(callCount, 1);

    // Second request — should be cached
    final response2 = await client.get('/user', headers: {});
    expect(response2.statusCode, 200);
    expect(response2.body, contains('Alice'));
    expect(callCount, 1); // Still 1 — no network call
  });

  group('HttpCacheClient cache control', () {
    late int callCount;
    late HttpCacheClient client;

    setUp(() {
      callCount = 0;

      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response('{"status": "ok"}', 200);
      });

      client = HttpCacheClient(
        baseUrl: 'https://api.example.com',
        cacheTimeout: Duration(minutes: 1),
        httpClient: mockClient,
      );
    });

    test('clearCache() should remove all cached entries', () async {
      await client.get('/data');
      expect(callCount, 1); // Real request

      await client.get('/data');
      expect(callCount, 1); // Should be cached

      client.clearCache(); // Clear everything

      await client.get('/data');
      expect(callCount, 2); // Should hit network again
    });

    test('invalidateCache(uri) should remove only one cached entry', () async {
      await client.get('/one');
      await client.get('/two');
      expect(callCount, 2); // Two network calls

      await client.get('/one');
      await client.get('/two');
      expect(callCount, 2); // All cached

      client.invalidateCache(
          uri: '/one', method: REQUEST_METHODS.GET); // Invalidate one

      await client.get('/one'); // Should hit network again
      await client.get('/two'); // Still cached
      expect(callCount, 3);
    });
  });

  group('HttpCacheClient caching (no cache for PUT/DELETE)', () {
    late int callCount;
    late HttpCacheClient client;

    setUp(() {
      callCount = 0;

      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response('{"status": "ok"}', 200);
      });

      client = HttpCacheClient(
        baseUrl: 'https://api.example.com',
        cacheTimeout: Duration(minutes: 1),
        httpClient: mockClient,
      );
    });

    test('PUT request should not cache', () async {
      await client.put('/user/123', headers: {}, body: '{"name": "Alice"}');
      expect(callCount, 1); // Network call

      // Call again — should not be cached
      await client.put('/user/123', headers: {}, body: '{"name": "Bob"}');
      expect(callCount, 2); // Another network call
    });

    test('DELETE request should not cache', () async {
      await client.delete('/user/123');
      expect(callCount, 1); // Network call

      // Call again — should not be cached
      await client.delete('/user/123');
      expect(callCount, 2); // Another network call
    });

    test('GET request should cache the response', () async {
      await client.get('/data');
      expect(callCount, 1); // Network call

      // Call again — should be cached
      await client.get('/data');
      expect(callCount, 1); // Still cached, no network call
    });
  });

  group('HttpCacheClient query parameters', () {
    late int callCount;
    late Uri? lastRequestedUri;
    late HttpCacheClient client;

    setUp(() {
      callCount = 0;
      lastRequestedUri = null;

      final mockClient = MockClient((request) async {
        callCount++;
        lastRequestedUri = request.url;
        return http.Response('{"status": "ok"}', 200);
      });

      client = HttpCacheClient(
        baseUrl: 'https://api.example.com',
        cacheTimeout: Duration(minutes: 5),
        httpClient: mockClient,
      );
    });

    test('includes query parameters in the request URL', () async {
      await client.get('/user', queryParams: {'id': '123', 'sort': 'name'});

      expect(lastRequestedUri.toString(), 'https://api.example.com/user?id=123&sort=name');
    });

    test('returns cached response on repeated request with same query params', () async {
      final first = await client.get('/user', queryParams: {'id': '1'});
      final second = await client.get('/user', queryParams: {'id': '1'});

      expect(first.body, '{"status": "ok"}');
      expect(second.body, '{"status": "ok"}');
      expect(callCount, 1); // Only one network call due to caching
    });

    test('treats different query parameters as different cache keys', () async {
      final first = await client.get('/user', queryParams: {'id': '1'});
      final second = await client.get('/user', queryParams: {'id': '2'});

      expect(first.body, '{"status": "ok"}');
      expect(second.body, '{"status": "ok"}');
      expect(callCount, 2); // Two different calls because of different query params
    });
  });
}
