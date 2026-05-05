import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:crab_cakes/application/scanner/interfaces/scanner_stream_repo.dart';

class StreamDecoder implements ScannerStreamRepo{

  Stream<Uint8List> byteStream;

  //constructor
  StreamDecoder({required this.byteStream});

  @override
  Stream<String> getStringStream() {
    //convert the unsigned 8 bit integer stream into a stream of strings
    return byteStream
    .map((u8)=>u8 as List<int>)
    .transform(utf8.decoder)
    .transform(LineSplitter());
  }

}