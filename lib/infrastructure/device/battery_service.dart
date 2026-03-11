//this is the battery service page it holds everything needed with retiriving info from device
//as such i added it into the infastructure layer

//in short it handles communication with the battery plugin.
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  //access battery inofrmation
  final Battery _battery = Battery();

  //return current battery level as percentage
  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  //constently check every 2 minutes
  Stream<int> batteryStream() async* {
    while (true) {
      final level = await _battery.batteryLevel;
      yield level;
      await Future.delayed(const Duration(minutes: 2));
    }
  }
  //lisen for battery state chnge
  Stream<BatteryState> batteryStateStream() {
    return _battery.onBatteryStateChanged;
  }
}