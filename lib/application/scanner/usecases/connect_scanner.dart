
//REMINDER: App Layer code SHOULD NOT depend on the layers above it
//          In this case, we use an interface to connect to the scanner because
//          this app-layer use case does not have access to infrastructure

//Including APP LAYER interface
import 'package:crab_cakes/application/scanner/interfaces/scanner_connector.dart';


class ConnectScanner {
  final ScannerConnector connector;

  ConnectScanner(this.connector);

  Future<bool> execute(String device) async {
    return connector.connect(device);
  }
}