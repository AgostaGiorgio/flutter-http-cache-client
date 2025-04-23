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
}
