import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/domain/booking/entities/booking/booking_draft.dart';

abstract class BookingDraftLocalDataSource {
  Future<List<BookingDraft>> getDrafts();
  Future<BookingDraft?> getDraftById(String draftId);
  Future<void> saveDraft(BookingDraft draft);
  Future<void> deleteDraft(String draftId);
  Future<void> clearAllDrafts();
}

class BookingDraftLocalDataSourceImpl implements BookingDraftLocalDataSource {
  Future<Box<String>> _openBox() async {
    if (!Hive.isBoxOpen(HiveBoxNames.bookingDraftsBox)) {
      return await Hive.openBox<String>(HiveBoxNames.bookingDraftsBox);
    }
    return Hive.box<String>(HiveBoxNames.bookingDraftsBox);
  }

  @override
  Future<List<BookingDraft>> getDrafts() async {
    try {
      final box = await _openBox();
      final List<BookingDraft> drafts = [];
      for (final rawJson in box.values) {
        try {
          drafts.add(BookingDraft.fromJson(rawJson));
        } catch (_) {
          // Ignore corrupt entry
        }
      }
      // Sort newest first
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return drafts;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<BookingDraft?> getDraftById(String draftId) async {
    try {
      final box = await _openBox();
      final raw = box.get(draftId);
      if (raw == null) return null;
      return BookingDraft.fromJson(raw);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> saveDraft(BookingDraft draft) async {
    try {
      final box = await _openBox();
      await box.put(draft.id, draft.toJson());
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteDraft(String draftId) async {
    try {
      final box = await _openBox();
      await box.delete(draftId);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearAllDrafts() async {
    try {
      final box = await _openBox();
      await box.clear();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
