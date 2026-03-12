import 'package:ui_prototype/domain/enums/battery_state.dart';

abstract class BatteryService {
  Future<int> getBatteryLevel();

  Stream<int> batteryLevelStream();

  Stream<BatteryState> batteryStateStream();
}