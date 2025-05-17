import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'dart:io';

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
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitialized = false;

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
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onRecordButtonPressed() async {
    if (_isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      if (widget.onVideoRecorded != null) {
        widget.onVideoRecorded!(File(file.path));
      }
      if (mounted) Navigator.pop(context);
    } else {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
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
                ? CameraPreview(_controller!)
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
    );
  }
}