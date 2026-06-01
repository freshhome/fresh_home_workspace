// import 'package:flutter_test/flutter_test.dart';
// import 'package:fpdart/fpdart.dart';
// import 'package:shared/domain/technician/entities/smart_schedule_entry.dart';
// import 'package:shared/domain/technician/repositories/technician_repository.dart';
// import 'package:shared/core/error/failures.dart';
// import 'package:fresh_home_staff/features/technician_schedule/presentation/cubit/smart_schedule_cubit.dart';
// import 'package:fresh_home_staff/features/technician_schedule/presentation/cubit/smart_schedule_state.dart';

// class MockTechnicianRepository implements TechnicianRepository {
//   Either<Failure, WorkloadForecast>? result;

//   @override
//   Future<Either<Failure, WorkloadForecast>> getSmartSchedule(String technicianId, int days) async {
//     return result!;
//   }
// }

// void main() {
//   late SmartScheduleCubit cubit;
//   late MockTechnicianRepository mockRepository;

//   setUp(() {
//     mockRepository = MockTechnicianRepository();
//     cubit = SmartScheduleCubit(mockRepository);
//   });

//   tearDown(() {
//     cubit.close();
//   });

//   group('SmartScheduleCubit', () {
//     const tTechnicianId = 'tech123';
//     final tWorkloadForecast = WorkloadForecast(
//       schedule: [
//         SmartScheduleEntry(
//           date: DateTime(2026, 4, 21),
//           status: 'recommended',
//           utilization: 0.5,
//           bookingsCount: 5,
//           capacity: 10,
//           riskScore: 0.1,
//           forceMultiplier: 1.0,
//           suggestion: 'Good',
//           isOverride: false,
//         ),
//       ],
//       averageRisk: 0.1,
//       generalRecommendation: 'Keep going',
//     );

//     test('initial state should be SmartScheduleInitial', () {
//       expect(cubit.state, SmartScheduleInitial());
//     });

//     test('should emit [Loading, Loaded] when data is gotten successfully', () async {
//       // arrange
//       mockRepository.result = Right(tWorkloadForecast);
//       // assert later
//       final expectedStates = [
//         SmartScheduleLoading(),
//         SmartScheduleLoaded(
//           schedule: tWorkloadForecast.schedule,
//           generalRecommendation: tWorkloadForecast.generalRecommendation,
//         ),
//       ];
//       expectLater(cubit.stream, emitsInOrder(expectedStates));
//       // act
//       await cubit.loadSchedule(tTechnicianId);
//     });

//     test('should emit [Loading, Error] when getting data fails', () async {
//       // arrange
//       mockRepository.result = const Left(ServerFailure(message: 'Server Error'));
//       // assert later
//       final expectedStates = [
//         SmartScheduleLoading(),
//         const SmartScheduleError('Server Error'),
//       ];
//       expectLater(cubit.stream, emitsInOrder(expectedStates));
//       // act
//       await cubit.loadSchedule(tTechnicianId);
//     });
//   });
// }
