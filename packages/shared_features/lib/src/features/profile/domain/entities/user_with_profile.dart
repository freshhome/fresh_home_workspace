import 'package:shared/domain/user/entities/user/user.dart';
import 'package:shared/domain/user/entities/user/client_profile.dart';
import 'package:shared/domain/user/entities/user/technician_profile.dart';
import 'package:shared/domain/user/entities/user/capacity_pool.dart';
import 'package:shared/domain/user/entities/user/technician_skill.dart';

class UserWithProfile {
  final User user;
  final ClientProfile? clientProfile;
  final TechnicianProfile? technicianProfile;
  final List<CapacityPool>? capacityPools;
  final List<TechnicianSkill>? technicianSkills;
  final Map<String, String>? subServiceNames;

  UserWithProfile({
    required this.user,
    this.clientProfile,
    this.technicianProfile,
    this.capacityPools,
    this.technicianSkills,
    this.subServiceNames,
  });
}
