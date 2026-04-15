import 'package:ui_prototype/application/device_storage/device_storage.dart';
import 'package:ui_prototype/application/uuid/generate_uuid.dart';
import 'dart:typed_data';

class DeviceIDUseCase {
  static const _deviceIdKey = 'device_id';

  // Make this a method in an interface class
  Future<Uint8List> getOrCreateDeviceID({
    required GenerateUuid uuidGen,
    required DeviceStorage storage,
  }) async {
    // Read stored device ID
    final stored = await storage.read(key: _deviceIdKey);

    // Check if device ID already exists
    if (stored != null) {
      // If it does, convert the string into a Uint8List (for blob storage in SQLite)
      return Uint8List.fromList(stored.codeUnits);
    }

    // Otherwise, generate a new Uuid from the passed-in function
    final id = uuidGen.generate();

    // Write to secure storage
    await storage.write(key: _deviceIdKey, value: String.fromCharCodes(id));

    // Return the ID
    return id;
  }
}
