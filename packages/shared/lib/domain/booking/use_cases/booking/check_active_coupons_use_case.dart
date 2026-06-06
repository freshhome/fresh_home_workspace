import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/core/error/failures.dart';

class CheckActiveCouponsUseCase {
  final BookingRepository repository;

  CheckActiveCouponsUseCase({required this.repository});

  Future<Either<Failure, bool>> call(String subServiceId) async {
    return await repository.hasActiveCoupons(subServiceId: subServiceId);
  }
}
