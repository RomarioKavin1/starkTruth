enum PostType { text, photo, video }

class Post {
  final String username;
  final String avatarText;
  final String content;
  final int likes;
  final int comments;
  final PostType? type;
  final String? mediaPath; // local or remote file path

  Post({
    required this.username,
    required this.avatarText,
    required this.content,
    required this.likes,
    required this.comments,
    this.type,
    this.mediaPath,
  });
}