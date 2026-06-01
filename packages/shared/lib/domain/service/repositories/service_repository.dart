import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import 'package:shared/domain/service/entities/service.dart'; // Keep for ServiceAvailability and TimeSlot
import '../../technician/entities/technician.dart';
import '../entities/sub_entities/shared_icon_entity.dart';

abstract class ServiceRepository {
  // Legacy / Backward Compatibility Queries
  Stream<Either<Failure, List<MainServiceEntity>>> getMainServices();
  Future<Either<Failure, MainServiceEntity>> getMainServiceById(String id);
  Future<Either<Failure, MainServiceEntity>> addMainService(MainServiceEntity service);
  Future<Either<Failure, MainServiceEntity>> updateMainService(MainServiceEntity service);
  Future<Either<Failure, Unit>> deleteMainService(String id, {required MainServiceEntity mainService});
  Future<Either<Failure, List<SubServiceEntity>>> getSubServices(String mainServiceId);
  Future<Either<Failure, SubServiceEntity>> getSubServiceById(String id, {required bool forceRemote, required String mainServiceId, required String subServiceId});
  Future<Either<Failure, SubServiceEntity>> addSubService(SubServiceEntity subService, String mainServiceId);
  Future<Either<Failure, SubServiceEntity>> updateSubService(SubServiceEntity service);
  Future<Either<Failure, Unit>> deleteSubService(String id);
  Future<Either<Failure, List<MainServiceEntity>>> searchServices(String query);

  // Service Queries (Unified Tree)
  Future<Either<Failure, List<ServiceEntity>>> getRootServices({bool forceRefresh = false});
  Future<Either<Failure, List<ServiceEntity>>> getChildren(String parentId, {bool forceRefresh = false});
  Future<Either<Failure, List<ServiceEntity>>> getBookableServices({bool forceRefresh = false});
  Future<Either<Failure, ServiceEntity>> getServiceById(String id, {bool forceRefresh = false});

  // Mutator / Write Operations (Insert / Update)
  Future<Either<Failure, ServiceEntity>> addService(ServiceEntity service);
  Future<Either<Failure, ServiceEntity>> updateService(ServiceEntity service);

  // Sync & Realtime
  Future<Either<Failure, bool>> syncAllServices({bool forceFull = false});
  Future<Either<Failure, Unit>> startRealtimeSync();
  Future<Either<Failure, Unit>> stopRealtimeSync();

  // Availability & Technicians
  Future<Either<Failure, List<ServiceAvailability>>> getAvailability(String subServiceId);
  Future<Either<Failure, List<Technician>>> getTechnicians();
  Future<Either<Failure, List<Technician>>> getTechniciansForService(String subServiceId);

  // Pricing
  Future<Either<Failure, double>> calculatePrice({
    required String subServiceId,
    required Map<String, dynamic> formValues,
    required List<String> selectedOptions,
  });

  // Storage
  Future<Either<Failure, String>> uploadServiceImage({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? serviceId,
    bool isTemp = false,
  });
  Future<Either<Failure, void>> deleteServiceImage(String imageUrl);

  // Shared Icon Library
  Future<Either<Failure, List<SharedIconEntity>>> getSharedIcons();
  Future<Either<Failure, SharedIconEntity>> insertSharedIcon(SharedIconEntity icon);
  Future<Either<Failure, void>> deleteSharedIcon(String id);
}
