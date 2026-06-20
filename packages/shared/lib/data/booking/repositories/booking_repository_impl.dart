import 'package:fpdart/fpdart.dart';

import 'package:shared/data/booking/datasources/booking_local_datasource.dart';
import 'package:shared/data/booking/datasources/booking_remote_datasource.dart';
import 'package:shared/data/booking/mappers/booking_mapper.dart';
import 'package:shared/data/booking/models/remote/order_status_model.dart';

import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';


class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final BookingLocalDataSource localDataSource;

  BookingRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, String>> createBooking({
    required Booking booking,
  }) async {
    try {
      final remoteModel = BookingMapper.entityToRemote(booking);
      final newUuid = await remoteDataSource.createBooking(booking: remoteModel);
      return Right(newUuid);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> getBookingById({required String id}) async {
    try {
      final localBooking = await localDataSource.getBookingById(id);
      if (localBooking != null) {
        return Right(BookingMapper.hiveToEntity(localBooking));
      }
      final remoteModel = await remoteDataSource.getBookingById(id);
      await localDataSource.cacheBooking(
        BookingMapper.remoteToHive(remoteModel),
      );
      return Right(BookingMapper.remoteToEntity(remoteModel));
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Booking>>> watchUserBookings({
    required String userId,
  }) {
    return remoteDataSource.watchUserBookings(userId).map((remoteModels) {
      try {
        final entities = remoteModels
            .map((model) => BookingMapper.remoteToEntity(model))
            .toList();
        return Right(entities);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    });
  }

  @override
  Stream<Either<Failure, List<Booking>>> watchAllBookings({
    List<String>? serviceNames,
  }) {
    return remoteDataSource.watchAllBookings(serviceNames: serviceNames).map((
      remoteModels,
    ) {
      try {
        final entities = remoteModels
            .map((model) => BookingMapper.remoteToEntity(model))
            .toList();
        return Right(entities);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    });
  }

  @override
  Stream<Either<Failure, Booking>> watchBooking({required String bookingId}) {
    return remoteDataSource.watchBooking(bookingId).map((model) {
      try {
        return Right<Failure, Booking>(BookingMapper.remoteToEntity(model));
      } catch (e) {
        return Left<Failure, Booking>(ServerFailure(message: e.toString()));
      }
    }).handleError((e) => Left<Failure, Booking>(ServerFailure(message: e.toString())));
  }

  @override
  Future<Either<Failure, List<Booking>>> getUserBookings({
    required String userId,
  }) async {
    try {
      try {
        final remoteModels = await remoteDataSource.getUserBookings(userId);
        final hiveModels = remoteModels
            .map((e) => BookingMapper.remoteToHive(e))
            .toList();
        await localDataSource.cacheBookings(hiveModels);
        return Right(
          remoteModels
              .map((model) => BookingMapper.remoteToEntity(model))
              .toList(),
        );
      } catch (e) {
        final localModels = await localDataSource.getUserBookings(userId);
        if (localModels.isNotEmpty) {
          return Right(
            localModels
                .map((model) => BookingMapper.hiveToEntity(model))
                .toList(),
          );
        }
        rethrow;
      }
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBooking({
    required Booking booking,
  }) async {
    try {
      final remoteModel = BookingMapper.entityToRemote(booking);
      await remoteDataSource.updateBooking(booking: remoteModel);
      await localDataSource.cacheBooking(
        BookingMapper.remoteToHive(remoteModel),
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> transitionBooking({
    required String bookingId,
    required OrderStatus newStatus,
    required String actorId,
    required String actorRole,
    String? reason,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await remoteDataSource.transitionBooking(
        bookingId: bookingId,
        newStatus: OrderStatusModel.toJson(newStatus),
        actorId: actorId,
        actorRole: actorRole,
        reason: reason,
        notes: notes,
        metadata: metadata,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking({
    required String bookingId,
  }) async {
    try {
      await remoteDataSource.cancelBooking(bookingId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adminConfirmWhatsappBooking({
    required String bookingId,
  }) async {
    try {
      await remoteDataSource.adminConfirmWhatsappBooking(bookingId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookingSchedule({
    required String bookingId,
    required DateTime newDay,
    required String newTimeSlot,
    required String actorId,
  }) async {
    try {
      await remoteDataSource.updateBookingSchedule(
        bookingId: bookingId,
        newDay: newDay,
        newTimeSlot: newTimeSlot,
        actorId: actorId,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookingAddress({
    required String bookingId,
    required Address address,
    required Contact contact,
    required String actorId,
  }) async {
    try {
      await remoteDataSource.updateBookingAddress(
        bookingId: bookingId,
        addressSnapshot: BookingMapper.addressToSnapshot(address).toJson(),
        contactSnapshot: BookingMapper.contactToSnapshot(contact).toJson(),
        actorId: actorId,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingPricing>> calculateBookingPrice({
    required String subServiceId,
    required Map<String, dynamic> pricingInputs,
  }) async {
    try {
      final response = await remoteDataSource.calculateBookingPrice(
        subServiceId: subServiceId,
        pricingInputs: pricingInputs,
      );
      final pricing = BookingPricing(
        basePrice: (response['basePrice'] as num).toDouble(),
        extraFees: (response['extraFees'] as num).toDouble(),
        discount: (response['discount'] as num).toDouble(),
        total: (response['total'] as num).toDouble(),
        metadata: response['metadata'] != null ? Map<String, dynamic>.from(response['metadata'] as Map) : null,
      );
      return Right(pricing);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasActiveCoupons({
    required String subServiceId,
  }) async {
    try {
      final result = await remoteDataSource.hasActiveCoupons(subServiceId);
      return Right(result);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
