import 'package:catalyst_app/models/profile_model.dart';

class Message {
  final String id;
  final String teamId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final Profile? sender;

  Message({
    required this.id,
    required this.teamId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      teamId: json['team_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      sender: json['profiles'] != null ? Profile.fromJson(json['profiles']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
