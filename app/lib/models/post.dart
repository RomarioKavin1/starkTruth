class Post {
  final String username;
  final String avatarText;
  final String content;
  final int likes;
  final int comments;
  final String? imageUrl;

  Post({
    required this.username,
    required this.avatarText,
    required this.content,
    required this.likes,
    required this.comments,
    this.imageUrl,
  });
}