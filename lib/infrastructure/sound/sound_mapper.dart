import 'package:ui_prototype/domain/enums/app_sound.dart';

//converts the AppSound enum values into the correct file paths
String mapSoundToAsset(AppSound sound) 
{
  switch (sound) 
  {
    case AppSound.readerDiscovered:
      return 'sounds/reader_discovered.wav';
    case AppSound.tagAccepted:
      return 'sounds/tag_accepted.wav';
    case AppSound.tagHistoryFound:
      return 'sounds/tag_history_found.wav';
    case AppSound.tagHistoryDiff:
      return 'sounds/tag_history_diff.wav';
    case AppSound.tagIgnored:
      return 'sounds/tag_ignored.wav';
    case AppSound.tagDuplicate:
      return 'sounds/tag_duplicate.wav';
    case AppSound.recordSavedOk:
      return 'sounds/record_saved_ok.wav';
    case AppSound.recordSaveFailed:
      return 'sounds/record_save_failed.wav';
  }
}