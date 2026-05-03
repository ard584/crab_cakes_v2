import 'dart:convert';

import 'package:crypto/crypto.dart';

class ProjectJsonIntegrityService {
  ProjectJsonIntegrityService({
    required List<int> hmacKey,
  }) : _hmacKey = hmacKey;

  static const String algorithm = 'HMAC-SHA256';

  final List<int> _hmacKey;

  /// Takes the actual project/settings payload and wraps it with integrity data.
  ///
  /// Input shape:
  /// {
  ///   "formatVersion": 1,
  ///   "projectGuid": "...",
  ///   "schemaHash": "...",
  ///   "syncVersion": 1,
  ///   "schemaSql": [],
  ///   "settings": {}
  /// }
  ///
  /// Output shape:
  /// {
  ///   "payload": { ... },
  ///   "integrity": {
  ///     "algorithm": "HMAC-SHA256",
  ///     "signature": "..."
  ///   }
  /// }
  Map<String, dynamic> createSignedWrapper(Map<String, dynamic> payload) {
    final canonicalPayloadJson = jsonEncode(payload);
    final signature = _computeHmacSha256(canonicalPayloadJson);

    return {
      'payload': payload,
      'integrity': {
        'algorithm': algorithm,
        'signature': signature,
      },
    };
  }

  /// Same as createSignedWrapper, but returns the final encoded JSON string.
  String createSignedJson(Map<String, dynamic> payload) {
    final wrapper = createSignedWrapper(payload);
    return jsonEncode(wrapper);
  }

  /// Extracts and verifies the payload from a signed project JSON wrapper.
  ///
  /// Throws a ProjectJsonIntegrityException if the file is missing integrity
  /// data, has an unsupported algorithm, or has an invalid signature.
  Map<String, dynamic> extractVerifiedPayload(Map<String, dynamic> root) {
    final rawPayload = root['payload'];
    final rawIntegrity = root['integrity'];

    if (rawPayload is! Map<String, dynamic>) {
      throw const ProjectJsonIntegrityException(
        'Project JSON payload must be a map.',
      );
    }

    if (rawIntegrity is! Map<String, dynamic>) {
      throw const ProjectJsonIntegrityException(
        'Project JSON integrity must be a map.',
      );
    }

    verifyPayload(
      payload: rawPayload,
      integrity: rawIntegrity,
    );

    return rawPayload;
  }

  /// Verifies the integrity object against the provided payload.
  void verifyPayload({
    required Map<String, dynamic> payload,
    required Map<String, dynamic> integrity,
  }) {
    final rawAlgorithm = integrity['algorithm'];
    final rawSignature = integrity['signature'];

    if (rawAlgorithm != algorithm) {
      throw ProjectJsonIntegrityException(
        'Unsupported project JSON integrity algorithm: $rawAlgorithm',
      );
    }

    if (rawSignature is! String || rawSignature.isEmpty) {
      throw const ProjectJsonIntegrityException(
        'Project JSON signature is missing.',
      );
    }

    final canonicalPayloadJson = jsonEncode(payload);
    final expectedSignature = _computeHmacSha256(canonicalPayloadJson);

    if (!_constantTimeEquals(rawSignature, expectedSignature)) {
      throw const ProjectJsonIntegrityException(
        'Project JSON signature is invalid. The file may have been modified.',
      );
    }
  }

  String _computeHmacSha256(String message) {
    final hmac = Hmac(sha256, _hmacKey);
    final digest = hmac.convert(utf8.encode(message));

    return digest.toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;

    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }
}

class ProjectJsonIntegrityException implements Exception {
  final String message;

  const ProjectJsonIntegrityException(this.message);

  @override
  String toString() => message;
}