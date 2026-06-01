import 'package:shared/domain/user/entities/user/technician_profile.dart';
import 'package:shared/data/user/models/local/technician_profile_hive_model.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';

class TechnicianProfileMapper {
  TechnicianProfileMapper._();

  static TechnicianProfileRemoteModel toModel(TechnicianProfile entity) {
    return TechnicianProfileRemoteModel.fromEntity(entity);
  }

  static TechnicianProfileHiveModel toHive(TechnicianProfile entity) {
    return TechnicianProfileHiveModel.fromEntity(entity);
  }

  static TechnicianProfile fromRemote(TechnicianProfileRemoteModel model) {
    return TechnicianProfile(
      userId: model.userId,
      bio: model.bio,
      rating: model.rating,
      completedJobs: model.completedJobs,
      isVerified: model.isVerified,
      isAvailable: model.isAvailable,
      serviceArea: model.serviceArea,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static TechnicianProfile fromHive(TechnicianProfileHiveModel model) {
    return TechnicianProfile(
      userId: model.userId,
      bio: model.bio,
      rating: model.rating,
      completedJobs: model.completedJobs,
      isVerified: model.isVerified,
      isAvailable: model.isAvailable,
      serviceArea: model.serviceArea,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
