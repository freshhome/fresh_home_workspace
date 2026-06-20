import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/whatsapp_settings_repository.dart';

abstract class WhatsAppSettingsState {}

class WhatsAppSettingsInitial extends WhatsAppSettingsState {}

class WhatsAppSettingsLoading extends WhatsAppSettingsState {}

class WhatsAppSettingsLoaded extends WhatsAppSettingsState {
  final Map<String, dynamic> settings;
  WhatsAppSettingsLoaded(this.settings);
}

class WhatsAppSettingsError extends WhatsAppSettingsState {
  final String message;
  WhatsAppSettingsError(this.message);
}

class WhatsAppSettingsSaving extends WhatsAppSettingsState {
  final Map<String, dynamic> settings;
  WhatsAppSettingsSaving(this.settings);
}

class WhatsAppSettingsSaveSuccess extends WhatsAppSettingsState {}

class WhatsAppSettingsCubit extends Cubit<WhatsAppSettingsState> {
  final WhatsAppSettingsRepository _repository;

  WhatsAppSettingsCubit({required WhatsAppSettingsRepository repository})
      : _repository = repository,
        super(WhatsAppSettingsInitial());

  Future<void> loadSettings() async {
    emit(WhatsAppSettingsLoading());
    try {
      final settings = await _repository.getWhatsAppSettings();
      emit(WhatsAppSettingsLoaded(settings));
    } catch (e) {
      emit(WhatsAppSettingsError(e.toString()));
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final currentSettings = state is WhatsAppSettingsLoaded
        ? (state as WhatsAppSettingsLoaded).settings
        : <String, dynamic>{};
        
    emit(WhatsAppSettingsSaving(currentSettings));
    try {
      await _repository.saveWhatsAppSettings(settings);
      emit(WhatsAppSettingsSaveSuccess());
      emit(WhatsAppSettingsLoaded(settings));
    } catch (e) {
      emit(WhatsAppSettingsError(e.toString()));
      emit(WhatsAppSettingsLoaded(currentSettings));
    }
  }
}
