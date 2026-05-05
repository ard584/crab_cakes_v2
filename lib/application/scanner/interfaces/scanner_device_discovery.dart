import 'package:crab_cakes/application/scanner/dtos/discovered_port.dart';

abstract class ScannerDeviceDiscovery {
  
  Future<List<DiscoveredPort>> listDevices();

}