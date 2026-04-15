import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/device_storage/device_id_use_case.dart';

final deviceIDUseCaseProvider = Provider<DeviceIDUseCase>((ref) {
  return DeviceIDUseCase();
});