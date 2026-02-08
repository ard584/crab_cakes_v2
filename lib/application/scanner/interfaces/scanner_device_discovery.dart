import 'package:ui_prototype/application/scanner/dtos/discovered_port.dart';

abstract class ScannerDeviceDiscovery {
  
  Future<List<DiscoveredPort>> listDevices();

}