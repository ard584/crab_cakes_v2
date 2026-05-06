//import 'dart:async';
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:crab_cakes/application/scanner/interfaces/scanner_connector.dart';
import 'dart:typed_data';

  class LibserialportAdapter implements ScannerConnector {

    static const bool _debugScannerLogs = true;

    SerialPort? _port;
    SerialPortReader? _reader;
    StreamSubscription<Uint8List>? _readerSub;
    
    final StreamController<Uint8List> _controller = 
      StreamController<Uint8List>.broadcast();
    
    bool connected = false; 

    final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

    void _log(String message) {
      if (!kDebugMode || !_debugScannerLogs) return;

      debugPrint('[PIT SCANNER] ${DateTime.now().toIso8601String()} | $message');
    }

    String _formatBytes(Uint8List data) {
      final hex = data
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');

      final text = String.fromCharCodes(data)
        .replaceAll('\r', r'\r')
        .replaceAll('\n', r'\n');

      return 'len=${data.length}, hex=[$hex], text="$text"';
    }

    @override
    Stream<bool> get connectionStatusStream => _statusController.stream;

    @override
    bool get isConnected => connected;

    //stream handoff point (just a getter)
    @override
    Stream<Uint8List> get byteStream => _controller.stream;                       


    @override
    Future<bool> connect( String portName) async {

      _log('connect() requested for portName=$portName');

      //disconnect to prevent opening an already open port
      _log('connect() calling disconnect() before opening new port');
      await disconnect();

      //attempting connection
      try {
        //set the port
        _log('Creating SerialPort($portName)');
        final port = SerialPort( portName );
        _port = port;

        _log('Attempting openReadWrite() for $portName');
        final opened = await _openPortWithRetries(port, portName);

        _log('openReadWrite result for $portName: opened=$opened, isOpen=${port.isOpen}');

        //verify read/write stream opened success
        if(!opened || !port.isOpen) {
          //handle connection failure
          //TODO: LOG / DISPLAY FAILURE
          _log('FAILED TO OPEN port=$portName. opened=$opened, isOpen=${port.isOpen}');

          //clean up port
          _log('Disposing unopened/failed port=$portName');
          port.dispose();
          _port = null;

          return false;
        }

        //set scanner settings (Default for now)
        _log('Applying serial config to $portName: baud=9600, bits=8, parity=none, stopBits=1, flowControl=none');
        port.config = (SerialPortConfig()
        ..baudRate = 9600
        ..bits = 8
        ..parity = SerialPortParity.none
        ..stopBits = 1
        ..setFlowControl(SerialPortFlowControl.none));

        _log('Serial config applied to $portName');

        //setting a reader to get access to the byte stream
        _log('Creating SerialPortReader for $portName');
        final reader = SerialPortReader(port);
        _reader = reader;

        //setting up the subscription which feeds the stream controller
        _log('Starting reader stream subscription for $portName');
        _readerSub = reader.stream.listen(
          (data) {
            _log('reader.stream data received from $portName: ${_formatBytes(data)}');
            _controller.add(data);
          },
          onError: (error, stackTrace) async {
            _log('reader.stream ERROR on $portName: $error');
            _controller.addError(error, stackTrace);
            await disconnect();
          },
          onDone: () async {
            _log('reader.stream DONE on $portName');
            await disconnect();
          },
        );

        // Optional: give Bluetooth serial a tiny moment to settle after opening.
        _log('Waiting 150ms for Bluetooth serial settle time before validation');
        await Future.delayed(const Duration(milliseconds: 150));

        //Test and validate the scanner connection
        _log('Starting scanner validation for $portName');
        final validScanner = await _validateConnection(port);
        _log('Scanner validation result for $portName: validScanner=$validScanner');

        //handle invalid scanner (port opened but no communication established)
        if(!validScanner) {
          _log('Validation failed for $portName. Disconnecting through normal cleanup path.');
          await disconnect();
          return false;
        }

        connected = true;
        _statusController.add(true);
        _log('Connection established successfully for $portName. connected=$connected');

        //return success
        return true;

      } catch(error, stackTrace) {

        _log('connect() caught error for portName=$portName: $error');
        _log('connect() stackTrace: $stackTrace');

        await disconnect();

        //log/display error
        return false;
      }
    }

    @override
    Future<bool> disconnect() async {

      _log('disconnect() requested. connected=$connected, hasPort=${_port != null}, hasReader=${_reader != null}, hasSub=${_readerSub != null}');

      try {
        _log('Cancelling reader subscription');
        await _readerSub?.cancel();
        _readerSub = null;
        _log('Reader subscription cancelled');

        _log('Closing reader');
        _reader?.close();
        _reader = null;
        _log('Reader closed');

        final port = _port;
        _port = null;

        if(port != null) {
          _log('Cleaning up port. isOpen=${port.isOpen}');

          if(port.isOpen) {
            _log('Closing serial port');
            port.close();
            _log('Serial port closed');
          }

          _log('Disposing serial port');
          port.dispose();
          _log('Serial port disposed');
        } else {
          _log('No serial port to clean up');
        }

        connected = false;
        _statusController.add(false);
        _log('disconnect() complete. connected=$connected');

        return true;

      } catch (error, stackTrace) {
        //log/display error
        _log('disconnect() caught error: $error');
        _log('disconnect() stackTrace: $stackTrace');

        connected = false;
        _statusController.add(false);

        return false;
      }
    }

    //helper function to verify that the scanner is actually communicating with 
    //the computer
    Future<bool> _validateConnection(SerialPort port) async {
      StreamSubscription<Uint8List>? sub;

      final completer = Completer<String>();
      final buffer = StringBuffer();

      _log('_validateConnection() started. portIsOpen=${port.isOpen}');

      try {
        _log('_validateConnection() subscribing to existing byte controller stream');

        sub = _controller.stream.listen(
          (data) {
            _log('_validateConnection() saw data: ${_formatBytes(data)}');

            // Convert incoming bytes into text.
            buffer.write(String.fromCharCodes(data));

            // Check whether we have received a complete line yet.
            final text = buffer.toString();
            final lines = text.split(RegExp(r'\r\n|\n|\r'));

            _log('_validateConnection() current buffer="$text", parsedLines=$lines');

            for (final line in lines) {
              final trimmed = line.trim();

              // RID should respond with something like "01".
              final isReaderId = RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(trimmed);

              _log('_validateConnection() checking line="$trimmed", isReaderId=$isReaderId');

              if (isReaderId && !completer.isCompleted) {
                _log('_validateConnection() completed with reader id="$trimmed"');
                completer.complete(trimmed);
                return;
              }
            }
          },
          onError: (error, stackTrace) {
            _log('_validateConnection() stream error: $error');

            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
        );

        // Ask scanner to report its reader ID.
        final command = Uint8List.fromList('RID\r\n'.codeUnits);
        _log('_validateConnection() writing RID command: ${_formatBytes(command)}');

        final bytesWritten = port.write(command);
        _log('_validateConnection() RID bytesWritten=$bytesWritten');

        // Wait for the stream listener above to complete the Future.
        _log('_validateConnection() waiting up to 2 seconds for RID response');
        final response = await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            _log('_validateConnection() timed out waiting for RID response');

            if (!completer.isCompleted) {
              completer.complete('');
            }

            return '';
          },
        );

        final valid = RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(response.trim());
        _log('_validateConnection() final response="$response", valid=$valid');

        return valid;
      } catch (error, stackTrace) {
        _log('_validateConnection() caught error: $error');
        _log('_validateConnection() stackTrace: $stackTrace');

        return false;
      } finally {
        _log('_validateConnection() cancelling validation subscription');
        await sub?.cancel();
        _log('_validateConnection() validation subscription cancelled');
      }
    }

    Future<bool> _openPortWithRetries(SerialPort port, String portName) async {
      const attempts = 3;
      const retryDelay = Duration(milliseconds: 1200);

      for (var attempt = 1; attempt <= attempts; attempt++) {
        _log('open attempt $attempt/$attempts for $portName');

        final opened = port.openReadWrite();

        _log(
          'open attempt $attempt/$attempts result for $portName: '
          'opened=$opened, isOpen=${port.isOpen}',
        );

        if (opened && port.isOpen) {
          return true;
        }

        if (attempt < attempts) {
          _log('open attempt failed for $portName. Waiting ${retryDelay.inMilliseconds}ms before retry.');
          await Future.delayed(retryDelay);
        }
      }

      return false;
    }
  }