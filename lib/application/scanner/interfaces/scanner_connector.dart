import 'dart:typed_data';

abstract class ScannerConnector {

  Stream<Uint8List> _byteStream = const Stream.empty();
  Stream<Uint8List> get byteStream => _byteStream;

  //connect method
  Future<bool> connect( String portName );

  //disconnect method
  Future<bool> disconnect(); 

  //State?
}