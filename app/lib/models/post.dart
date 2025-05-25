enum PostType { text, photo, video }

class Post {
  final String id;
  final String username;
  final String avatarText;
  final String content;
  final int likes;
  final int comments;
  final PostType? type;
  final String? mediaPath; // local or remote file path

  Post({
    required this.id,
    required this.username,
    required this.avatarText,
    required this.content,
    required this.likes,
    required this.comments,
    this.type,
    this.mediaPath,
  });

  Post copyWith({
    String? id,
    String? username,
    String? avatarText,
    String? content,
    int? likes,
    int? comments,
    PostType? type,
    String? mediaPath,
  }) {
    return Post(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarText: avatarText ?? this.avatarText,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      type: type ?? this.type,
      mediaPath: mediaPath ?? this.mediaPath,
    );
  }
}