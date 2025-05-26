import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/brutalist_components.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

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

  Future<void> _playVideo(String videoUrl) async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }

    _videoController = VideoPlayerController.network(videoUrl);
    await _videoController!.initialize();
    await _videoController!.play();
    setState(() {
      _isVideoPlaying = true;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: BrutalistButton(
                      onPressed: () {
                        _videoController?.pause();
                        _videoController?.dispose();
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ).then((_) {
        _videoController?.pause();
        _videoController?.dispose();
        setState(() {
          _isVideoPlaying = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController?.dispose();
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
        automaticallyImplyLeading: false, // Remove default back button
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black),
        ),
        title: SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered title
              const Align(
                alignment: Alignment.center,
                child: Text(
                  'Profile',
                  style: TextStyle(
                    color: Color(0xFF004AAD),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              // Left-aligned logo
              const Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Stark',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Truth',
                      style: TextStyle(
                        color: Color(0xFF004AAD),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF004AAD),
                    ),
                    strokeWidth: 3,
                  ),
                ),
              )
              : _error != null
              ? Center(
                child: BrutalistContainer(
                  backgroundColor: Colors.red.shade50,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      BrutalistButton(
                        onPressed: _loadProfile,
                        backgroundColor: Colors.red.shade100,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Retry',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  const SizedBox(height: 32),
                  // Profile avatar
                  BrutalistContainer(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        (_profile?['username'] ??
                                _profile?['wallet_address'] ??
                                '?')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: Color(0xFF004AAD),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Username
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF004AAD), width: 3),
                      ),
                    ),
                    child: Text(
                      _profile?['username'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bio
                  if (_profile?['bio'] != null && _profile!['bio'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: BrutalistContainer(
                        backgroundColor: Colors.grey.shade50,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _profile!['bio'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Wallet address
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: BrutalistContainer(
                      backgroundColor: Colors.grey.shade50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        _profile?['wallet_address'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                Icon(Icons.grid_on, size: 24),
                                SizedBox(width: 12),
                                Text('Videos'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark, size: 24),
                                SizedBox(width: 12),
                                Text('Saved'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.videocam_off,
                                      size: 48,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No videos yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    BrutalistButton(
                                      onPressed: () {},
                                      backgroundColor: const Color(0xFF004AAD),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Record Video',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: _videos.length,
                              itemBuilder: (context, index) {
                                final video = _videos[index];
                                return GestureDetector(
                                  onTap: () => _playVideo(video['video_url']),
                                  child: BrutalistContainer(
                                    padding: const EdgeInsets.all(8),
                                    child: Stack(
                                      children: [
                                        const Center(
                                          child: Icon(
                                            Icons.play_circle_outline,
                                            size: 40,
                                            color: Color(0xFF004AAD),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: BrutalistContainer(
                                            backgroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.favorite,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${video['likes'] ?? 0}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        // Saved tab
                        _savedVideos.isEmpty
                            ? Center(
                              child: BrutalistContainer(
                                backgroundColor: Colors.grey.shade50,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bookmark_border,
                                      size: 48,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No saved videos',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: _savedVideos.length,
                              itemBuilder: (context, index) {
                                final video = _savedVideos[index];
                                return GestureDetector(
                                  onTap: () => _playVideo(video['video_url']),
                                  child: BrutalistContainer(
                                    padding: const EdgeInsets.all(8),
                                    child: Stack(
                                      children: [
                                        const Center(
                                          child: Icon(
                                            Icons.bookmark,
                                            size: 40,
                                            color: Color(0xFF004AAD),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: BrutalistContainer(
                                            backgroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.favorite,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${video['likes'] ?? 0}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
