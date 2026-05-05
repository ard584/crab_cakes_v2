import 'package:crab_cakes/domain/enums/app_sound.dart';

//an abstract class for playing the sounds
abstract class SoundService 
{
  Future<void> play(AppSound sound);
  Future<void> preview(AppSound sound);
}