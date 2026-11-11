import 'dart:typed_data';

abstract class ScannerConnector {

  final Stream<Uint8List> _byteStream = const Stream.empty();
  Stream<Uint8List> get byteStream => _byteStream;

  Stream<bool> get connectionStatusStream;
  bool get isConnected;

  //connect method
  Future<bool> connect( String portName );

  //disconnect method
  Future<bool> disconnect(); 

  //State?
}