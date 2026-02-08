abstract class ScannerConnector {

  //connect method
  Future<bool> connect( String portName );

  //disconnect method
  Future<bool> disconnect(); 

  //State?
}