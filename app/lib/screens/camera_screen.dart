import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../services/steno_service.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/starknet_service.dart';
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
  String stringToFeltHexList(String input) {
  // Split string into 31-byte chunks (Felt max for short string)
  final bytes = input.codeUnits;
  List<String> felts = [];
  for (int i = 0; i < bytes.length; i += 31) {
    final chunk = bytes.sublist(i, i + 31 > bytes.length ? bytes.length : i + 31);
    final value = BigInt.parse(chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
    felts.add('0x${value.toRadixString(16)}');
  }
  return felts.join('');
}
  Future<void> _uploadVideoWithText(File videoFile, String text) async {
    setState(() => _isUploading = true);
    try {
      // 1. Get wallet address
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
      print(walletAddress);
      // 2. Call create_pre_secret on StarkNet contract
      final secretHash = await createPreSecret(walletAddress);
      print(secretHash);
      // 3. Encrypt video with secretHash
      const apiUrl = 'http://10.0.2.2:5000/encrypt';
      final result = await sendVideoForEncryption(
        videoFile: videoFile,
        apiUrl: apiUrl,
        text: secretHash, // Pass the secret hash to your encryption API
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
          await supabaseService.createUserProfile(walletAddress, '', '');
        }
        final video_filename=DateTime.now().millisecondsSinceEpoch.toString();
        final videoUrl = await supabaseService.uploadVideo(
          encryptedFile.path,
          '${video_filename}.mp4',
        );
        await supabaseService.createPost(
          walletAddress: walletAddress,
          videoUrl: videoUrl,
          encryptedContent: text,
        );

        // 5. Call associate_post_details on StarkNet contract with new format
        await associatePostDetails(
          secretId: secretHash,
          postId: video_filename,
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
      print(e);
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
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
                    : Container(
                      color: Colors.black,
                      child: const Center(
                        child: BrutalistContainer(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: Color(0xFF004AAD),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Initializing camera...',
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

                // Top controls
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BrutalistButton(
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      BrutalistButton(
                        onPressed: () {
                          // Optional: implement camera switch
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.cameraswitch,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 56,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isRecording
                            ? 'Tap to stop recording'
                            : 'Tap to start recording',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _isInitialized ? _onRecordButtonPressed : null,
                        child: BrutalistContainer(
                          width: 80,
                          height: 80,
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
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                        'Processing your video...',
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
