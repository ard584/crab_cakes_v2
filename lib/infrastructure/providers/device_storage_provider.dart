import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/application/device_storage/device_storage.dart';
import 'package:crab_cakes/infrastructure/device_storage/device_storage_impl.dart';

final deviceStorageProvider = Provider<DeviceStorage>((ref) {
  return DeviceStorageImpl();
});