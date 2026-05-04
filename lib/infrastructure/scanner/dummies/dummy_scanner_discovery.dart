

import 'package:crab_cakes/application/scanner/interfaces/scanner_device_discovery.dart';
import 'package:crab_cakes/application/scanner/dtos/discovered_port.dart';


class DummyScannerDiscovery implements ScannerDeviceDiscovery {
  @override
  Future<List<DiscoveredPort>> listDevices() async {

    return [];
  }
}