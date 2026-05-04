import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/application/uuid/generate_uuid.dart';
import 'package:crab_cakes/infrastructure/uuid/generate_uuid.dart';


final generateUuidProvider = Provider<GenerateUuid>((ref) {
  return GenerateUuidImpl();
});