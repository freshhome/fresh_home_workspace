import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/notification_campaign.dart';

abstract class NotificationManagementRepository {
  /// Fetch a paginated list of notification campaigns.
  Future<Either<Failure, List<NotificationCampaign>>> getCampaigns({int limit = 20, int offset = 0});

  /// Send a new notification campaign immediately or schedule it.
  Future<Either<Failure, NotificationCampaign>> submitCampaign(NotificationCampaign campaign);

  /// Retry a failed campaign.
  Future<Either<Failure, NotificationCampaign>> retryCampaign(String campaignId);

  /// Upload an image to the notification_images bucket.
  Future<Either<Failure, String>> uploadCampaignImage(File image);
}
