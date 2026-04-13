import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/services/sound_service.dart';
import 'package:ui_prototype/domain/enums/app_sound.dart';
import 'package:ui_prototype/infrastructure/sound/audio_player_service.dart';

//notifier to store wheather app sound is on or off
class SoundSettingsNotifier extends Notifier<Map<AppSound, bool>> {
  @override
  //default is on (enabled)
  Map<AppSound, bool> build() 
  {
    return {
      for (final sound in AppSound.values) sound: true,
    };
  }

  //update for one sound
  void setEnabled(AppSound sound, bool enabled) 
  {
    state = {
      ...state,
      sound: enabled,
    };
  }

  //return whether sound is enabled or not
  bool isEnabled(AppSound sound) 
  {
    return state[sound] ?? true;
  }
}

//provider that shows the notifier the full sound settings map
final soundSettingsProvider =NotifierProvider<SoundSettingsNotifier, Map<AppSound, bool>>(SoundSettingsNotifier.new,);

//provider that is used to get the enabled state of a sound
final soundEnabledProvider = Provider.family<bool, AppSound>((ref, sound) 
{
  final settings = ref.watch(soundSettingsProvider);
  return settings[sound] ?? true;
});

//provider that gives access to the sound service
final soundServiceProvider = Provider<SoundService>((ref) 
{
  return AudioPlayerService(ref);
});