import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ui_prototype/infrastructure/project/project_json_integrity_service.dart';

void main() {
  group('ProjectJsonIntegrityService', () {
    late ProjectJsonIntegrityService service;

    setUp(() {
      service = ProjectJsonIntegrityService(
        hmacKey: utf8.encode('test-hmac-key'),
      );
    });

    Map<String, dynamic> samplePayload() {
      return {
        'formatVersion': 1,
        'projectGuid': 'project-guid-123',
        'schemaHash': 'schema-hash-456',
        'syncVersion': 1,
        'schemaSql': [
          'CREATE TABLE Trip (id INTEGER PRIMARY KEY);',
          'CREATE TABLE Sample (id INTEGER PRIMARY KEY, trip_id INTEGER);',
        ],
        'settings': {
          'scanner': {
            'targetTable': 'Specimen',
            'targetColumn': 'tag_id',
          },
          'export': {
            'baseTable': 'Specimen',
            'delimiter': '\t',
          },
        },
      };
    }

    // -------------------------------------------------------------------------
    // createSignedWrapper
    // -------------------------------------------------------------------------

    test('createSignedWrapper returns payload and integrity wrapper', () {
      final payload = samplePayload();

      final wrapper = service.createSignedWrapper(payload);

      expect(wrapper.containsKey('payload'), isTrue);
      expect(wrapper.containsKey('integrity'), isTrue);
      expect(wrapper['payload'], payload);
      expect(wrapper['integrity'], isA<Map<String, dynamic>>());
    });

    test('createSignedWrapper uses HMAC-SHA256 algorithm label', () {
      final wrapper = service.createSignedWrapper(samplePayload());
      final integrity = wrapper['integrity'] as Map<String, dynamic>;

      expect(integrity['algorithm'], ProjectJsonIntegrityService.algorithm);
      expect(integrity['algorithm'], 'HMAC-SHA256');
    });

    test('createSignedWrapper creates non-empty string signature', () {
      final wrapper = service.createSignedWrapper(samplePayload());
      final integrity = wrapper['integrity'] as Map<String, dynamic>;

      expect(integrity['signature'], isA<String>());
      expect((integrity['signature'] as String).isNotEmpty, isTrue);
    });

    test('createSignedWrapper creates sha256 hex-length signature', () {
      final wrapper = service.createSignedWrapper(samplePayload());
      final integrity = wrapper['integrity'] as Map<String, dynamic>;
      final signature = integrity['signature'] as String;

      expect(signature.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(signature), isTrue);
    });

    test('createSignedWrapper produces deterministic signature for same payload and key', () {
      final payload = samplePayload();

      final first = service.createSignedWrapper(payload);
      final second = service.createSignedWrapper(payload);

      final firstIntegrity = first['integrity'] as Map<String, dynamic>;
      final secondIntegrity = second['integrity'] as Map<String, dynamic>;

      expect(firstIntegrity['signature'], secondIntegrity['signature']);
    });

    test('createSignedWrapper produces different signature when payload changes', () {
      final firstPayload = samplePayload();

      final secondPayload = samplePayload();
      secondPayload['projectGuid'] = 'different-guid';

      final first = service.createSignedWrapper(firstPayload);
      final second = service.createSignedWrapper(secondPayload);

      final firstIntegrity = first['integrity'] as Map<String, dynamic>;
      final secondIntegrity = second['integrity'] as Map<String, dynamic>;

      expect(firstIntegrity['signature'], isNot(secondIntegrity['signature']));
    });

    test('createSignedWrapper produces different signature when key changes', () {
      final payload = samplePayload();

      final otherService = ProjectJsonIntegrityService(
        hmacKey: utf8.encode('different-key'),
      );

      final first = service.createSignedWrapper(payload);
      final second = otherService.createSignedWrapper(payload);

      final firstIntegrity = first['integrity'] as Map<String, dynamic>;
      final secondIntegrity = second['integrity'] as Map<String, dynamic>;

      expect(firstIntegrity['signature'], isNot(secondIntegrity['signature']));
    });

    test('createSignedWrapper supports empty payload map', () {
      final payload = <String, dynamic>{};

      final wrapper = service.createSignedWrapper(payload);

      expect(wrapper['payload'], payload);
      expect(wrapper['integrity'], isA<Map<String, dynamic>>());

      final verifiedPayload = service.extractVerifiedPayload(wrapper);

      expect(verifiedPayload, payload);
    });

    test('createSignedWrapper supports nested payload data', () {
      final payload = {
        'settings': {
          'scanner': {
            'targetTable': 'Specimen',
            'targetColumn': 'tag_id',
          },
          'fieldConfig': {
            'Specimen': {
              'tag_id': {
                'useDropdown': false,
                'allowCustomValues': true,
                'options': ['A', 'B', 'C'],
              },
            },
          },
        },
      };

      final wrapper = service.createSignedWrapper(payload);

      final verifiedPayload = service.extractVerifiedPayload(wrapper);

      expect(verifiedPayload, payload);
    });

    // -------------------------------------------------------------------------
    // createSignedJson
    // -------------------------------------------------------------------------

    test('createSignedJson returns valid JSON string', () {
      final signedJson = service.createSignedJson(samplePayload());

      final decoded = jsonDecode(signedJson);

      expect(decoded, isA<Map<String, dynamic>>());
    });

    test('createSignedJson returns encoded wrapper with payload and integrity', () {
      final payload = samplePayload();

      final signedJson = service.createSignedJson(payload);
      final decoded = jsonDecode(signedJson) as Map<String, dynamic>;

      expect(decoded.containsKey('payload'), isTrue);
      expect(decoded.containsKey('integrity'), isTrue);
      expect(decoded['payload'], payload);
    });

    test('createSignedJson output can be verified and extracted', () {
      final payload = samplePayload();

      final signedJson = service.createSignedJson(payload);
      final decoded = jsonDecode(signedJson) as Map<String, dynamic>;

      final verifiedPayload = service.extractVerifiedPayload(decoded);

      expect(verifiedPayload, payload);
    });

    test('createSignedJson produces deterministic JSON for same payload and key', () {
      final payload = samplePayload();

      final first = service.createSignedJson(payload);
      final second = service.createSignedJson(payload);

      expect(first, second);
    });

    // -------------------------------------------------------------------------
    // extractVerifiedPayload
    // -------------------------------------------------------------------------

    test('extractVerifiedPayload returns original payload for valid wrapper', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);

      final verifiedPayload = service.extractVerifiedPayload(wrapper);

      expect(verifiedPayload, payload);
    });

    test('extractVerifiedPayload throws when payload key is missing', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);

      wrapper.remove('payload');

      expect(
        () => service.extractVerifiedPayload(wrapper),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('extractVerifiedPayload throws when payload is not a map', () {
      final wrapper = {
        'payload': 'not-a-map',
        'integrity': {
          'algorithm': ProjectJsonIntegrityService.algorithm,
          'signature': 'not-important',
        },
      };

      expect(
        () => service.extractVerifiedPayload(wrapper),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('extractVerifiedPayload throws when integrity key is missing', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);

      wrapper.remove('integrity');

      expect(
        () => service.extractVerifiedPayload(wrapper),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('extractVerifiedPayload throws when integrity is not a map', () {
      final wrapper = {
        'payload': samplePayload(),
        'integrity': 'not-a-map',
      };

      expect(
        () => service.extractVerifiedPayload(wrapper),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('extractVerifiedPayload ignores unrelated top-level wrapper fields', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);

      wrapper['extraField'] = 'ignored';

      final verifiedPayload = service.extractVerifiedPayload(wrapper);

      expect(verifiedPayload, payload);
    });

    // -------------------------------------------------------------------------
    // verifyPayload
    // -------------------------------------------------------------------------

    test('verifyPayload does not throw for valid payload and integrity', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);
      final integrity = wrapper['integrity'] as Map<String, dynamic>;

      expect(
        () => service.verifyPayload(
          payload: payload,
          integrity: integrity,
        ),
        returnsNormally,
      );
    });

    test('verifyPayload throws for unsupported algorithm', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);
      final integrity = Map<String, dynamic>.from(
        wrapper['integrity'] as Map<String, dynamic>,
      );

      integrity['algorithm'] = 'SHA256';

      expect(
        () => service.verifyPayload(
          payload: payload,
          integrity: integrity,
        ),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('verifyPayload throws when signature is missing', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);
      final integrity = Map<String, dynamic>.from(
        wrapper['integrity'] as Map<String, dynamic>,
      );

      integrity.remove('signature');

      expect(
        () => service.verifyPayload(
          payload: payload,
          integrity: integrity,
        ),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('verifyPayload throws when signature is empty', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);
      final integrity = Map<String, dynamic>.from(
        wrapper['integrity'] as Map<String, dynamic>,
      );

      integrity['signature'] = '';

      expect(
        () => service.verifyPayload(
          payload: payload,
          integrity: integrity,
        ),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('verifyPayload throws when signature is not a string', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);
      final integrity = Map<String, dynamic>.from(
        wrapper['integrity'] as Map<String, dynamic>,
      );

      integrity['signature'] = 12345;

      expect(
        () => service.verifyPayload(
          payload: payload,
          integrity: integrity,
        ),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('verifyPayload throws when payload has been tampered with', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);
      final integrity = wrapper['integrity'] as Map<String, dynamic>;

      final tamperedPayload = Map<String, dynamic>.from(payload);
      tamperedPayload['projectGuid'] = 'tampered-guid';

      expect(
        () => service.verifyPayload(
          payload: tamperedPayload,
          integrity: integrity,
        ),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('verifyPayload throws when nested payload has been tampered with', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);
      final integrity = wrapper['integrity'] as Map<String, dynamic>;

      final tamperedPayload = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
      final settings = tamperedPayload['settings'] as Map<String, dynamic>;
      final scanner = settings['scanner'] as Map<String, dynamic>;

      scanner['targetTable'] = 'DifferentTable';

      expect(
        () => service.verifyPayload(
          payload: tamperedPayload,
          integrity: integrity,
        ),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('verifyPayload throws when signature has been tampered with', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);
      final integrity = Map<String, dynamic>.from(
        wrapper['integrity'] as Map<String, dynamic>,
      );

      final signature = integrity['signature'] as String;
      integrity['signature'] = '${signature.substring(0, signature.length - 1)}0';

      expect(
        () => service.verifyPayload(
          payload: payload,
          integrity: integrity,
        ),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('verifyPayload throws when verified with different key', () {
      final payload = samplePayload();
      final wrapper = service.createSignedWrapper(payload);
      final integrity = wrapper['integrity'] as Map<String, dynamic>;

      final otherService = ProjectJsonIntegrityService(
        hmacKey: utf8.encode('different-key'),
      );

      expect(
        () => otherService.verifyPayload(
          payload: payload,
          integrity: integrity,
        ),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    // -------------------------------------------------------------------------
    // JSON ordering / canonical behavior
    // -------------------------------------------------------------------------

    test('different map insertion order produces different signature with jsonEncode canonicalization', () {
      final firstPayload = <String, dynamic>{
        'a': 1,
        'b': 2,
      };

      final secondPayload = <String, dynamic>{
        'b': 2,
        'a': 1,
      };

      final first = service.createSignedWrapper(firstPayload);
      final second = service.createSignedWrapper(secondPayload);

      final firstIntegrity = first['integrity'] as Map<String, dynamic>;
      final secondIntegrity = second['integrity'] as Map<String, dynamic>;

      expect(firstIntegrity['signature'], isNot(secondIntegrity['signature']));
    });

    test('payload extracted from signed JSON verifies with same key', () {
      final payload = samplePayload();

      final signedJson = service.createSignedJson(payload);
      final root = jsonDecode(signedJson) as Map<String, dynamic>;

      final extractedPayload = service.extractVerifiedPayload(root);

      expect(extractedPayload, payload);
    });

    // -------------------------------------------------------------------------
    // Exception behavior
    // -------------------------------------------------------------------------

    test('ProjectJsonIntegrityException toString returns message', () {
      const exception = ProjectJsonIntegrityException('Something went wrong');

      expect(exception.toString(), 'Something went wrong');
    });
  });
}