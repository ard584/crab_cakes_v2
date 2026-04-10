//import 'dart:async';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:ui_prototype/application/scanner/interfaces/scanner_connector.dart';
import 'dart:typed_data';

  class LibserialportAdapter implements ScannerConnector {

    SerialPort? _port;
    Stream<Uint8List>? _byteStream;
    
    bool connected = false;

    //stream handoff point (just a getter)
<<<<<<< HEAD
    @override
    Stream<Uint8List> get byteStream => _controller.stream;                       
=======
    Stream<Uint8List>? get byteStream => _byteStream;
>>>>>>> main


    @override
    Future<bool> connect( String portName) async {

      //disconnect to prevent opening an already open port
      await disconnect();

      //attempting connection
      try {
        //set the port
        final port = SerialPort( portName );
        _port = port;

        final goodResult = port.openReadWrite();

        //verify read/write stream opened success
        if(!goodResult) {
          //handle connection failure
          //TODO: LOG / DISPLAY FAILURE

          //clean up port
          port.dispose();
          _port = null;

          return false;
        }

        //set scanner settings (Default for now)
        port.config = (SerialPortConfig()
        ..baudRate = 9600
        ..bits = 8
        ..parity = SerialPortParity.none
        ..stopBits = 1
        ..setFlowControl(SerialPortFlowControl.none));

        connected = true;

        //setting a reader to get access to the byte stream
        final reader = SerialPortReader(port);

        _byteStream = reader.stream;

        //return success
        return true;

      } catch(error) {

        await disconnect();

        //log/display error
        return false;
      }
    }

    @override
    Future<bool> disconnect() async {

      try {
        _byteStream = null;

        final port = _port;
        _port = null;

        if(port != null) {
          if(port.isOpen) {
            port.close();
          }
          port.dispose();
        }

        connected = false;

        return true;

      } catch (error) {
        //log/display error
        connected = false;
        return false;
      }
    }
  }

