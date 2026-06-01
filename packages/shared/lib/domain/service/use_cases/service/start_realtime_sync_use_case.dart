import 'package:shared/domain/service/repositories/service_repository.dart';

class StartRealtimeSyncUseCase {
  final ServiceRepository repository;

  StartRealtimeSyncUseCase({required this.repository});

  void call() {
    repository.startRealtimeSync();
  }
}
