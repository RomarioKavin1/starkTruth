import 'dart:io';

import 'package:flutter/material.dart';
import '../models/post.dart';

import 'package:video_player/video_player.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;
    if (post.type == PostType.photo && post.mediaPath != null && post.mediaPath!.isNotEmpty) {
      contentWidget = Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: post.mediaPath!.startsWith('http')
                    ? Image.network(
                        post.mediaPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                          ),
                        ),
                      )
                    : Image.asset(post.mediaPath!, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      );
    } else if (post.type == PostType.video && post.mediaPath != null && post.mediaPath!.isNotEmpty) {
      contentWidget = Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 240,
              child: _VideoPlayerWidget(videoPath: post.mediaPath!),
            ),
          ),
        ],
      );
    } else if ((post.type == null || post.type == PostType.text) && post.content.isNotEmpty) {
      contentWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          post.content,
          style: const TextStyle(fontSize: 16),
        ),
      );
    } else {
      // Fallback: minimal placeholder if nothing to show
      contentWidget = const SizedBox(height: 8);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!, width: 1),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  radius: 20,
                  child: Text(
                    post.avatarText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '@${post.username}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.share, size: 16),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            contentWidget,
            // Post actions
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.likes.toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.comments.toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
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

class _VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  const _VideoPlayerWidget({required this.videoPath});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.videoPath.startsWith('assets/')
        ? VideoPlayerController.asset(widget.videoPath)
        : VideoPlayerController.file(File(widget.videoPath));
    _controller.initialize().then((_) {
      setState(() {
        _initialized = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.black.withOpacity(0.6),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying ? _controller.pause() : _controller.play();
                      });
                    },
                    child: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container(
            height: 240,
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
  }
}