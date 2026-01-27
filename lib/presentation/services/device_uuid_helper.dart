import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'uuid_helpers.dart';
import 'dart:typed_data';

const _deviceIdKey = 'device_id';
const FlutterSecureStorage _storage = FlutterSecureStorage();
const Uint8List Function() _uuidGen = newUuidV4;

Future<Uint8List> getOrCreateDeviceID({ 
  Uint8List Function() uuidGen = _uuidGen,
  FlutterSecureStorage storage = _storage
  }) async {

  // Read stored device ID
  final stored = await storage.read(key: _deviceIdKey);

  // Check if device ID already exists
  if (stored != null) {

    // If it does, convert the string into a Uint8List (for blob storage in SQLite)
    return Uint8List.fromList(stored.codeUnits);
  }

  // Otherwise, generate a new Uuid from the passed-in function
  final id = uuidGen();

  // Write to secure storage
  await storage.write(key: _deviceIdKey, value: String.fromCharCodes(id));

  // Return the ID
  return id;
}