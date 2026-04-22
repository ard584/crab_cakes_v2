import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/services/sound_service.dart';
import 'package:ui_prototype/domain/enums/app_sound.dart';
import 'package:ui_prototype/infrastructure/sound/audio_player_service.dart';


// Default behavior: if a sound has no stored setting,
// it is treated as enabled.
const bool kDefaultSoundEnabled = true;

//notifier to store whether app sound is on or off
class SoundSettingsNotifier extends Notifier<Map<AppSound, bool>> {
  @override
  //default is on (enabled)
  Map<AppSound, bool> build() 
  {
    return {for (final sound in AppSound.values) sound: true,};
  }

  //update for one sound
  void setEnabled(AppSound sound, bool enabled) 
  {
    state = {...state,sound: enabled,
    };
  }

  //turn all sounds on/off
  void setAllEnabled(bool enabled)
  {
    state = {for(final sound in AppSound.values) sound:enabled};
  }

  //return whether sound is enabled or not
  bool isEnabled(AppSound sound) 
  {
    return state[sound] ?? kDefaultSoundEnabled;
  }
}

//provider that shows the notifier the full sound settings map
final soundSettingsProvider =NotifierProvider<SoundSettingsNotifier, Map<AppSound, bool>>(SoundSettingsNotifier.new,);

//provider that is used to get the enabled state of a sound (one)
final soundEnabledProvider = Provider.family<bool, AppSound>((ref, sound) 
{
  final settings = ref.watch(soundSettingsProvider);
  return settings[sound] ?? kDefaultSoundEnabled;
});

//provider that checks if all the sounds are enabled
final allSoundsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(soundSettingsProvider);
  return AppSound.values.every((sound) => settings[sound] ?? kDefaultSoundEnabled);
});

//provider that gives access to the sound service
final soundServiceProvider = Provider<SoundService>((ref) 
{
  return AudioPlayerService(ref);
});