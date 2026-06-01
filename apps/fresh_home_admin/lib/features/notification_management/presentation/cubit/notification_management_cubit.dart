import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_campaign.dart';
import '../../domain/use_cases/campaign_use_cases.dart';

// --- States ---
abstract class NotificationManagementState extends Equatable {
  const NotificationManagementState();
  @override List<Object?> get props => [];
}
class NotificationManagementInitial extends NotificationManagementState {}
class NotificationManagementLoading extends NotificationManagementState {}
class NotificationManagementLoaded extends NotificationManagementState {
  final List<NotificationCampaign> campaigns;
  const NotificationManagementLoaded(this.campaigns);
  @override List<Object?> get props => [campaigns];
}
class NotificationCampaignSending extends NotificationManagementState {}
class NotificationImageUploading extends NotificationManagementState {}
class NotificationCampaignActionSuccess extends NotificationManagementState {
  final String message;
  const NotificationCampaignActionSuccess(this.message);
  @override List<Object?> get props => [message];
}
class NotificationManagementError extends NotificationManagementState {
  final String message;
  const NotificationManagementError(this.message);
  @override List<Object?> get props => [message];
}

// --- Cubit ---
class NotificationManagementCubit extends Cubit<NotificationManagementState> {
  final GetCampaignsUseCase getCampaignsUseCase;
  final SubmitCampaignUseCase submitCampaignUseCase;
  final RetryCampaignUseCase retryCampaignUseCase;
  final UploadCampaignImageUseCase uploadCampaignImageUseCase;

  NotificationManagementCubit({
    required this.getCampaignsUseCase,
    required this.submitCampaignUseCase,
    required this.retryCampaignUseCase,
    required this.uploadCampaignImageUseCase,
  }) : super(NotificationManagementInitial());

  Future<void> fetchCampaigns() async {
    emit(NotificationManagementLoading());
    final result = await getCampaignsUseCase();
    result.fold(
      (failure) => emit(NotificationManagementError(failure.message)),
      (campaigns) => emit(NotificationManagementLoaded(campaigns)),
    );
  }

  Future<void> submitCampaign(NotificationCampaign campaign) async {
    emit(NotificationCampaignSending());
    final result = await submitCampaignUseCase(campaign);
    result.fold(
      (failure) {
        emit(NotificationManagementError(failure.message));
        fetchCampaigns(); // refresh if mixed state
      },
      (_) {
        emit(const NotificationCampaignActionSuccess('Campaign submitted successfully!'));
        fetchCampaigns();
      },
    );
  }

  Future<void> retryCampaign(String id) async {
    emit(NotificationCampaignSending());
    final result = await retryCampaignUseCase(id);
    result.fold(
      (failure) {
        emit(NotificationManagementError(failure.message));
        fetchCampaigns();
      },
      (_) {
        emit(const NotificationCampaignActionSuccess('Campaign retried!'));
        fetchCampaigns();
      },
    );
  }

  Future<String?> uploadImage(File file) async {
    // Preserve old list while uploading if possible
    final prevState = state; 
    emit(NotificationImageUploading());
    final result = await uploadCampaignImageUseCase(file);
    return result.fold(
      (failure) {
        emit(NotificationManagementError(failure.message));
        if (prevState is NotificationManagementLoaded) {
          emit(prevState);
        }
        return null; // Signals failure
      },
      (url) {
        if (prevState is NotificationManagementLoaded) {
          emit(prevState);
        } else {
          emit(NotificationManagementInitial());
        }
        return url; // Return URL to be used in UI text field
      },
    );
  }
}
