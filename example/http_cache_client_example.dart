import 'package:http_cached_client/http_cache_client.dart';
import 'package:http_cached_client/utils.dart';

void main() async {
  // Create an instance of HttpCacheClient with a base URL and default cache timeout
  final client = HttpCacheClient(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    cacheTimeout: Duration(minutes: 10),
  );

  // Basic GET request
  print('Making first GET request...');
  final response = await client.get('/posts/1');
  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');
  
  // Same GET request again (should be served from cache)
  print('\nMaking second GET request (should use cache)...');
  final cachedResponse = await client.get('/posts/1');
  print('Response status: ${cachedResponse.statusCode}');
  print('Response body from cache: ${cachedResponse.body}');
  
  // GET request with query parameters
  print('\nMaking GET request with query parameters...');
  final queryResponse = await client.get(
    '/posts',
    queryParams: {'userId': '1'},
  );
  print('Response status: ${queryResponse.statusCode}');
  print('Number of posts returned: ${queryResponse.body.split('{').length - 1}');
  
  // POST request
  print('\nMaking POST request...');
  final postResponse = await client.post(
    '/posts',
    body: {
      'title': 'Sample Post',
      'body': 'This is a sample post created with HttpCacheClient',
      'userId': 1,
    },
  );
  print('Response status: ${postResponse.statusCode}');
  print('Response body: ${postResponse.body}');
  
  // Clearing cache
  print('\nClearing cache...');
  client.clearCache();
  
  // This GET request should now hit the network again
  print('\nMaking GET request after clearing cache...');
  final uncachedResponse = await client.get('/posts/1');
  print('Response status: ${uncachedResponse.statusCode}');
  print('Response body (from network): ${uncachedResponse.body}');
  
  // Selective cache invalidation
  print('\nInvalidating specific cache entry...');
  client.invalidateCache(
    uri: '/posts/1',
    method: REQUEST_METHODS.GET,
  );
  
  print('\nDone!');
}
