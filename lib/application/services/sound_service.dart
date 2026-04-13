import 'package:ui_prototype/domain/enums/app_sound.dart';

//an abstract class fo playing the sounds
abstract class SoundService 
{
  Future<void> play(AppSound sound);
  Future<void> preview(AppSound sound);
}