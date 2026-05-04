import 'package:crab_cakes/application/scanner/interfaces/scanner_connector.dart';


class DisconnectScanner {
  final ScannerConnector connector;

  DisconnectScanner(this.connector);

  Future<bool> execute() async {
    return connector.disconnect();
  }
}