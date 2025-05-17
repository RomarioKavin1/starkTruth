import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../models/post.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<Post> _posts = [
    Post(
      username: 'truthseeker',
      avatarText: 'T',
      content: 'The truth about our society that no one wants to talk about.',
      likes: 1243,
      comments: 89,
    ),
    Post(
      username: 'deepdiver',
      avatarText: 'D',
      content: 'What I discovered after years of research.',
      likes: 856,
      comments: 42,
    ),
    Post(
      username: 'realitycheck',
      avatarText: 'R',
      content: 'This is what they don\'t want you to know about current events.',
      likes: 2134,
      comments: 156,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Truth',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              TextSpan(
                text: 'Cast',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: _posts[index]);
        },
      ),
    );
  }
}