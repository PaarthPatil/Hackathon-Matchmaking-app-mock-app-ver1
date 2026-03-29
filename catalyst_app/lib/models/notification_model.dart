class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String message;
  final bool read;
  final String? referenceId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.read = false,
    this.referenceId,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? message,
    bool? read,
    String? referenceId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      read: read ?? this.read,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      message: json['message'],
      read: json['read'] ?? false,
      referenceId: json['reference_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'message': message,
      'read': read,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
