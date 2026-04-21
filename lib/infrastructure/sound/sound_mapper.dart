import 'package:ui_prototype/domain/enums/app_sound.dart';

//converts the AppSound enum values into the correct file paths
const Map<AppSound, String> kSoundAssetPaths = {
  AppSound.readerDiscovered: 'sounds/reader_discovered.wav',
  AppSound.tagAccepted: 'sounds/tag_accepted.wav',
  AppSound.tagHistoryFound: 'sounds/tag_history_found.wav',
  AppSound.tagHistoryDiff: 'sounds/tag_history_diff.wav',
  AppSound.tagIgnored: 'sounds/tag_ignored.wav',
  AppSound.tagDuplicate: 'sounds/tag_duplicate.wav',
  AppSound.recordSavedOk: 'sounds/record_saved_ok.wav',
  AppSound.recordSaveFailed: 'sounds/record_save_failed.wav',
};

String mapSoundToAsset(AppSound sound) {
  return kSoundAssetPaths[sound]!;
}