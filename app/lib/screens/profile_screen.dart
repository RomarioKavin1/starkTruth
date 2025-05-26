import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/brutalist_components.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Stark',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'Truth',
                style: TextStyle(
                  color: Color(0xFF004AAD),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        title: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
          child: const Text(
            'Profile',
            style: TextStyle(
              color: Color(0xFF004AAD),
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: BrutalistContainer(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(12),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              )
              : _error != null
              ? Center(
                child: BrutalistContainer(
                  backgroundColor: Colors.red.shade50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BrutalistButton(
                        onPressed: _loadProfile,
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  const SizedBox(height: 24),
                  // Profile avatar
                  BrutalistContainer(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        (_profile?['username'] ??
                                _profile?['wallet_address'] ??
                                '?')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Username
                  Text(
                    _profile?['username'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bio
                  if (_profile?['bio'] != null && _profile!['bio'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _profile!['bio'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Wallet address
                  BrutalistContainer(
                    backgroundColor: Colors.grey.shade50,
                    child: Text(
                      _profile?['wallet_address'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BrutalistContainer(
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.5,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.5,
                        ),
                        indicator: BoxDecoration(
                          color: const Color(0xFF004AAD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.grid_on, size: 20),
                                SizedBox(width: 8),
                                Text('Videos'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark, size: 20),
                                SizedBox(width: 8),
                                Text('Saved'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Videos tab
                        _videos.isEmpty
                            ? Center(
                              child: BrutalistContainer(
                                backgroundColor: Colors.grey.shade50,
                                child: const Text(
                                  'No videos yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: _videos.length,
                              itemBuilder: (context, index) {
                                final video = _videos[index];
                                return BrutalistContainer(
                                  padding: const EdgeInsets.all(8),
                                  child: Stack(
                                    children: [
                                      const Center(
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          size: 32,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${video['likes'] ?? 0}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
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
                            ? Center(
                              child: BrutalistContainer(
                                backgroundColor: Colors.grey.shade50,
                                child: const Text(
                                  'No saved videos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: _savedVideos.length,
                              itemBuilder: (context, index) {
                                final video = _savedVideos[index];
                                return BrutalistContainer(
                                  padding: const EdgeInsets.all(8),
                                  child: Stack(
                                    children: [
                                      const Center(
                                        child: Icon(Icons.bookmark, size: 32),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${video['likes'] ?? 0}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
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
