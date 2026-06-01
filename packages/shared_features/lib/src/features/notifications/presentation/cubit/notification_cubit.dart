import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification.dart';
import '../../domain/usecases/watch_notifications_use_case.dart';
import '../../domain/usecases/mark_notification_read_use_case.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  NotificationLoaded(this.notifications);
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}

class NotificationCubit extends Cubit<NotificationState> {
  final WatchNotificationsUseCase _watchUseCase;
  final MarkNotificationReadUseCase _markReadUseCase;
  final SupabaseClient _supabaseClient;
  StreamSubscription? _subscription;

  NotificationCubit({
    required WatchNotificationsUseCase watchUseCase,
    required MarkNotificationReadUseCase markReadUseCase,
    required SupabaseClient supabaseClient,
  })  : _watchUseCase = watchUseCase,
        _markReadUseCase = markReadUseCase,
        _supabaseClient = supabaseClient,
        super(NotificationInitial()) {
    _init();
  }

  void _init() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      emit(NotificationInitial());
      return;
    }
    emit(NotificationLoading());
    
    _subscription?.cancel();
    _subscription = _watchUseCase(userId).listen((result) {
      result.fold(
        (failure) => emit(NotificationError(failure.message)),
        (notifications) => emit(NotificationLoaded(notifications)),
      );
    });
  }

  void refresh() {
    _init();
  }

  Future<void> markAsRead(String id) async {
    await _markReadUseCase(id);
  }

  Future<void> markAllAsRead() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) return;
    await _markReadUseCase.all(userId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
