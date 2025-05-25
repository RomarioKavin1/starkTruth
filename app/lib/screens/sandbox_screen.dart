import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../services/steno_service.dart';
import '../services/decrypt_service.dart';

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
  final _apiUrl = 'http://192.168.1.3:5000/encrypt';

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

      // Initialize video controller for preview
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_recordedVideo!)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _videoController?.pause();
        });

      // Dispose camera after recording
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

      // Save the encrypted video
      final tempDir = await getTemporaryDirectory();
      final encryptedPath =
          '${tempDir.path}/encrypted_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final encryptedBytes = base64Decode(response['mp4']);
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(encryptedBytes);

      setState(() {
        _encryptedVideo = encryptedFile;
      });

      // Initialize video controller for encrypted video preview
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

  Widget _buildMessageCard(String title, String message) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Steganography Sandbox'), elevation: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera preview (only shown when recording is not done)
            if (_isInitialized &&
                _cameraController != null &&
                _recordedVideo == null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Recording controls (only shown when camera is active)
            if (_cameraController != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : (_isRecording ? _stopRecording : _startRecording),
                    icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
                    label: Text(
                      _isRecording ? 'Stop Recording' : 'Start Recording',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Message input
            if (_recordedVideo != null)
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message to Hide',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Icons.message),
                ),
                maxLines: 3,
              ),

            const SizedBox(height: 16),

            // Video preview
            if (_videoController != null &&
                _videoController!.value.isInitialized)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_videoController!),
                        IconButton(
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 50,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _videoController!.value.isPlaying
                                  ? _videoController!.pause()
                                  : _videoController!.play();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Encrypt button
            if (_recordedVideo != null)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _encryptVideo,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.lock),
                label: Text(_isLoading ? 'Encrypting...' : 'Encrypt Video'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

            const SizedBox(height: 16),

            // Decrypt button (only shown after encryption)
            if (_encryptedVideo != null)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _decryptVideo,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.lock_open),
                label: Text(_isLoading ? 'Decrypting...' : 'Decrypt Video'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

            const SizedBox(height: 16),

            // Decrypted message display
            if (_decryptedMessage != null)
              _buildMessageCard('Decrypted Message', _decryptedMessage!),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
