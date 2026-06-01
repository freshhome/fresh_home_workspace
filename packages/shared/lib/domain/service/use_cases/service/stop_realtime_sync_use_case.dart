import 'package:shared/domain/service/repositories/service_repository.dart';

class StopRealtimeSyncUseCase {
  final ServiceRepository repository;

  StopRealtimeSyncUseCase({required this.repository});

  void call() {
    repository.stopRealtimeSync();
  }
}
