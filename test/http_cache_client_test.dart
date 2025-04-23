// ignore_for_file: unused_local_variable, prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_cache_client/http_cache_client.dart';

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

      client.invalidateCache(uri: '/one', method: 'GET'); // Invalidate one

      await client.get('/one'); // Should hit network again
      await client.get('/two'); // Still cached
      expect(callCount, 3);
    });
  });
}
