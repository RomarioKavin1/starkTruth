import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../services/steno_service.dart';
import '../services/decrypt_service.dart';
import '../widgets/brutalist_components.dart';

class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isInitialized = false;
  File? _recordedVideo;
  VideoPlayerController? _videoController;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  File? _encryptedVideo;
  String? _decryptedMessage;
  final _decryptService = DecryptService();
  final _apiUrl = 'http://192.168.1.4:5000/encrypt';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() {
        _error = 'No cameras available';
      });
      return;
    }

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to start recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile video = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _recordedVideo = File(video.path);
      });

      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_recordedVideo!)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _videoController?.pause();
        });

      await _cameraController?.dispose();
      setState(() {
        _cameraController = null;
        _isInitialized = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to stop recording: $e';
      });
    }
  }

  Future<void> _encryptVideo() async {
    if (_recordedVideo == null || _messageController.text.isEmpty) {
      setState(() {
        _error = 'Please record a video and enter a message';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await sendVideoForEncryption(
        videoFile: _recordedVideo!,
        text: _messageController.text,
        apiUrl: _apiUrl,
      );

      final tempDir = await getTemporaryDirectory();
      final encryptedPath =
          '${tempDir.path}/encrypted_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final encryptedBytes = base64Decode(response['mp4']);
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(encryptedBytes);

      setState(() {
        _encryptedVideo = encryptedFile;
      });

      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_encryptedVideo!)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _videoController?.pause();
        });
    } catch (e) {
      setState(() {
        _error = 'Failed to encrypt video: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _decryptVideo() async {
    if (_encryptedVideo == null) {
      setState(() {
        _error = 'No encrypted video available';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final message = await _decryptService.decryptVideo(_encryptedVideo!);
      setState(() {
        _decryptedMessage = message;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            'Sandbox',
            style: TextStyle(
              color: Color(0xFF004AAD),
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isInitialized &&
                _cameraController != null &&
                _recordedVideo == null)
              BrutalistContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Camera Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: BrutalistButton(
                        onPressed:
                            _isLoading
                                ? null
                                : (_isRecording
                                    ? _stopRecording
                                    : _startRecording),
                        backgroundColor:
                            _isRecording ? Colors.red : const Color(0xFF004AAD),
                        color: Colors.white,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRecording ? Icons.stop : Icons.videocam,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isRecording
                                  ? 'Stop Recording'
                                  : 'Start Recording',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_recordedVideo != null) ...[
              const SizedBox(height: 16),
              BrutalistContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message to Hide',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BrutalistTextField(
                      controller: _messageController,
                      hintText: 'Enter your secret message...',
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ],

            if (_videoController != null &&
                _videoController!.value.isInitialized) ...[
              const SizedBox(height: 16),
              BrutalistContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_videoController!),
                          BrutalistIconButton(
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                            icon:
                                _videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                            size: 32,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_recordedVideo != null) ...[
              const SizedBox(height: 16),
              BrutalistButton(
                onPressed: _isLoading ? null : _encryptVideo,
                isLoading: _isLoading,
                backgroundColor: const Color(0xFF004AAD),
                color: Colors.white,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isLoading ? 'Encrypting...' : 'Encrypt Video',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_encryptedVideo != null) ...[
              const SizedBox(height: 16),
              BrutalistButton(
                onPressed: _isLoading ? null : _decryptVideo,
                isLoading: _isLoading,
                backgroundColor: const Color(0xFF004AAD),
                color: Colors.white,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_open, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isLoading ? 'Decrypting...' : 'Decrypt Video',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_decryptedMessage != null) ...[
              const SizedBox(height: 16),
              BrutalistContainer(
                backgroundColor: Colors.green.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Decrypted Message',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _decryptedMessage!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              BrutalistContainer(
                backgroundColor: Colors.red.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
