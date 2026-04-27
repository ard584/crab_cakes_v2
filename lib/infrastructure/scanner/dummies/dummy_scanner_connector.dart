import 'package:ui_prototype/application/scanner/interfaces/scanner_connector.dart';
import 'dart:typed_data';


class DummyScannerConnector implements ScannerConnector {

  @override
  Stream<Uint8List> get byteStream => Stream.empty();  
  
  @override
  Future<bool> connect( String portName) async {
    throw UnsupportedError('Scanner is only supported on Windows right now.');
  }

  @override
  Future<bool> disconnect() async {
    return true;
  }

}