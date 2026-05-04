import 'package:crab_cakes/domain/value_objects/scanner_id.dart';
import 'package:crab_cakes/domain/value_objects/scanner_transport.dart';

// MVP for the app will assume that scanner devices will ALWAYS communicate through
// serial via COM ports. Because of this, 'transport' only refers to serial methods
// of communication, and 'port' refers to the specific COM port number in the format
// COM# (i.e. COM7)


class ScannerDevice {
  final ScannerId id;
  final String displayName;
  final Transport transport;
  final String port;

  const ScannerDevice({
    required this.id, 
    required this.displayName,
    required this.transport,
    required this.port});

}