import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/decrypt_service.dart';

class DecryptScreen extends StatefulWidget {
  const DecryptScreen({super.key});

  @override
  State<DecryptScreen> createState() => _DecryptScreenState();
}

class _DecryptScreenState extends State<DecryptScreen> {
  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  String? _error;
  String? _decryptedMessage;
  final _decryptService = DecryptService();

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _videoFile = File(result.files.single.path!);
          _error = null;
          _decryptedMessage = null;
        });

        // Initialize video controller
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(_videoFile!)
          ..initialize().then((_) {
            setState(() {});
            _videoController?.play();
            _videoController?.pause();
          });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking video: $e';
      });
    }
  }

  Future<void> _decryptVideo() async {
    if (_videoFile == null) {
      setState(() {
        _error = 'Please select a video first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _decryptedMessage = null;
    });

    try {
      final message = await _decryptService.decryptVideo(_videoFile!);
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
      appBar: AppBar(title: const Text('Decrypt Content')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video upload button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickVideo,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Video'),
            ),
            const SizedBox(height: 16),

            // Video preview and decrypt button (only shown after video is selected)
            if (_videoController != null &&
                _videoController!.value.isInitialized) ...[
              AspectRatio(
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
              const SizedBox(height: 16),
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
              ),
            ],

            const SizedBox(height: 16),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),

            const SizedBox(height: 16),

            // Decrypted message
            if (_decryptedMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Decrypted Message:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_decryptedMessage!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
