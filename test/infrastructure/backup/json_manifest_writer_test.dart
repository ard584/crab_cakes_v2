import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:ui_prototype/application/backup/dtos/backup_plan.dart';
import 'package:ui_prototype/application/backup/dtos/backup_request.dart';
import 'package:ui_prototype/infrastructure/backup/json_manifest_writer.dart';

void main() {
  group('JsonManifestWriter', () {
    late Directory tempDir;
    late JsonManifestWriter writer;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'json_manifest_writer_test_',
      );

      writer = JsonManifestWriter();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    BackupRequest request({
      String projectId = 'project-123',
      String projectName = 'Colorado River Study',
      String sourceDbPath = 'C:/source/project.sqlite',
      bool includeTextExport = true,
      DateTime? createdAt,
      String? baseTable,
      String? exportDelimiter,
    }) {
      return BackupRequest(
        projectId: projectId,
        projectName: projectName,
        sourceDbPath: sourceDbPath,
        includeTextExport: includeTextExport,
        createdAt: createdAt ?? DateTime.utc(2026, 5, 3, 12, 30),
        baseTable: baseTable,
        exportDelimiter: exportDelimiter,
      );
    }

    BackupPlan plan({
      String? backupRootPath,
      String? projectRootPath,
      String? dataDir,
      String? exportDir,
      String? backupDbPath,
      String? textExportPath,
      String? manifestPath,
    }) {
      final root = backupRootPath ?? path.join(tempDir.path, 'CRABCAKES');
      final projectRoot = projectRootPath ?? path.join(root, 'projects', 'Project_project-123');
      final data = dataDir ?? path.join(projectRoot, 'data');
      final export = exportDir ?? path.join(projectRoot, 'export');

      Directory(data).createSync(recursive: true);
      Directory(export).createSync(recursive: true);

      return BackupPlan(
        backupRootPath: root,
        projectRootPath: projectRoot,
        dataDir: data,
        exportDir: export,
        backupDbPath: backupDbPath ?? path.join(data, 'data.sqlite'),
        textExportPath: textExportPath ?? path.join(export, 'data.txt'),
        manifestPath: manifestPath ?? path.join(projectRoot, 'backup_manifest.json'),
      );
    }

    Map<String, dynamic> readManifest(String manifestPath) {
      return jsonDecode(File(manifestPath).readAsStringSync())
          as Map<String, dynamic>;
    }

    test('creates manifest file', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      expect(File(backupPlan.manifestPath).existsSync(), isTrue);
    });

    test('writes valid JSON', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      expect(
        () => jsonDecode(File(backupPlan.manifestPath).readAsStringSync()),
        returnsNormally,
      );
    });

    test('writes pretty-printed JSON with indentation', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      final text = File(backupPlan.manifestPath).readAsStringSync();

      expect(text, contains('\n'));
      expect(text, contains('  "version"'));
    });

    test('writes manifest version 1', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);

      expect(manifest['version'], 1);
    });

    test('writes project id from request', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(projectId: 'abc-123'),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);

      expect(manifest['projectId'], 'abc-123');
    });

    test('writes project name from request', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(projectName: 'Fish Survey'),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);

      expect(manifest['projectName'], 'Fish Survey');
    });

    test('writes backupCreatedAt in UTC ISO-8601 format', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(
          createdAt: DateTime(2026, 5, 3, 12, 30),
        ),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);

      expect(manifest['backupCreatedAt'], DateTime(2026, 5, 3, 12, 30).toUtc().toIso8601String());
    });

    test('database path is relative data/data.sqlite', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final database = manifest['database'] as Map<String, dynamic>;

      expect(database['path'], 'data/data.sqlite');
    });

    test('database exists is false when backup db file is missing', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final database = manifest['database'] as Map<String, dynamic>;

      expect(database['exists'], isFalse);
    });

    test('database sizeBytes is zero when backup db file is missing', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final database = manifest['database'] as Map<String, dynamic>;

      expect(database['sizeBytes'], 0);
    });

    test('database exists is true when backup db file exists', () async {
      final backupPlan = plan();

      File(backupPlan.backupDbPath).writeAsStringSync('fake sqlite bytes');

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final database = manifest['database'] as Map<String, dynamic>;

      expect(database['exists'], isTrue);
    });

    test('database sizeBytes matches backup db file size', () async {
      final backupPlan = plan();

      File(backupPlan.backupDbPath).writeAsStringSync('1234567890');

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final database = manifest['database'] as Map<String, dynamic>;

      expect(database['sizeBytes'], 10);
    });

    test('textExport included is true when request includes text export', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(includeTextExport: true),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['included'], isTrue);
    });

    test('textExport included is false when request excludes text export', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(includeTextExport: false),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['included'], isFalse);
    });

    test('textExport path is export/data.txt when included', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(includeTextExport: true),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['path'], 'export/data.txt');
    });

    test('textExport path is null when not included', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(includeTextExport: false),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['path'], isNull);
    });

    test('textExport exists is false when included but file is missing', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(includeTextExport: true),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['exists'], isFalse);
    });

    test('textExport sizeBytes is zero when included but file is missing', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(includeTextExport: true),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['sizeBytes'], 0);
    });

    test('textExport exists is true when included and file exists', () async {
      final backupPlan = plan();

      File(backupPlan.textExportPath).writeAsStringSync('export data');

      await writer.writeManifest(
        request: request(includeTextExport: true),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['exists'], isTrue);
    });

    test('textExport sizeBytes matches export file size when included', () async {
      final backupPlan = plan();

      File(backupPlan.textExportPath).writeAsStringSync('12345');

      await writer.writeManifest(
        request: request(includeTextExport: true),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['sizeBytes'], 5);
    });

    test('textExport exists is false when file exists but export not included', () async {
      final backupPlan = plan();

      File(backupPlan.textExportPath).writeAsStringSync('export data');

      await writer.writeManifest(
        request: request(includeTextExport: false),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['exists'], isFalse);
    });

    test('textExport sizeBytes is zero when file exists but export not included', () async {
      final backupPlan = plan();

      File(backupPlan.textExportPath).writeAsStringSync('export data');

      await writer.writeManifest(
        request: request(includeTextExport: false),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(textExport['sizeBytes'], 0);
    });

    test('writes both database and text export file sizes when both exist', () async {
      final backupPlan = plan();

      File(backupPlan.backupDbPath).writeAsStringSync('db-bytes');
      File(backupPlan.textExportPath).writeAsStringSync('export-bytes');

      await writer.writeManifest(
        request: request(includeTextExport: true),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);
      final database = manifest['database'] as Map<String, dynamic>;
      final textExport = manifest['textExport'] as Map<String, dynamic>;

      expect(database['exists'], isTrue);
      expect(database['sizeBytes'], 'db-bytes'.length);
      expect(textExport['exists'], isTrue);
      expect(textExport['sizeBytes'], 'export-bytes'.length);
    });

    test('overwrites existing manifest file', () async {
      final backupPlan = plan();

      File(backupPlan.manifestPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('old manifest');

      await writer.writeManifest(
        request: request(projectId: 'new-project'),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);

      expect(manifest['projectId'], 'new-project');
    });

    test('does not create backup db file', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(),
        plan: backupPlan,
      );

      expect(File(backupPlan.backupDbPath).existsSync(), isFalse);
    });

    test('does not create text export file', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(includeTextExport: true),
        plan: backupPlan,
      );

      expect(File(backupPlan.textExportPath).existsSync(), isFalse);
    });

    test('baseTable does not appear in manifest', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(baseTable: 'Specimen'),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);

      expect(manifest.containsKey('baseTable'), isFalse);
    });

    test('exportDelimiter does not appear in manifest', () async {
      final backupPlan = plan();

      await writer.writeManifest(
        request: request(exportDelimiter: '\t'),
        plan: backupPlan,
      );

      final manifest = readManifest(backupPlan.manifestPath);

      expect(manifest.containsKey('exportDelimiter'), isFalse);
    });

    test('throws FileSystemException when manifest parent directory does not exist', () async {
      final backupPlan = plan(
        manifestPath: path.join(tempDir.path, 'missing', 'backup_manifest.json'),
      );

      await expectLater(
        () => writer.writeManifest(
          request: request(),
          plan: backupPlan,
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}