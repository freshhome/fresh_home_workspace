import 'package:fpdart/fpdart.dart';
import 'package:shared/core/usecase/usecase.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';

import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/entities/sub_entities/service_price.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';

class CalculatePriceParams {
  final PriceEntity priceEntity;
  final String? subServiceId;
  final double? area;
  final double? width;
  final double? height;
  final double? totalLinearMeters;
  final List<WindowDimension>? windows;
  final List<String>? selectedOptions;
  final Map<String, dynamic> pricingInputs;

  const CalculatePriceParams({
    required this.priceEntity,
    this.subServiceId,
    this.area,
    this.width,
    this.height,
    this.totalLinearMeters,
    this.windows,
    this.selectedOptions,
    this.pricingInputs = const {},
  });
}

class CalculatePriceUseCase
    extends UseCase<BookingPricing, CalculatePriceParams> {
  final BookingRepository repository;

  CalculatePriceUseCase(this.repository);

  @override
  Future<Either<Failure, BookingPricing>> call(
    CalculatePriceParams params,
  ) async {
    // ── Security Guard ────────────────────────────────────────────────────────
    // The backend is the ONLY source of truth for pricing.
    // This use case will NOT perform any local math, fallback calculations,
    // or offline price estimation. If the API cannot be reached, a hard
    // Failure is returned and the UI must surface an error to the user.
    // ─────────────────────────────────────────────────────────────────────────

    if (params.subServiceId == null) {
      return Left(
        ValidationFailure(message: 'لا يمكن حساب السعر: معرّف الخدمة غير متاح'),
      );
    }

    // Merge all user inputs into a single pricing inputs map for the backend.
    final pricingInputs = <String, dynamic>{
      ...params.pricingInputs,
      if (params.area != null) 'area': params.area,
      if (params.totalLinearMeters != null)
        'total_linear_meters': params.totalLinearMeters,
      if (params.windows != null)
        'windows': params.windows!
            .map(
              (w) => {
                'width': w.width,
                'height': w.height,
                'quantity': w.quantity,
                'is_both_sides': w.isBothSides,
              },
            )
            .toList(),
      if (params.selectedOptions != null)
        'selected_options': params.selectedOptions,
    };

    // Delegate entirely to the backend RPC. On failure, propagate the Failure
    // upstream — the frontend must NEVER attempt a local calculation.
    return repository.calculateBookingPrice(
      subServiceId: params.subServiceId!,
      pricingInputs: pricingInputs,
    );
  }
}
