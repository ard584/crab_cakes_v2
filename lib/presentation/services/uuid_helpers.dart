import 'dart:typed_data';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

int nowMs() => DateTime.now().millisecondsSinceEpoch;

Uint8List newUuidV7() => UuidValue.fromString(_uuid.v7()).toBytes();
Uint8List newUuidV4() => UuidValue.fromString(_uuid.v4()).toBytes();
