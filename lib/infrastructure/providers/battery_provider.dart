// This file defines Riverpod providers that supply battery information to the UI.

//in short it Expose the data to the UI and manage app state.
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod StreamProvider that periodically emits the device battery level
final batteryLevelProvider =
    StreamProvider.autoDispose<int>((ref) async* {
  final battery = Battery();
  //check infitly every 2 minutes for battery percentage
  while (true) {
    final level = await battery.batteryLevel;
    yield level;

    await Future.delayed(const Duration(minutes: 2));
  }
});

// Riverpod StreamProvider that listens for battery state changes
final batteryStateProvider =
    StreamProvider.autoDispose<BatteryState>((ref) {
  final battery = Battery();
  return battery.onBatteryStateChanged;
});