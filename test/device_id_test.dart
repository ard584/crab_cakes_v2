import 'package:ui_prototype/infrastructure/uuid/generate_uuid.dart';

import 'fakes/fake_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_prototype/application/device_storage/device_id_use_case.dart';

void main() {

  final useCase = DeviceIDUseCase();
  final uuidFunc = GenerateUuidImpl();
  test('getOrCreateDeviceID generates and persists a device ID', () async {

    final fakeStorage = FakeSecureStorage();

    // Step 3: First call should generate a new UUID
    final first = await useCase.getOrCreateDeviceID(uuidGen: uuidFunc, storage: fakeStorage);

    // Check the UUID has the right length
    expect(first.length, 16);

    // Step 4: Second call should reuse stored UUID
    final second = await useCase.getOrCreateDeviceID(uuidGen: uuidFunc, storage: fakeStorage);

    // Check it’s exactly the same
    expect(second, equals(first));

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