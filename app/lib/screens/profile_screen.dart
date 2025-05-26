import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabaseService = SupabaseService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _savedVideos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletAddress = prefs.getString('wallet_address') ?? '';
      final profile = await _supabaseService.getUserProfile(walletAddress);
      
      if (profile != null) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
        _loadVideos(walletAddress);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVideos(String walletAddress) async {
    try {
      final videos = await _supabaseService.getUserPosts(walletAddress);
      setState(() {
        _videos = videos;
      });
    } catch (e) {
      // Handle error silently for videos
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.arrow_back, size: 16),
          ),
          onPressed: () {},
        ),
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'PRO',
                style: TextStyle(
                  color: Color(0xFF004AAD),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: 'FILE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.settings, size: 16),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.share, size: 16),
            ),
            onPressed: () {},
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
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile avatar
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            (_profile?['username'] ?? _profile?['wallet_address'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Username
                    Text(
                      _profile?['username'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bio
                    Text(
                      _profile?['bio'] ?? '',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Wallet address (small)
                    Text(
                      _profile?['wallet_address'] ?? '',
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF004AAD), width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Color(0xFF004AAD),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black38),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Color(0xFF004AAD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.grid_on, color: Colors.black),
                                SizedBox(width: 8),
                                Text('Videos', style: TextStyle(color: Colors.black)),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark, color: Colors.black),
                                SizedBox(width: 8),
                                Text('Saved', style: TextStyle(color: Colors.black)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Videos tab
                          _videos.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No videos yet',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _videos.length,
                                  itemBuilder: (context, index) {
                                    final video = _videos[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF003377),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Icon(
                                              Icons.play_circle_outline,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Text(
                                              '${video['likes'] ?? 0}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          // Saved tab
                          _savedVideos.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No saved videos',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _savedVideos.length,
                                  itemBuilder: (context, index) {
                                    final video = _savedVideos[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF003377),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Icon(
                                              Icons.bookmark,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Text(
                                              '${video['likes'] ?? 0}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}