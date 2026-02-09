import 'dart:async';
import 'dart:typed_data';

class StreamReader {

  Stream<Uint8List> byteStream;

  StreamSubscription<Uint8List>? _sub;
  final StringBuffer _lineBuffer = StringBuffer();

  StreamReader({required this.byteStream});

  void startReading() {

    _sub = byteStream.listen( (Uint8List data) {
    
      //converting unsigned 8bit ints to their ASCII representations
      final chunk = String.fromCharCodes(data);
      _lineBuffer.write(chunk);

      final text = _lineBuffer.toString();
      final lines = text.split(RegExp(r'\r?\n'));

      final endsWithNewLine = text.endsWith('\n');
      final completeCount = endsWithNewLine ? lines.length : lines.length - 1;

      //iterating over the complete lines
      for(var i=0; i<completeCount; i++) {
        // final scanLine = lines[i].trim();

        //TODO: Figure out how to send this scan to the UI/calling classes

      }

      //clear buffer and write any incomplete lines to it
      _lineBuffer.clear();
      if(!endsWithNewLine && lines.isNotEmpty) {
        _lineBuffer.write(lines.last);
      }
    },
    onError: (e) {
      //TODO: Implement Error Handling
    },
    onDone: () {
      //TODO: Implement cleanup on stream cancellation
    },
    cancelOnError: true,
    );
  }

  void stopReading() async {

    final subscription = _sub;
    if(subscription == null) {
      return;
    }

    _sub = null;
    await subscription.cancel();
  }

}