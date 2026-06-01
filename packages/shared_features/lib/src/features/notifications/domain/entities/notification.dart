import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.metadata,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      metadata: metadata,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, body, metadata, isRead, createdAt];
}
