import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/core/constants/hive_constants.dart';

abstract class OnboardingLocalDataSource {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  static const String _onboardingKey = 'is_onboarding_completed';

  @override
  Future<bool> isOnboardingCompleted() async {
    final box = Hive.box(HiveBoxNames.settingsBox);
    return box.get(_onboardingKey, defaultValue: false) as bool;
  }

  @override
  Future<void> setOnboardingCompleted() async {
    final box = Hive.box(HiveBoxNames.settingsBox);
    await box.put(_onboardingKey, true);
  }
}
