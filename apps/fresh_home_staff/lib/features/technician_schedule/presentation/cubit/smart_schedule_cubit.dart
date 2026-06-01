import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/technician/repositories/technician_repository.dart';
import 'smart_schedule_state.dart';

class SmartScheduleCubit extends Cubit<SmartScheduleState> {
  final TechnicianRepository _repository;

  SmartScheduleCubit(this._repository) : super(SmartScheduleInitial());

  Future<void> loadSchedule(String technicianId, {int days = 10}) async {
    emit(SmartScheduleLoading());

    final result = await _repository.getSmartSchedule(technicianId, days);

    result.fold(
      (failure) => emit(SmartScheduleError(failure.message)),
      (forecast) => emit(SmartScheduleLoaded(
        schedule: forecast.schedule,
        generalRecommendation: forecast.generalRecommendation,
      )),
    );
  }


  Future<void> loadDailyBreakdown({
    required String technicianId,
    required DateTime date,
  }) async {
    final currentState = state;
    if (currentState is SmartScheduleLoaded) {
      final result = await _repository.getDailyPoolBreakdown(
        technicianId: technicianId,
        date: date,
      );

      result.fold(
        (failure) => emit(SmartScheduleError(failure.message)),
        (breakdown) => emit(currentState.copyWith(poolBreakdown: breakdown)),
      );
    }
  }

  Future<void> updatePoolCapacity({
    required String technicianId,
    required String poolId,
    required DateTime date,
    required int newCapacity,
    String? slotMask,
  }) async {
    final result = await _repository.updateDailyCapacity(
      technicianId: technicianId,
      date: date,
      newCapacity: newCapacity,
      isBlocked: false,
      poolId: poolId,
      reason: 'Slot update by technician',
      slotMask: slotMask,
    );

    await result.fold(
      (failure) async => emit(SmartScheduleError(failure.message)),
      (_) async {
        await loadSchedule(technicianId);
        await loadDailyBreakdown(technicianId: technicianId, date: date);
      },
    );
  }

  Future<void> updateDailyCapacity({
    required String technicianId,
    required DateTime date,
    required int newCapacity,
    required bool isBlocked,
    String? reason,
    String? slotMask,
  }) async {
    final result = await _repository.updateDailyCapacity(
      technicianId: technicianId,
      date: date,
      newCapacity: newCapacity,
      isBlocked: isBlocked,
      reason: reason,
      slotMask: slotMask,
    );

    await result.fold(
      (failure) async => emit(SmartScheduleError(failure.message)),
      (_) async {
        await loadSchedule(technicianId);
        await loadDailyBreakdown(technicianId: technicianId, date: date);
      },
    );
  }

  Future<void> resetDailyCapacity({
    required String technicianId,
    required DateTime date,
  }) async {
    final result = await _repository.resetDailyCapacity(
      technicianId: technicianId,
      date: date,
    );

    await result.fold(
      (failure) async => emit(SmartScheduleError(failure.message)),
      (_) async => await loadSchedule(technicianId),
    );
  }

  Future<bool> reassignAndBlockCapacity({
    required String technicianId,
    required DateTime date,
    String? poolId,
    int? slotIndex,
  }) async {
    final result = await _repository.reassignAndBlockCapacity(
      technicianId: technicianId,
      date: date,
      poolId: poolId,
      slotIndex: slotIndex,
    );

    return result.fold(
      (failure) {
        emit(SmartScheduleError(failure.message));
        return false;
      },
      (success) async {
        if (success) {
          await loadSchedule(technicianId);
          await loadDailyBreakdown(technicianId: technicianId, date: date);
        }
        return success;
      },
    );
  }
}
