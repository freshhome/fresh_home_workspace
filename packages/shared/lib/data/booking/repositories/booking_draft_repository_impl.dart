import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/data/booking/datasources/booking_draft_local_datasource.dart';
import 'package:shared/domain/booking/entities/booking/booking_draft.dart';
import 'package:shared/domain/booking/repositories/booking_draft_repository.dart';

class BookingDraftRepositoryImpl implements BookingDraftRepository {
  final BookingDraftLocalDataSource localDataSource;

  BookingDraftRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<BookingDraft>>> getDrafts() async {
    try {
      final drafts = await localDataSource.getDrafts();
      return Right(drafts);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingDraft?>> getDraftById(String draftId) async {
    try {
      final draft = await localDataSource.getDraftById(draftId);
      return Right(draft);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveDraft(BookingDraft draft) async {
    try {
      await localDataSource.saveDraft(draft);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDraft(String draftId) async {
    try {
      await localDataSource.deleteDraft(draftId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearAllDrafts() async {
    try {
      await localDataSource.clearAllDrafts();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
