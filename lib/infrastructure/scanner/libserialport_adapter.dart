//import 'dart:async';
import 'dart:async';

import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:ui_prototype/application/scanner/interfaces/scanner_connector.dart';
import 'dart:typed_data';

  class LibserialportAdapter implements ScannerConnector {

    SerialPort? _port;
    SerialPortReader? _reader;
    StreamSubscription<Uint8List>? _readerSub;
    
    final StreamController<Uint8List> _controller = 
      StreamController<Uint8List>.broadcast();
    
    bool connected = false; 

    //stream handoff point (just a getter)
    @override
    Stream<Uint8List> get byteStream => _controller.stream;                       


    @override
    Future<bool> connect( String portName) async {

      //disconnect to prevent opening an already open port
      await disconnect();

      //attempting connection
      try {
        //set the port
        final port = SerialPort( portName );
        _port = port;

        final opened = port.openReadWrite();

        //verify read/write stream opened success
        if(!opened || !port.isOpen) {
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

        //Test and validate the scanner connection
        final validScanner = await _validateConnection(port);

        //handle invalid scanner (port opened but no communication established)
        if(!validScanner) {
          port.close();
          port.dispose();

          _port = null;

          return false;
        } 

        connected = true;

        //setting a reader to get access to the byte stream
        final reader = SerialPortReader(port);
        _reader = reader;

        //setting up the subscription which feeds the stream controller
        _readerSub = reader.stream.listen(
          (data) {
            _controller.add(data);
          },
          onError: (error, stackTrace) {
            _controller.addError(error, stackTrace);
          },
        );
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
        await _readerSub?.cancel();
        _readerSub = null;

        _reader?.close();
        _reader = null;

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

    //helper function to verify that the scanner is actually communicating with 
    //the computer
    Future<bool> _validateConnection(SerialPort port) async {
      SerialPortReader? reader;
      StreamSubscription<Uint8List>? sub;

      final completer = Completer<String>();
      final buffer = StringBuffer();

      try {
        reader = SerialPortReader(port);

        sub = reader.stream.listen(
          (data) {
            // Convert incoming bytes into text.
            buffer.write(String.fromCharCodes(data));

            // Check whether we have received a complete line yet.
            final lines = buffer.toString().split(RegExp(r'\r\n|\n|\r'));

            for (final line in lines) {
              final trimmed = line.trim();

              // RID should respond with something like "01".
              final isReaderId = RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(trimmed);

              if (isReaderId && !completer.isCompleted) {
                completer.complete(trimmed);
                return;
              }
            }
          },
          onError: (error, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
        );

        // Ask scanner to report its reader ID.
        port.write(Uint8List.fromList('RID\r\n'.codeUnits));

        // Wait for the stream listener above to complete the Future.
        final response = await completer.future.timeout(
          const Duration(seconds: 2),
        );

        return RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(response.trim());
      } catch (_) {
        return false;
      } finally {
        await sub?.cancel();
        reader?.close();
      }
    }
  }

