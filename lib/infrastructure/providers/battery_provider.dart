// This file defines Riverpod providers that supply battery information to the UI.

//in short it Expose the data to the UI and manage app state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/services/battery_service.dart';
import 'package:ui_prototype/infrastructure/device/battery_service.dart';
import 'package:ui_prototype/domain/enums/battery_state.dart';

final batteryServiceProvider = Provider<BatteryService>((ref) {
  return BatteryPlusService();
});

// Riverpod StreamProvider that periodically emits the device battery level
final batteryLevelProvider =
    StreamProvider.autoDispose<int>((ref) {

  final service = ref.watch(batteryServiceProvider);
  return service.batteryLevelStream();
});

// Riverpod StreamProvider that listens for battery state changes
final batteryStateProvider =
    StreamProvider.autoDispose<BatteryState>((ref) {
  final service = ref.watch(batteryServiceProvider);
  return service.batteryStateStream();
});