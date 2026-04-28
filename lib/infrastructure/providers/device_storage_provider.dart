import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/device_storage/device_storage.dart';
import 'package:ui_prototype/infrastructure/device_storage/device_storage_impl.dart';

final deviceStorageProvider = Provider<DeviceStorage>((ref) {
  return DeviceStorageImpl();
});