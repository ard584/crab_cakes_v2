import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:ui_prototype/application/services/sound_service.dart';
import 'package:ui_prototype/domain/enums/app_sound.dart';
import 'package:ui_prototype/infrastructure/providers/sound_provider.dart';
import 'package:ui_prototype/infrastructure/sound/sound_mapper.dart';

//class that is used to play the applications sounds
//the rest of the app does not need to know how sounds are played 
//so its clean
class AudioPlayerService implements SoundService {
  AudioPlayerService(this.ref);

  final Ref ref;
  final SoLoud _soloud = SoLoud.instance;
  final Map<AppSound, AudioSource> _loadedSources = {};
  bool _isInitialized = false;

  //audio engine is only initialized once
  Future<void> _ensureInitialized() async 
    {
    if (_isInitialized) return;
    await _soloud.init();
    _isInitialized = true;
  }
  Future<AudioSource> _getSource(AppSound sound) async {
    final existing = _loadedSources[sound];
    if (existing != null) return existing;

    final assetPath = mapSoundToAsset(sound);
    final source = await _soloud.loadAsset('assets/$assetPath');
    _loadedSources[sound] = source;
    return source;
  }

  @override
  Future<void> play(AppSound sound) async 
  {
    //make sure sound is enabled(on) in settings for it to work
    final enabled = ref.read(soundEnabledProvider(sound));
    if (!enabled) return;

    await _playSound(sound);
  }

  //can preview sounds without worrying about it being off and on
  @override
  Future<void> preview(AppSound sound) async 
  {
    await _playSound(sound);
  }

  //internal helper to load sound files and plays them
  Future<void> _playSound(AppSound sound) async 
  {
    try {
      await _ensureInitialized();
      final source = await _getSource(sound);
      await _soloud.play(source);
    } 
    catch (_) 
    {
      //TODO: Implement Error Handling
    }
  }
}