import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ui_prototype/application/device_storage/device_storage.dart';

class DeviceStorageImpl implements DeviceStorage {
  FlutterSecureStorage storage = FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) async {
    return await storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) async {
    storage.write(key: key, value: value);
  }
}
