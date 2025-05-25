import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../models/post.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _supabaseService = SupabaseService();
  List<Post> _posts = [];
  Set<String> _likedPostIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _supabaseService.getFeed();
      setState(() {
        _posts = posts.map<Post>((post) => Post(
          id: post['id'].toString(),
          username: post['profiles']['wallet_address'] ?? 'Anonymous',
          avatarText: (post['profiles']['wallet_address'] ?? 'A')[2].toUpperCase(),
          content: post['encrypted_content'] ?? '',
          likes: post['likes'] ?? 0,
          comments: post['comments'] ?? 0,
          type: PostType.video,
          mediaPath: post['video_url'] ?? '',
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load posts';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Truth',
                style: TextStyle(
                  color: Color(0xFF004AAD),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              TextSpan(
                text: 'Cast',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPosts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? const Center(
                      child: Text(
                        'No posts yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final isLiked = _likedPostIds.contains(_posts[index].id);
                          return PostCard(
                            post: _posts[index],
                            isLiked: isLiked,
                            onLike: () async {
                              try {
                                await _supabaseService.likePost(_posts[index].id);
                                setState(() {
                                  _posts[index] = _posts[index].copyWith(likes: _posts[index].likes + 1);
                                  _likedPostIds.add(_posts[index].id);
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to like post: $e')),
                                );
                              }
                            },
                            onComment: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final walletAddress = prefs.getString('wallet_address') ?? '';
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) {
                                  final commentController = TextEditingController();
                                  return Padding(
                                    padding: MediaQuery.of(ctx).viewInsets,
                                    child: SizedBox(
                                      height: 400,
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 16),
                                          const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          Expanded(
                                            child: FutureBuilder<List<Map<String, dynamic>>>(
                                              future: _supabaseService.getComments(_posts[index].id),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return const Center(child: CircularProgressIndicator());
                                                }
                                                final comments = snapshot.data!;
                                                if (comments.isEmpty) {
                                                  return const Center(child: Text('No comments yet'));
                                                }
                                                return ListView.builder(
                                                  itemCount: comments.length,
                                                  itemBuilder: (context, idx) {
                                                    final c = comments[idx];
                                                    return ListTile(
                                                      leading: CircleAvatar(child: Text((c['wallet_address'] ?? '?').substring(2, 3).toUpperCase())),
                                                      title: Text(c['comment'] ?? ''),
                                                      subtitle: Text('@${c['wallet_address'] ?? ''}'),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: commentController,
                                                    decoration: const InputDecoration(hintText: 'Add a comment...'),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.send, color: Color(0xFF004AAD)),
                                                  onPressed: () async {
                                                    final text = commentController.text.trim();
                                                    if (text.isEmpty) return;
                                                    await _supabaseService.addComment(_posts[index].id, text, walletAddress);
                                                    setState(() {
                                                      _posts[index] = _posts[index].copyWith(comments: _posts[index].comments + 1);
                                                    });
                                                    Navigator.of(ctx).pop();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}