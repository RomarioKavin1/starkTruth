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
import '../widgets/brutalist_components.dart';

class CameraScreen extends StatefulWidget {
  final void Function(File videoFile)? onVideoRecorded;
  const CameraScreen({super.key, this.onVideoRecorded});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _isUploading = false;
  File? _lastRecordedFile;
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
        _timer?.cancel();
        final file = await _controller!.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });
        _lastRecordedFile = File(file.path);
        _showUploadDialog(context, _lastRecordedFile!);
      } else {
        setState(() {
          _isRecording = true;
          _recordingStartTime = DateTime.now();
          _recordingDuration = Duration.zero;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_recordingStartTime != null && mounted && _isRecording) {
            setState(() {
              _recordingDuration = DateTime.now().difference(
                _recordingStartTime!,
              );
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
          builder:
              (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'Camera Error',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                content: Text(
                  'Failed to record video: $e',
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
                actions: [
                  BrutalistButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
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
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Encrypt & Upload',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter text to encrypt and hide in your video:',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              BrutalistTextField(
                controller: textController,
                hintText: 'Your secret message',
              ),
            ],
          ),
          actions: [
            BrutalistButton(
              onPressed: () => Navigator.of(ctx).pop(),
              backgroundColor: Colors.grey.shade100,
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 18),
            BrutalistButton(
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isEmpty) return;
                Navigator.of(ctx).pop();
                await _uploadVideoWithText(videoFile, text);
              },
              backgroundColor: const Color(0xFF004AAD),
              color: Colors.white,
              child: const Text(
                'Send',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadVideoWithText(File videoFile, String text) async {
    setState(() => _isUploading = true);
    try {
      const apiUrl = 'http://10.0.2.2:5000/encrypt';
      final result = await sendVideoForEncryption(
        videoFile: videoFile,
        text: text,
        apiUrl: apiUrl,
      );
      if (result['mp4'] != null && result['mp4_filename'] != null) {
        final mp4Bytes = base64Decode(result['mp4']);
        final filename = result['mp4_filename'] as String;
        String? savePath;
        if (Theme.of(context).platform == TargetPlatform.android) {
          final downloadsDir = await getExternalStorageDirectory();
          if (downloadsDir != null) {
            savePath = '${downloadsDir.path}/$filename';
          }
        }
        savePath ??=
            (await getApplicationDocumentsDirectory()).path + '/$filename';
        final encryptedFile = File(savePath);
        await encryptedFile.writeAsBytes(mp4Bytes);

        final supabaseService = SupabaseService();
        final prefs = await SharedPreferences.getInstance();
        final walletAddress = prefs.getString('wallet_address') ?? '';
        if (walletAddress.isEmpty) {
          setState(() => _isUploading = false);
          if (!mounted) return;
          showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text(
                    'Error',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                  content: const Text(
                    'No wallet address found. Please log in again.',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  actions: [
                    BrutalistButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
          return;
        }

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

        setState(() => _isUploading = false);
        if (!mounted) return;
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'Success!',
                  style: TextStyle(
                    color: Color(0xFF004AAD),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
                content: const Text(
                  'Your encrypted video has been uploaded and posted!',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                actions: [
                  BrutalistButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        setState(() => _isUploading = false);
        if (!mounted) return;
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
                content: const Text(
                  'No video data received from server.',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                actions: [
                  BrutalistButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
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
        builder:
            (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Error',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              content: Text(
                'Failed to upload: $e',
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
              actions: [
                BrutalistButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
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
            'Record',
            style: TextStyle(
              color: Color(0xFF004AAD),
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 0) {
                Navigator.pop(context, 'nextTab');
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
                            top: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: BrutalistContainer(
                                backgroundColor: Colors.black,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.fiber_manual_record,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDuration(_recordingDuration),
                                      style: const TextStyle(
                                        color: Colors.white,
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
                    )
                    : Container(color: Colors.black),

                // Top controls
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BrutalistIconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icons.arrow_back,
                        size: 20,
                      ),
                      BrutalistIconButton(
                        onPressed: () {
                          // Optional: implement camera switch
                        },
                        icon: Icons.cameraswitch,
                        size: 20,
                      ),
                    ],
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 56,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _isInitialized ? _onRecordButtonPressed : null,
                        child: BrutalistContainer(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.red : Colors.white,
                              shape: BoxShape.rectangle,
                            ),
                            child: Icon(
                              _isRecording
                                  ? Icons.stop
                                  : Icons.fiber_manual_record,
                              color: _isRecording ? Colors.white : Colors.red,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Centered Title
              ],
            ),
          ),
          if (_isUploading)
            const ThemedLoader(
              message: 'Encrypting and uploading your video...',
            ),
        ],
      ),
    );
  }
}
