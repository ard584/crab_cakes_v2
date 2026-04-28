import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/uuid/generate_uuid.dart';
import 'package:ui_prototype/infrastructure/uuid/generate_uuid.dart';


final generateUuidProvider = Provider<GenerateUuid>((ref) {
  return GenerateUuidImpl();
});