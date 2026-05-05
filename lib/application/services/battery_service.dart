import 'package:crab_cakes/domain/enums/battery_state.dart';

abstract class BatteryService {
  Future<int> getBatteryLevel();

  Stream<int> batteryLevelStream();

  Stream<BatteryState> batteryStateStream();
}