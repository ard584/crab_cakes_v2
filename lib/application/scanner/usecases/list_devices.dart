import 'package:crab_cakes/application/scanner/interfaces/scanner_device_discovery.dart';
import 'package:crab_cakes/application/scanner/dtos/discovered_port.dart';

class ListDevices {

  final ScannerDeviceDiscovery discoverer;

  ListDevices(this.discoverer);

  Future<List<DiscoveredPort>> all() async {
    return discoverer.listDevices();
  }

  Future<List<DiscoveredPort>> likely() async {
    final ports = await discoverer.listDevices();

    return ports.where((p)=>p.isBluetooth).toList();
  }
}