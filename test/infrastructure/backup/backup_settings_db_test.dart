import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ui_prototype/infrastructure/backup/backup_settings_db.dart';

void main() {
  group('BackupSettingsDb', () {
    late BackupSettingsDb db;

    setUp(() {
      db = BackupSettingsDb.forTesting(
        NativeDatabase.memory(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is 1', () {
      expect(db.schemaVersion, 1);
    });

    test('selected_backup_targets table starts empty', () async {
      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows, isEmpty);
    });

    test('can insert selected backup target', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows.length, 1);
      expect(rows.first.targetId, 'drive-1');
    });

    test('can insert multiple selected backup targets', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-2',
            ),
          );

      final rows = await db.select(db.selectedBackupTargets).get();

      final ids = rows.map((row) => row.targetId).toSet();

      expect(ids, {'drive-1', 'drive-2'});
    });

    test('targetId is primary key and rejects duplicates', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      expect(
        () => db.into(db.selectedBackupTargets).insert(
              SelectedBackupTargetsCompanion.insert(
                targetId: 'drive-1',
              ),
            ),
        throwsException,
      );
    });

    test('can delete selected backup target', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      await (db.delete(db.selectedBackupTargets)
            ..where((tbl) => tbl.targetId.equals('drive-1')))
          .go();

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows, isEmpty);
    });

    test('delete only removes matching target', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-2',
            ),
          );

      await (db.delete(db.selectedBackupTargets)
            ..where((tbl) => tbl.targetId.equals('drive-1')))
          .go();

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows.length, 1);
      expect(rows.first.targetId, 'drive-2');
    });

    test('deleting missing target affects zero rows', () async {
      final deletedCount = await (db.delete(db.selectedBackupTargets)
            ..where((tbl) => tbl.targetId.equals('missing-drive')))
          .go();

      expect(deletedCount, 0);
    });

    test('can read selected targets and sort them by target id', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-b',
            ),
          );

      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-a',
            ),
          );

      final rows = await db.select(db.selectedBackupTargets).get();

      final ids = rows.map((row) => row.targetId).toList()..sort();

      expect(ids, ['drive-a', 'drive-b']);
    });

    test('can clear all selected backup targets', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-2',
            ),
          );

      final deletedCount = await db.delete(db.selectedBackupTargets).go();

      expect(deletedCount, 2);

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows, isEmpty);
    });

    test('supports target ids with Windows drive paths', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: r'E:\',
            ),
          );

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows.single.targetId, r'E:\');
    });

    test('supports target ids with volume-like identifiers', () async {
      const targetId = r'\\?\Volume{abc-123}\';

      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: targetId,
            ),
          );

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows.single.targetId, targetId);
    });

    test('supports target ids with spaces', () async {
      const targetId = 'USB Drive Backup Target';

      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: targetId,
            ),
          );

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows.single.targetId, targetId);
    });

    test('supports long target ids', () async {
      final targetId = 'drive-${'x' * 200}';

      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: targetId,
            ),
          );

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows.single.targetId, targetId);
    });

    test('supports unicode target ids', () async {
      const targetId = 'unidad-café-ñ';

      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: targetId,
            ),
          );

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows.single.targetId, targetId);
    });

    test('insertOnConflictUpdate keeps one row for same target id', () async {
      await db.into(db.selectedBackupTargets).insertOnConflictUpdate(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      await db.into(db.selectedBackupTargets).insertOnConflictUpdate(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows.length, 1);
      expect(rows.single.targetId, 'drive-1');
    });

    test('select returns generated data class type', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      final row = await db.select(db.selectedBackupTargets).getSingle();

      expect(row, isA<SelectedBackupTarget>());
      expect(row.targetId, 'drive-1');
    });

    test('can watch selected backup targets stream', () async {
      final emitted = <List<SelectedBackupTarget>>[];

      final sub = db.select(db.selectedBackupTargets).watch().listen(emitted.add);

      await Future<void>.delayed(Duration.zero);

      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isNotEmpty);
      expect(
        emitted.last.map((row) => row.targetId).toList(),
        ['drive-1'],
      );

      await sub.cancel();
    });

    test('watch stream emits update after delete', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      final emitted = <List<SelectedBackupTarget>>[];

      final sub = db.select(db.selectedBackupTargets).watch().listen(emitted.add);

      await Future<void>.delayed(Duration.zero);

      await (db.delete(db.selectedBackupTargets)
            ..where((tbl) => tbl.targetId.equals('drive-1')))
          .go();

      await Future<void>.delayed(Duration.zero);

      expect(emitted.last, isEmpty);

      await sub.cancel();
    });

    test('database can be closed without throwing', () async {
      await expectLater(
        db.close(),
        completes,
      );

      db = BackupSettingsDb.forTesting(
        NativeDatabase.memory(),
      );
    });

    test('database can be recreated after close', () async {
      await db.close();

      db = BackupSettingsDb.forTesting(
        NativeDatabase.memory(),
      );

      final rows = await db.select(db.selectedBackupTargets).get();

      expect(rows, isEmpty);
    });

    test('separate in-memory databases do not share selected targets', () async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: 'drive-1',
            ),
          );

      await db.close();

      final otherDb = BackupSettingsDb.forTesting(
        NativeDatabase.memory(),
      );

      try {
        final otherRows = await otherDb.select(otherDb.selectedBackupTargets).get();

        expect(otherRows, isEmpty);
      } finally {
        await otherDb.close();

        // Recreate db so tearDown can still close it safely.
        db = BackupSettingsDb.forTesting(
          NativeDatabase.memory(),
        );
      }
    });

    test('targetId column is not nullable through companion insert', () async {
      final companion = SelectedBackupTargetsCompanion.insert(
        targetId: 'drive-1',
      );

      expect(companion.targetId.present, isTrue);
      expect(companion.targetId.value, 'drive-1');
    });
  });
}