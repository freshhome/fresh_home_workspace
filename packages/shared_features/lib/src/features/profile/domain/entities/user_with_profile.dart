import 'package:shared/domain/user/entities/user/user.dart';
import 'package:shared/domain/user/entities/user/client_profile.dart';
import 'package:shared/domain/user/entities/user/technician_profile.dart';

class UserWithProfile {
  final User user;
  final ClientProfile? clientProfile;
  final TechnicianProfile? technicianProfile;

  UserWithProfile({
    required this.user,
    this.clientProfile,
    this.technicianProfile,
  });
}
