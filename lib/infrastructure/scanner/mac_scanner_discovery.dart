import 'dart:io';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'package:crab_cakes/application/scanner/interfaces/scanner_device_discovery.dart';
import 'package:crab_cakes/application/scanner/dtos/discovered_port.dart';

class MacScannerDiscovery implements ScannerDeviceDiscovery {
  @override
  Future<List<DiscoveredPort>> listDevices() async {
    if (!Platform.isMacOS) {
      return [];
    }

    // Find Biomark HPR serial ports on Mac.
    final ports = SerialPort.availablePorts;

    final devices = <DiscoveredPort>[];

    for (final port in ports) {
      if (port.startsWith('/dev/cu.') && port.toUpperCase().contains('HPR')) {
        devices.add(
          DiscoveredPort(
            port.split('/').last.replaceFirst('cu.', ''),
            port,
            'Biomark HPR Bluetooth Scanner',
            true,
          ),
        );
      }
    }

    return devices;
  }
}
