
import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/data/booking/models/local/booking_hive_model.dart';
import 'package:shared/core/error/exceptions.dart';

abstract class BookingLocalDataSource {
  Future<void> cacheBooking(BookingHiveModel booking);
  Future<void> cacheBookings(List<BookingHiveModel> bookings);
  Future<List<BookingHiveModel>> getUserBookings(String userId);
  Future<BookingHiveModel?> getBookingById(String id);
  Future<void> clearCache();
}

class BookingLocalDataSourceImpl implements BookingLocalDataSource {
  @override
  Future<void> cacheBooking(BookingHiveModel booking) async {
    try {
      final box = await _openBox();
      await box.put(booking.id, booking);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheBookings(List<BookingHiveModel> bookings) async {
    try {
      final box = await _openBox();
      final Map<String, BookingHiveModel> entries = {
        for (var booking in bookings) booking.id: booking
      };
      await box.putAll(entries);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _openBox();
      await box.clear();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<BookingHiveModel?> getBookingById(String id) async {
    try {
      final box = await _openBox();
      return box.get(id);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<List<BookingHiveModel>> getUserBookings(String userId) async {
    try {
      final box = await _openBox();
      return box.values.where((booking) => booking.userId == userId).toList();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  Future<Box<BookingHiveModel>> _openBox() async {
    if (!Hive.isBoxOpen(HiveBoxNames.bookingsBox)) {
      return await Hive.openBox<BookingHiveModel>(HiveBoxNames.bookingsBox);
    }
    return Hive.box<BookingHiveModel>(HiveBoxNames.bookingsBox);
  }
}
