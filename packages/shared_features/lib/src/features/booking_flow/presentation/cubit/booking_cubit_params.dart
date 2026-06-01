import 'package:shared_features/src/features/booking_flow/domain/booking_flow_config.dart';

/// Parameters passed when constructing [BookingFlowCubit] via GetIt factory.
class BookingCubitParams {
  final BookingFlowConfig config;

  const BookingCubitParams({required this.config});
}
