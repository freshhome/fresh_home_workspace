import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification_campaign.dart';
import '../../domain/repositories/notification_management_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_campaign_model.dart';

class NotificationManagementRepositoryImpl implements NotificationManagementRepository {
  final NotificationManagementRemoteDataSource remoteDataSource;

  NotificationManagementRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<NotificationCampaign>>> getCampaigns({int limit = 20, int offset = 0}) async {
    try {
      final models = await remoteDataSource.fetchCampaigns(limit: limit, offset: offset);
      return Right(models);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationCampaign>> submitCampaign(NotificationCampaign campaign) async {
    try {
      final model = NotificationCampaignModel.fromEntity(campaign);
      final result = await remoteDataSource.insertCampaign(model);
      return Right(result);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationCampaign>> retryCampaign(String campaignId) async {
    try {
      // Retrying sets the status back to sending, which trips the DB trigger again
      final result = await remoteDataSource.updateCampaignStatus(campaignId, 'sending');
      return Right(result);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadCampaignImage(File image) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return Left(CacheFailure(message: 'User not logged in'));
      
      final url = await remoteDataSource.uploadImage(image, currentUserId);
      return Right(url);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
