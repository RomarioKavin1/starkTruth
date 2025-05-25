import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'dart:io';

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
      final encryptedFile = await _supabaseService.encryptVideo(_videoFile!, _postController.text);
      print('Encrypted file at: \\${encryptedFile.path}');

      print('Uploading to Supabase...');
      final videoUrl = await _supabaseService.uploadVideo(
        encryptedFile.path,
        '${DateTime.now().millisecondsSinceEpoch}_encrypted.mp4',
      );
      print('Uploaded video URL: \\${videoUrl}');

      print('Creating post in Supabase...');
      await _supabaseService.createPost(
        walletAddress: 'current_user_wallet', // TODO: Get from auth state
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
      }
    } catch (e) {
      print('Error in createPost: \\${e.toString()}');
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
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _createPost,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF004AAD),
                    ),
                  )
                : const Text(
                    'POST',
                    style: TextStyle(
                      color: Color(0xFF004AAD),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // User info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  radius: 20,
                  child: const Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '@username',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                  TextField(
                    controller: _postController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Share your deep truth...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (_videoFile != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
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
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Media options
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF004AAD)),
                  onPressed: _isUploading
                      ? null
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/camera',
                            arguments: _handleVideoRecorded,
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