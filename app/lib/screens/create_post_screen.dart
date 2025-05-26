import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'dart:io';
import '../widgets/brutalist_components.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final _supabaseService = SupabaseService();
  File? _videoFile;
  bool _isUploading = false;
  String? _error;

  Future<void> _handleVideoRecorded(File videoFile) async {
    setState(() {
      _videoFile = videoFile;
    });
  }

  Future<void> _createPost() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record a video first')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      print('Encrypting video...');
      final encryptedFile = await _supabaseService.encryptVideo(
        _videoFile!,
        _postController.text,
      );
      print('Encrypted file at: ${encryptedFile.path}');

      print('Uploading to Supabase...');
      final videoUrl = await _supabaseService.uploadVideo(
        encryptedFile.path,
        '${DateTime.now().millisecondsSinceEpoch}_encrypted.mp4',
      );
      print('Uploaded video URL: ${videoUrl}');

      print('Creating post in Supabase...');
      await _supabaseService.createPost(
        walletAddress: 'current_user_wallet',
        videoUrl: videoUrl,
        encryptedContent: _postController.text,
      );
      print('Post created!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        _postController.clear();
        setState(() {
          _videoFile = null;
        });
        // Navigate to feed screen
        Navigator.pushReplacementNamed(context, '/feed');
      }
    } catch (e) {
      print('Error in createPost: ${e.toString()}');
      setState(() {
        _error = 'Failed to create post. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _postController.dispose();
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
            'Create Post',
            style: TextStyle(
              color: Color(0xFF004AAD),
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isUploading ? null : _createPost,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isUploading
                            ? Colors.grey.shade200
                            : const Color(0xFF004AAD),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child:
                      _isUploading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Post',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // User info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    BrutalistContainer(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      child: const Center(
                        child: Text(
                          'T',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '@username',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Post content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      BrutalistTextField(
                        controller: _postController,
                        hintText: 'Share your deep truth...',
                      ),
                      if (_videoFile != null) ...[
                        const SizedBox(height: 16),
                        BrutalistContainer(
                          height: 200,
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.videocam,
                                  size: 48,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: BrutalistIconButton(
                                  icon: Icons.close,
                                  onPressed: () {
                                    setState(() {
                                      _videoFile = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BrutalistContainer(
                    backgroundColor: Colors.red.shade50,
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Media options
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BrutalistButton(
                      onPressed:
                          _isUploading
                              ? null
                              : () {
                                Navigator.pushNamed(
                                  context,
                                  '/camera',
                                  arguments: _handleVideoRecorded,
                                );
                              },
                      backgroundColor: const Color(0xFF004AAD),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _videoFile == null
                                ? 'Record Video'
                                : 'Change Video',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: BrutalistContainer(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF004AAD),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Creating your post...',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
