import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/notification_campaign.dart';
import '../repositories/notification_management_repository.dart';

class SubmitCampaignUseCase {
  final NotificationManagementRepository repository;
  SubmitCampaignUseCase(this.repository);

  Future<Either<Failure, NotificationCampaign>> call(NotificationCampaign campaign) {
    return repository.submitCampaign(campaign);
  }
}

class GetCampaignsUseCase {
  final NotificationManagementRepository repository;
  GetCampaignsUseCase(this.repository);

  Future<Either<Failure, List<NotificationCampaign>>> call({int limit = 20, int offset = 0}) {
    return repository.getCampaigns(limit: limit, offset: offset);
  }
}

class RetryCampaignUseCase {
  final NotificationManagementRepository repository;
  RetryCampaignUseCase(this.repository);

  Future<Either<Failure, NotificationCampaign>> call(String campaignId) {
    return repository.retryCampaign(campaignId);
  }
}

class UploadCampaignImageUseCase {
  final NotificationManagementRepository repository;
  UploadCampaignImageUseCase(this.repository);

  Future<Either<Failure, String>> call(File image) {
    return repository.uploadCampaignImage(image);
  }
}
