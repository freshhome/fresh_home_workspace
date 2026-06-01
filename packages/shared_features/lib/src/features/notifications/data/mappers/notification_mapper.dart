import '../../domain/entities/notification.dart';
import '../models/notification_remote_model.dart';

class NotificationMapper {
  static AppNotification remoteToEntity(NotificationRemoteModel model) {
    return AppNotification(
      id: model.id,
      userId: model.userId,
      title: model.title,
      body: model.body,
      metadata: model.metadata,
      isRead: model.isRead,
      createdAt: model.createdAt,
    );
  }

  static NotificationRemoteModel entityToRemote(AppNotification entity) {
    return NotificationRemoteModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      body: entity.body,
      metadata: entity.metadata,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
    );
  }
}
