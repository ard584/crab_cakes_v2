import 'fakes/fake_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'package:ui_prototype/presentation/services/device_uuid_helper.dart';

void main() {
  test('getOrCreateDeviceID generates and persists a device ID', () async {

    // Step 1: Create a fake storage
    final fakeStorage = FakeSecureStorage();

    // Step 2: Create a predictable Uuid generator
    int calls = 0;
    Uint8List fakeUuid() {
      calls++;
      return Uint8List.fromList(List.generate(16, (i) => i));
    }

    // Step 3: First call should generate a new UUID
    final first = await getOrCreateDeviceID(uuidGen: fakeUuid, storage: fakeStorage);

    // Check the UUID has the right length
    expect(first.length, 16);

    // Check that the UUID generator was called
    expect(calls, 1);

    // Step 4: Second call should reuse stored UUID
    final second = await getOrCreateDeviceID(uuidGen: fakeUuid, storage: fakeStorage);

    // Check it’s exactly the same
    expect(second, equals(first));

    // Generator should not have been called again
    expect(calls, 1);

  });

  test('Writing a null value erases that value from the storage', () async {

    // Create a fake storage
    final storage = FakeSecureStorage();

    // Write a real value
    storage.write(key: 'device_id', value: 'test_value');

    // Read it to check it's there
    expect(await storage.read(key: 'device_id'), 'test_value');

    // Write a null value
    storage.write(key: 'device_id', value: null);

    // Read it to check it's gone
    expect(await storage.read(key: 'device_id'), isNull);
  });
}