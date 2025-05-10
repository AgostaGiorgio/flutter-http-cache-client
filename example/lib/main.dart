import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:simple_http_cache_client/http_cache_client.dart';
import 'package:simple_http_cache_client/utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTTP Cache Client Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HttpCacheClientDemo(),
    );
  }
}

class HttpCacheClientDemo extends StatefulWidget {
  const HttpCacheClientDemo({super.key});

  @override
  State<HttpCacheClientDemo> createState() => _HttpCacheClientDemoState();
}

class _HttpCacheClientDemoState extends State<HttpCacheClientDemo> {
  // Using JSONPlaceholder API for demonstration
  final client = HttpCacheClient(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    cacheTimeout: const Duration(minutes: 2), // Short timeout for demo purposes
  );

  bool isLoading = false;
  String responseText = 'No request made yet';
  String requestSource = '';
  List<Map<String, dynamic>> posts = [];
  int selectedPostId = 1;
  
  // Tracking request times to demonstrate caching
  Stopwatch stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    // Pre-populate the dropdown
    _fetchListPosts();
  }

  Future<void> _fetchPost() async {
    setState(() {
      isLoading = true;
      stopwatch.reset();
      stopwatch.start();
    });

    try {
      final response = await client.get('/posts/$selectedPostId');
      stopwatch.stop();

      // Check if the response is coming from cache 
      // (This is a simplistic way - in reality we'd need to modify the library to return this info)
      final isCached = stopwatch.elapsedMilliseconds < 100; // Assumption: cache responses are very fast
      
      setState(() {
        isLoading = false;
        responseText = response.body;
        requestSource = isCached ? 'from cache' : 'from network';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        responseText = 'Error: $e';
        requestSource = 'error';
      });
    }
  }

  Future<void> _fetchListPosts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await client.get('/posts', queryParams: {'_limit': '10'});
      final List<dynamic> data = json.decode(response.body);
      
      setState(() {
        isLoading = false;
        posts = data.map((item) => item as Map<String, dynamic>).toList();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        responseText = 'Error fetching posts: $e';
      });
    }
  }

  Future<void> _createPost() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await client.post(
        '/posts',
        body: {
          'title': 'New Post from HTTP Cache Client',
          'body': 'This is a new post created with the HTTP Cache Client library',
          'userId': 1,
        },
      );
      
      setState(() {
        isLoading = false;
        responseText = response.body;
        requestSource = 'POST request (created)';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        responseText = 'Error creating post: $e';
      });
    }
  }

  void _clearCache() {
    client.clearCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared')),
    );
  }

  void _invalidateCurrentPost() {
    client.invalidateCache(
      uri: '/posts/$selectedPostId',
      method: REQUEST_METHODS.GET,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cache for post $selectedPostId invalidated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Cache Client Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HTTP Cache Client',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This demo shows how the HTTP Cache Client works by making requests to a test API. The first request fetches data from the network, while subsequent identical requests use the cached data until cache timeout.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cache timeout: ${client.cacheTimeout.inMinutes} minutes',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Post selection
            Row(
              children: [
                const Text('Select Post ID:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedPostId,
                    isExpanded: true,
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedPostId = newValue;
                        });
                      }
                    },
                    items: posts.isNotEmpty 
                        ? posts.map<DropdownMenuItem<int>>((Map<String, dynamic> post) {
                            return DropdownMenuItem<int>(
                              value: post['id'] as int,
                              child: Text('${post['id']}: ${post['title']}'),
                            );
                          }).toList()
                        : [1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('Post $value'),
                            );
                          }).toList(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchPost,
                  icon: const Icon(Icons.download),
                  label: const Text('Fetch Post'),
                ),
                ElevatedButton.icon(
                  onPressed: _createPost,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Post'),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _clearCache,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear All Cache'),
                ),
                OutlinedButton.icon(
                  onPressed: _invalidateCurrentPost,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Invalidate Current Post'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Response display
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Response:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (requestSource.isNotEmpty)
                            Chip(
                              label: Text(requestSource),
                              backgroundColor: requestSource == 'from cache' 
                                  ? Colors.green.shade100 
                                  : requestSource == 'from network'
                                      ? Colors.blue.shade100
                                      : Colors.amber.shade100,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _prettyPrintJson(responseText),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _prettyPrintJson(String jsonString) {
    try {
      var jsonObject = json.decode(jsonString);
      var encoder = const JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObject);
    } catch (e) {
      return jsonString; // Return the original string if it's not valid JSON
    }
  }
}
