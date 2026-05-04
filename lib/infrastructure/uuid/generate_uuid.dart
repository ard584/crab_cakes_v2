
import 'dart:typed_data';

import 'package:crab_cakes/application/uuid/generate_uuid.dart';
import 'package:uuid/uuid.dart';

class GenerateUuidImpl implements GenerateUuid {
  @override
  Uint8List generate() {
    return UuidValue.fromString(Uuid().v4()).toBytes();
  }
  
}