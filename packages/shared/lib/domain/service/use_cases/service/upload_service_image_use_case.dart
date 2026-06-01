import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';

class UploadServiceImageUseCase {
  final ServiceRepository repository;

  UploadServiceImageUseCase({required this.repository});

  Future<Either<Failure, String>> call({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? serviceId,
    bool isTemp = false,
  }) {
    return repository.uploadServiceImage(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      serviceId: serviceId,
      isTemp: isTemp,
    );
  }
}
