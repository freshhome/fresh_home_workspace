import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_home_admin/features/web_analytics/data/models/booking_funnel_model.dart';
import 'package:fresh_home_admin/features/web_analytics/domain/entities/booking_funnel_entity.dart';
import 'package:fresh_home_admin/features/web_analytics/domain/entities/web_analytics_entity.dart';
import 'package:fresh_home_admin/features/web_analytics/presentation/cubit/booking_funnel_cubit.dart';
import 'package:fresh_home_admin/features/web_analytics/presentation/cubit/booking_funnel_state.dart';
import 'package:fresh_home_admin/features/web_analytics/domain/usecases/get_booking_funnel_stats_use_case.dart';
import 'package:fresh_home_admin/features/web_analytics/domain/repositories/web_analytics_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';

class MockWebAnalyticsRepository implements WebAnalyticsRepository {
  Either<Failure, BookingFunnelEntity>? funnelResult;

  @override
  Future<Either<Failure, WebAnalyticsEntity>> getTodayAnalytics() async {
    return Left(ServerFailure(message: 'Unimplemented'));
  }

  @override
  Future<Either<Failure, BookingFunnelEntity>> getBookingFunnelStats({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
  }) async {
    return funnelResult ?? Left(ServerFailure(message: 'No mock configured'));
  }
}

void main() {
  group('BookingFunnelModel Deserialization & Calculations', () {
    test('Correctly deserializes authoritative RPC JSON response', () {
      final sampleRpcJson = {
        "summary": {
          "total_started": 1000,
          "total_completed": 413,
          "overall_conversion_rate": 41.3,
          "biggest_drop_off_step": 2,
          "biggest_drop_off_name": "price_calculated",
          "biggest_drop_off_rate": 28.9,
          "biggest_drop_off_count": 238
        },
        "steps": [
          {
            "step_number": 1,
            "event_name": "service_selected",
            "display_name_ar": "اختيار الخدمة",
            "count": 1000,
            "completion_rate": 100.0,
            "drop_off_count": 180,
            "drop_off_rate": 18.0
          },
          {
            "step_number": 2,
            "event_name": "price_calculated",
            "display_name_ar": "حساب السعر",
            "count": 820,
            "completion_rate": 82.0,
            "drop_off_count": 238,
            "drop_off_rate": 28.9
          },
          {
            "step_number": 3,
            "event_name": "schedule_selected",
            "display_name_ar": "اختيار الموعد",
            "count": 582,
            "completion_rate": 58.2,
            "drop_off_count": 52,
            "drop_off_rate": 8.9
          },
          {
            "step_number": 4,
            "event_name": "address_confirmed",
            "display_name_ar": "تأكيد العنوان",
            "count": 530,
            "completion_rate": 53.0,
            "drop_off_count": 117,
            "drop_off_rate": 22.1
          },
          {
            "step_number": 5,
            "event_name": "booking_created",
            "display_name_ar": "إتمام الحجز",
            "count": 413,
            "completion_rate": 41.3,
            "drop_off_count": 0,
            "drop_off_rate": 0.0
          }
        ],
        "filters_applied": {
          "start_date": "2026-08-21T00:00:00Z",
          "end_date": "2026-09-20T00:00:00Z",
          "service_id": null,
          "tracking_version": "v1"
        }
      };

      final model = BookingFunnelModel.fromJson(sampleRpcJson);

      expect(model.summary.totalStarted, 1000);
      expect(model.summary.totalCompleted, 413);
      expect(model.summary.overallConversionRate, 41.3);
      expect(model.summary.biggestDropOffStep, 2);
      expect(model.steps.length, 5);

      // Verify step 1
      expect(model.steps[0].stepNumber, 1);
      expect(model.steps[0].eventName, 'service_selected');
      expect(model.steps[0].count, 1000);
      expect(model.steps[0].completionRate, 100.0);
      expect(model.steps[0].dropOffCount, 180);

      // Verify step 5
      expect(model.steps[4].stepNumber, 5);
      expect(model.steps[4].eventName, 'booking_created');
      expect(model.steps[4].count, 413);
      expect(model.steps[4].completionRate, 41.3);
      expect(model.steps[4].dropOffCount, 0);
    });

    test('Zero-division and empty funnel state handled safely', () {
      final emptyRpcJson = {
        "summary": {
          "total_started": 0,
          "total_completed": 0,
          "overall_conversion_rate": 0.0,
          "biggest_drop_off_step": null,
          "biggest_drop_off_name": null,
          "biggest_drop_off_rate": 0.0,
          "biggest_drop_off_count": 0
        },
        "steps": [
          {
            "step_number": 1,
            "event_name": "service_selected",
            "display_name_ar": "اختيار الخدمة",
            "count": 0,
            "completion_rate": 0.0,
            "drop_off_count": 0,
            "drop_off_rate": 0.0
          },
          {
            "step_number": 2,
            "event_name": "price_calculated",
            "display_name_ar": "حساب السعر",
            "count": 0,
            "completion_rate": 0.0,
            "drop_off_count": 0,
            "drop_off_rate": 0.0
          },
          {
            "step_number": 3,
            "event_name": "schedule_selected",
            "display_name_ar": "اختيار الموعد",
            "count": 0,
            "completion_rate": 0.0,
            "drop_off_count": 0,
            "drop_off_rate": 0.0
          },
          {
            "step_number": 4,
            "event_name": "address_confirmed",
            "display_name_ar": "تأكيد العنوان",
            "count": 0,
            "completion_rate": 0.0,
            "drop_off_count": 0,
            "drop_off_rate": 0.0
          },
          {
            "step_number": 5,
            "event_name": "booking_created",
            "display_name_ar": "إتمام الحجز",
            "count": 0,
            "completion_rate": 0.0,
            "drop_off_count": 0,
            "drop_off_rate": 0.0
          }
        ],
        "filters_applied": {
          "start_date": "2026-08-21T00:00:00Z",
          "end_date": "2026-09-20T00:00:00Z",
          "service_id": null,
          "tracking_version": "v1"
        }
      };

      final model = BookingFunnelModel.fromJson(emptyRpcJson);
      expect(model.summary.totalStarted, 0);
      expect(model.summary.totalCompleted, 0);
      expect(model.summary.overallConversionRate, 0.0);
      expect(model.summary.biggestDropOffStep, isNull);
    });
  });

  group('BookingFunnelCubit State Management', () {
    late MockWebAnalyticsRepository mockRepository;
    late GetBookingFunnelStatsUseCase useCase;
    late BookingFunnelCubit cubit;

    setUp(() {
      mockRepository = MockWebAnalyticsRepository();
      useCase = GetBookingFunnelStatsUseCase(repository: mockRepository);
      cubit = BookingFunnelCubit(getBookingFunnelStatsUseCase: useCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is BookingFunnelInitial', () {
      expect(cubit.state, equals(const BookingFunnelInitial()));
    });

    test('Emits [Loading, Loaded] when funnel data is successfully retrieved', () async {
      final sampleFunnel = BookingFunnelModel(
        summary: const BookingFunnelSummaryModel(
          totalStarted: 50,
          totalCompleted: 20,
          overallConversionRate: 40.0,
          biggestDropOffRate: 20.0,
          biggestDropOffCount: 10,
        ),
        steps: const [
          BookingFunnelStepModel(
            stepNumber: 1,
            eventName: 'service_selected',
            displayNameAr: 'اختيار الخدمة',
            count: 50,
            completionRate: 100.0,
            dropOffCount: 10,
            dropOffRate: 20.0,
          )
        ],
        filters: const BookingFunnelFiltersModel(trackingVersion: 'v1'),
      );

      mockRepository.funnelResult = Right(sampleFunnel);

      final expectedStates = [
        const BookingFunnelLoading(),
        BookingFunnelLoaded(sampleFunnel),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadFunnelStats();
    });

    test('Emits [Loading, Empty] when all step counts are zero', () async {
      final emptyFunnel = BookingFunnelModel(
        summary: const BookingFunnelSummaryModel(
          totalStarted: 0,
          totalCompleted: 0,
          overallConversionRate: 0.0,
          biggestDropOffRate: 0.0,
          biggestDropOffCount: 0,
        ),
        steps: const [
          BookingFunnelStepModel(
            stepNumber: 1,
            eventName: 'service_selected',
            displayNameAr: 'اختيار الخدمة',
            count: 0,
            completionRate: 0.0,
            dropOffCount: 0,
            dropOffRate: 0.0,
          )
        ],
        filters: const BookingFunnelFiltersModel(trackingVersion: 'v1'),
      );

      mockRepository.funnelResult = Right(emptyFunnel);

      final expectedStates = [
        const BookingFunnelLoading(),
        const BookingFunnelEmpty(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadFunnelStats();
    });

    test('Emits [Loading, Error] when repository returns a failure', () async {
      mockRepository.funnelResult = Left(ServerFailure(message: 'خطأ في جلب البيانات'));

      final expectedStates = [
        const BookingFunnelLoading(),
        const BookingFunnelError('خطأ في جلب البيانات'),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadFunnelStats();
    });
  });
}
