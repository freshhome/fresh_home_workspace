import 'package:equatable/equatable.dart';

class NotificationRemoteModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;

  const NotificationRemoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.metadata,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationRemoteModel.fromJson(Map<String, dynamic> json) {
    return NotificationRemoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, title, body, metadata, isRead, createdAt];
}
