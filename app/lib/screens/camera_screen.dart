import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../services/steno_service.dart';
import '../widgets/loader.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraScreen extends StatefulWidget {
  final void Function(File videoFile)? onVideoRecorded;
  const CameraScreen({super.key, this.onVideoRecorded});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // Helper for translucent round controls
  Widget _buildTranslucentCircle({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF004AAD),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _isUploading = false;

  // Store the last recorded file for upload
  File? _lastRecordedFile;

  // Timer for recording duration
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onRecordButtonPressed() async {
    if (!_isInitialized) return;
    try {
      if (_isRecording) {
        // Stop recording
        _timer?.cancel();
        final file = await _controller!.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });
        _lastRecordedFile = File(file.path);
        _showUploadDialog(context, _lastRecordedFile!);
      } else {
        // Start recording
        setState(() {
          _isRecording = true;
          _recordingStartTime = DateTime.now();
          _recordingDuration = Duration.zero;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_recordingStartTime != null && mounted && _isRecording) {
            setState(() {
              _recordingDuration = DateTime.now().difference(_recordingStartTime!);
            });
          }
        });
        await _controller!.startVideoRecording();
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
      _timer?.cancel();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Color(0xFF004AAD),
            title: const Text('Camera Error', style: TextStyle(color: Colors.white)),
            content: Text('Failed to record video: $e', style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                child: const Text('OK', style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showUploadDialog(BuildContext context, File videoFile) async {
    final textController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Color(0xFF004AAD),
          title: const Text('Encrypt & Upload', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter text to encrypt and hide in your video:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Your secret message',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4CAF50))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4CAF50))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              child: const Text('Send'),
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isEmpty) return;
                Navigator.of(ctx).pop();
                await _uploadVideoWithText(videoFile, text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadVideoWithText(File videoFile, String text) async {
    setState(() => _isUploading = true);
    try {
      // Encrypt video via API
      const apiUrl = 'http://10.0.2.2:5000/encrypt';
      final result = await sendVideoForEncryption(
        videoFile: videoFile,
        text: text,
        apiUrl: apiUrl,
      );
      // Save the received video to storage
      if (result['mp4'] != null && result['mp4_filename'] != null) {
        final mp4Bytes = base64Decode(result['mp4']);
        final filename = result['mp4_filename'] as String;
        // Save encrypted file locally (optional)
        String? savePath;
        if (Theme.of(context).platform == TargetPlatform.android) {
          final downloadsDir = await getExternalStorageDirectory();
          if (downloadsDir != null) {
            savePath = '${downloadsDir.path}/$filename';
          }
        }
        savePath ??= (await getApplicationDocumentsDirectory()).path + '/$filename';
        final encryptedFile = File(savePath);
        await encryptedFile.writeAsBytes(mp4Bytes);

        // --- Upload to Supabase and create post ---
        final supabaseService = SupabaseService();
        final prefs = await SharedPreferences.getInstance();
        final walletAddress = prefs.getString('wallet_address') ?? '';
        if (walletAddress.isEmpty) {
          setState(() => _isUploading = false);
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Color(0xFF004AAD),
              title: const Text('Error', style: TextStyle(color: Colors.red)),
              content: const Text('No wallet address found. Please log in again.', style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
          return;
        }
        // Ensure profile exists
        final profile = await supabaseService.getUserProfile(walletAddress);
        if (profile == null) {
          await supabaseService.createUserProfile(walletAddress);
        }
        final videoUrl = await supabaseService.uploadVideo(
          encryptedFile.path,
          '${DateTime.now().millisecondsSinceEpoch}_encrypted.mp4',
        );
        await supabaseService.createPost(
          walletAddress: walletAddress,
          videoUrl: videoUrl,
          encryptedContent: text,
        );
        // --- End upload/post creation ---

        setState(() => _isUploading = false);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Color(0xFF004AAD),
            title: const Text('Success!', style: TextStyle(color: Color(0xFF4CAF50))),
            content: Text('Your encrypted video has been uploaded and posted!', style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                child: const Text('OK', style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      } else {
        setState(() => _isUploading = false);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Color(0xFF004AAD),
            title: const Text('Error', style: TextStyle(color: Colors.red)),
            content: const Text('No video data received from server.', style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                child: const Text('OK', style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Color(0xFF004AAD),
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: Text('Failed to upload: $e', style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF004AAD),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > 0) {
                  // Swipe right: move to next tab in navigation
                  Navigator.pop(context, 'nextTab');
                }
                // Optionally, handle swipe left for future features
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _isInitialized && _controller != null
                    ? Stack(
                        children: [
                          CameraPreview(_controller!),
                          if (_isRecording)
                            Positioned(
                              top: 48,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fiber_manual_record, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDuration(_recordingDuration),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Container(color: Colors.black),

                // Top controls (back, flash, switch)
                Positioned(
                  top: 48,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      _buildTranslucentCircle(
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      // Switch camera (optional, add logic if needed)
                      _buildTranslucentCircle(
                        child: IconButton(
                          icon: const Icon(Icons.cameraswitch, color: Colors.white),
                          onPressed: () {
                            // Optional: implement camera switch
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom controls (gallery, record/stop, more)
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTranslucentCircle(
                        child: IconButton(
                          icon: const Icon(Icons.photo_library, color: Colors.white),
                          onPressed: () {
                            // TODO: Open gallery
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: _isInitialized ? _onRecordButtonPressed : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording ? Colors.red.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                            border: Border.all(
                              color: _isRecording ? Colors.red : Colors.white,
                              width: 4,
                            ),
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.fiber_manual_record,
                            color: _isRecording ? Colors.white : Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                      _buildTranslucentCircle(
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                // Centered Title (Instagram-style overlay)
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'CREATE YOUR ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          TextSpan(
                            text: 'DEEP TRUTH',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          TextSpan(
                            text: ' NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
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
          if (_isUploading)
            const ThemedLoader(message: 'Encrypting and uploading your video...'),
        ],
      ),
    );
  }
}