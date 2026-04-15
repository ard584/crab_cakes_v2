abstract class DeviceStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
}