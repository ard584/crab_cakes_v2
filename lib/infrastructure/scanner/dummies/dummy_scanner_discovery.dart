

import 'package:ui_prototype/application/scanner/interfaces/scanner_device_discovery.dart';
import 'package:ui_prototype/application/scanner/dtos/discovered_port.dart';


class DummyScannerDiscovery implements ScannerDeviceDiscovery {
  @override
  Future<List<DiscoveredPort>> listDevices() async {

    return [];
  }
}