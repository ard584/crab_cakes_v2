import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:crab_cakes/infrastructure/scanner/stream_decoder.dart';

void main() {
  group('StreamDecoder', () {
    late StreamController<Uint8List> controller;
    late StreamDecoder decoder;

    setUp(() {
      controller = StreamController<Uint8List>();
      decoder = StreamDecoder(byteStream: controller.stream);
    });

    tearDown(() async {
      if (!controller.isClosed) {
        await controller.close();
      }
    });

    Uint8List bytes(String value) {
      return Uint8List.fromList(utf8.encode(value));
    }

    test('decodes a single LF-terminated line', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('hello\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['hello']);
    });

    test('decodes a single CRLF-terminated line', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('hello\r\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['hello']);
    });

    test('decodes a single CR-terminated line', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('hello\r'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['hello']);
    });

    test('decodes multiple LF-terminated lines from one chunk', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('one\ntwo\nthree\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['one', 'two', 'three']);
    });

    test('decodes multiple CRLF-terminated lines from one chunk', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('one\r\ntwo\r\nthree\r\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['one', 'two', 'three']);
    });

    test('decodes multiple CR-terminated lines from one chunk', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('one\rtwo\rthree\r'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['one', 'two', 'three']);
    });

    test('decodes mixed line endings', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('one\ntwo\r\nthree\rfour\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['one', 'two', 'three', 'four']);
    });

    test('handles a line split across two chunks', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('hel'));
      controller.add(bytes('lo\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['hello']);
    });

    test('handles a line split across many chunks', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('h'));
      controller.add(bytes('e'));
      controller.add(bytes('l'));
      controller.add(bytes('l'));
      controller.add(bytes('o'));
      controller.add(bytes('\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['hello']);
    });

    test('handles multiple lines split across chunks', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('one\nt'));
      controller.add(bytes('wo\nthr'));
      controller.add(bytes('ee\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['one', 'two', 'three']);
    });

    test('handles CRLF split across chunks', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('hello\r'));
      controller.add(bytes('\nworld\r'));
      controller.add(bytes('\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['hello', 'world']);
    });

    test('emits final unterminated line when stream closes', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('hello'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['hello']);
    });

    test('does not emit anything for an empty stream', () async {
      final futureLines = decoder.getStringStream().toList();

      await controller.close();

      final lines = await futureLines;

      expect(lines, isEmpty);
    });

    test('emits empty line for blank LF line', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['']);
    });

    test('emits empty lines for consecutive line breaks', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('one\n\nthree\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['one', '', 'three']);
    });

    test('preserves leading and trailing spaces in decoded lines', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('  hello  \n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['  hello  ']);
    });

    test('decodes realistic scanner line', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(
        bytes('03-02-2017 05:31:50 01 TAG 3DD.003BFB8ADF\r\n'),
      );

      await controller.close();

      final lines = await futureLines;

      expect(lines, [
        '03-02-2017 05:31:50 01 TAG 3DD.003BFB8ADF',
      ]);
    });

    test('decodes multiple realistic scanner lines', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(
        bytes(
          '03-02-2017 05:31:50 01 TAG 3DD.003BFB8ADF\r\n'
          '03-02-2017 05:31:55 01 TAG 3DD.003BFB8AD0\r\n',
        ),
      );

      await controller.close();

      final lines = await futureLines;

      expect(lines, [
        '03-02-2017 05:31:50 01 TAG 3DD.003BFB8ADF',
        '03-02-2017 05:31:55 01 TAG 3DD.003BFB8AD0',
      ]);
    });

    test('decodes non-ASCII UTF-8 characters', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('café\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['café']);
    });

    test('decodes UTF-8 character split across chunks', () async {
      final futureLines = decoder.getStringStream().toList();

      final encoded = Uint8List.fromList(utf8.encode('café\n'));

      controller.add(Uint8List.fromList(encoded.sublist(0, 4)));
      controller.add(Uint8List.fromList(encoded.sublist(4)));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['café']);
    });

    test('propagates errors from byte stream', () async {
      final errors = <Object>[];

      final sub = decoder.getStringStream().listen(
        (_) {},
        onError: errors.add,
      );

      controller.addError(StateError('scanner stream failed'));

      await Future<void>.delayed(Duration.zero);

      expect(errors.length, 1);
      expect(errors.first, isA<StateError>());

      await sub.cancel();
    });

    test('continues after stream error when listener does not cancel', () async {
      final lines = <String>[];
      final errors = <Object>[];

      final sub = decoder.getStringStream().listen(
        lines.add,
        onError: errors.add,
      );

      controller.addError(StateError('temporary scanner error'));
      controller.add(bytes('hello\n'));

      await Future<void>.delayed(Duration.zero);

      expect(errors.length, 1);
      expect(errors.first, isA<StateError>());
      expect(lines, ['hello']);

      await sub.cancel();
    });

    test('supports listening with first', () async {
      final futureLine = decoder.getStringStream().first;

      controller.add(bytes('first\nsecond\n'));
      await controller.close();

      final line = await futureLine;

      expect(line, 'first');
    });

    test('supports taking a limited number of decoded lines', () async {
      final futureLines = decoder.getStringStream().take(2).toList();

      controller.add(bytes('one\ntwo\nthree\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, ['one', 'two']);
    });

    test('throws FormatException for invalid UTF-8 bytes', () async {
      final errors = <Object>[];

      final sub = decoder.getStringStream().listen(
        (_) {},
        onError: errors.add,
      );

      controller.add(Uint8List.fromList([0xC3, 0x28]));

      await Future<void>.delayed(Duration.zero);

      expect(errors.length, 1);
      expect(errors.first, isA<FormatException>());

      await sub.cancel();
    });

    test('does not trim scanner output', () async {
      final futureLines = decoder.getStringStream().toList();

      controller.add(bytes('  03-02-2017 05:31:50 01 TAG 3DD.003BFB8ADF  \r\n'));
      await controller.close();

      final lines = await futureLines;

      expect(lines, [
        '  03-02-2017 05:31:50 01 TAG 3DD.003BFB8ADF  ',
      ]);
    });
  });
}