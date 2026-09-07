import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/entities/booking/booking_draft.dart';

abstract class BookingDraftRepository {
  Future<Either<Failure, List<BookingDraft>>> getDrafts();
  Future<Either<Failure, BookingDraft?>> getDraftById(String draftId);
  Future<Either<Failure, Unit>> saveDraft(BookingDraft draft);
  Future<Either<Failure, Unit>> deleteDraft(String draftId);
  Future<Either<Failure, Unit>> clearAllDrafts();
}
