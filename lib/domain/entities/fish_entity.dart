import 'package:ui_prototype/domain/value_objects/fish_identifier.dart';
import 'package:ui_prototype/domain/value_objects/species.dart';


/*
* Implementation Notes:
* FishEntity is one of the major entities in the app
* It represents a fish that MAY OR MAY NOT be in the database
* CatchEntities represent fish that ARE in the database
*/
class FishEntity{

  final String fishId;
  FishIdentifier identifier;

  Species? species;
  String? sex;

  FishEntity({ required this.fishId, required this.identifier, this.species, this.sex});
}