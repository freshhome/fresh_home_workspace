import 'package:hive/hive.dart';

/// Local data source for managing locale preferences using Hive
abstract class LocaleLocalDataSource {
  /// Get the saved locale code from Hive
  Future<String?> getSavedLocaleCode();
  
  /// Save the locale code to Hive
  Future<void> saveLocaleCode(String localeCode);
}

class LocaleLocalDataSourceImpl implements LocaleLocalDataSource {
  static const String _localeBoxName = 'locale_box';
  static const String _localeCodeKey = 'locale_code';

  /// Get or open the locale box
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_localeBoxName)) {
      return await Hive.openBox(_localeBoxName);
    }
    return Hive.box(_localeBoxName);
  }

  @override
  Future<String?> getSavedLocaleCode() async {
    try {
      final box = await _getBox();
      return box.get(_localeCodeKey) as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveLocaleCode(String localeCode) async {
    try {
      final box = await _getBox();
      await box.put(_localeCodeKey, localeCode);
    } catch (e) {
      rethrow;
    }
  }
}
