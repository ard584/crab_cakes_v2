import 'package:ui_prototype/domain/enums/app_sound.dart';
//abstract class for loading and saving sound settings
//separates business and storage logic
abstract class SoundSettingsRepository 
{
  Future<Map<AppSound, bool>> loadSettings();
  Future<void> setEnabled(AppSound sound, bool enabled);
}