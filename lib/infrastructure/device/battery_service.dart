//this is the battery service page it holds everything needed with retiriving info from device
//as such i added it into the infastructure layer

//in short it handles communication with the battery plugin.
import 'dart:async';
import 'package:battery_plus/battery_plus.dart' as bp;
import 'package:ui_prototype/application/services/battery_service.dart';
import 'package:ui_prototype/domain/enums/battery_state.dart';

class BatteryPlusService implements BatteryService {
  //access battery information
  final bp.Battery _battery = bp.Battery();

  //return current battery level as percentage
  @override
  Future<int> getBatteryLevel()  {
    return _battery.batteryLevel;
  }

  //update battery percentage immediately then check every 2 minutes
  @override
  Stream<int> batteryLevelStream() async* {
    yield await _battery.batteryLevel;

    yield* Stream.periodic(const Duration(minutes: 2))
        .asyncMap((_) => _battery.batteryLevel);
  }
  //listen for battery state chnge
  @override
  Stream<BatteryState> batteryStateStream() {
    return _battery.onBatteryStateChanged.map(_mapState);
  }
  
  BatteryState _mapState(bp.BatteryState state) {
    switch (state) {
      case bp.BatteryState.charging:
        return BatteryState.charging;
      case bp.BatteryState.discharging:
        return BatteryState.discharging;
      case bp.BatteryState.full:
        return BatteryState.full;
      default:
        return BatteryState.unknown;
    }
  }
  

}