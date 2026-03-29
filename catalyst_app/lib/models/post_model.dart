import 'package:catalyst_app/models/profile_model.dart';

class Post {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;
  final Profile? author; // Populated from join

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    this.upvotes = 0,
    this.downvotes = 0,
    required this.createdAt,
    this.author,
  });

  Post copyWith({
    String? id,
    String? userId,
    String? content,
    String? imageUrl,
    int? upvotes,
    int? downvotes,
    DateTime? createdAt,
    Profile? author,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      imageUrl: json['image_url'],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      author: json['profiles'] != null ? Profile.fromJson(json['profiles']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
