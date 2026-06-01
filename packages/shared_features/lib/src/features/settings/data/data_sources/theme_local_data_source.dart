import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';

abstract class ThemeLocalDataSource {
  Future<bool> getIsDark();
  Future<void> setIsDark(bool value);
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  static const String _isDarkKey = 'isDark';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(HiveBoxNames.settingsBox)) {
      return await Hive.openBox(HiveBoxNames.settingsBox);
    }
    return Hive.box(HiveBoxNames.settingsBox);
  }

  @override
  Future<bool> getIsDark() async {
    final box = await _getBox();
    return box.get(_isDarkKey, defaultValue: false) as bool;
  }

  @override
  Future<void> setIsDark(bool value) async {
    final box = await _getBox();
    await box.put(_isDarkKey, value);
  }
}
