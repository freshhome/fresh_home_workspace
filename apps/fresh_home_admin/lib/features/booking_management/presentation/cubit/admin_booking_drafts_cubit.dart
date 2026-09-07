import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared/domain/booking/entities/booking/booking_draft.dart';
import 'package:shared/domain/booking/repositories/booking_draft_repository.dart';

abstract class AdminBookingDraftsState extends Equatable {
  const AdminBookingDraftsState();

  @override
  List<Object?> get props => [];
}

class AdminBookingDraftsInitial extends AdminBookingDraftsState {
  const AdminBookingDraftsInitial();
}

class AdminBookingDraftsLoading extends AdminBookingDraftsState {
  const AdminBookingDraftsLoading();
}

class AdminBookingDraftsLoaded extends AdminBookingDraftsState {
  final List<BookingDraft> drafts;

  const AdminBookingDraftsLoaded(this.drafts);

  @override
  List<Object?> get props => [drafts];
}

class AdminBookingDraftsError extends AdminBookingDraftsState {
  final String message;

  const AdminBookingDraftsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminBookingDraftsCubit extends Cubit<AdminBookingDraftsState> {
  final BookingDraftRepository repository;

  AdminBookingDraftsCubit({required this.repository})
      : super(const AdminBookingDraftsInitial()) {
    loadDrafts();
  }

  Future<void> loadDrafts() async {
    emit(const AdminBookingDraftsLoading());
    final result = await repository.getDrafts();
    result.fold(
      (failure) => emit(AdminBookingDraftsError(failure.message)),
      (drafts) => emit(AdminBookingDraftsLoaded(drafts)),
    );
  }

  Future<void> deleteDraft(String draftId) async {
    final result = await repository.deleteDraft(draftId);
    result.fold(
      (failure) => emit(AdminBookingDraftsError(failure.message)),
      (_) => loadDrafts(),
    );
  }

  Future<void> clearAllDrafts() async {
    final result = await repository.clearAllDrafts();
    result.fold(
      (failure) => emit(AdminBookingDraftsError(failure.message)),
      (_) => emit(const AdminBookingDraftsLoaded([])),
    );
  }
}
