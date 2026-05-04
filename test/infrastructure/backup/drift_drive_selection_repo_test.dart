import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crab_cakes/infrastructure/backup/backup_settings_db.dart';
import 'package:crab_cakes/infrastructure/backup/drift_drive_selection_repo.dart';

void main() {
  group('DriftDriveSelectionRepository', () {
    late BackupSettingsDb db;
    late DriftDriveSelectionRepository repo;

    setUp(() {
      db = BackupSettingsDb.forTesting(
        NativeDatabase.memory(),
      );

      repo = DriftDriveSelectionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<String>> rawTargetIds() async {
      final rows = await db.select(db.selectedBackupTargets).get();
      return rows.map((row) => row.targetId).toList();
    }

    Future<void> insertRawTargetId(String id) async {
      await db.into(db.selectedBackupTargets).insert(
            SelectedBackupTargetsCompanion.insert(
              targetId: id,
            ),
          );
    }

    test('loadSelectedIds returns empty set when database is empty', () async {
      final ids = await repo.loadSelectedIds();

      expect(ids, isEmpty);
    });

    test('loadSelectedIds returns one selected id', () async {
      await insertRawTargetId('drive-1');

      final ids = await repo.loadSelectedIds();

      expect(ids, {'drive-1'});
    });

    test('loadSelectedIds returns multiple selected ids', () async {
      await insertRawTargetId('drive-1');
      await insertRawTargetId('drive-2');
      await insertRawTargetId('drive-3');

      final ids = await repo.loadSelectedIds();

      expect(ids, {'drive-1', 'drive-2', 'drive-3'});
    });

    test('loadSelectedIds returns a set, so duplicate rows are impossible through primary key', () async {
      await insertRawTargetId('drive-1');

      expect(
        () => insertRawTargetId('drive-1'),
        throwsException,
      );

      final ids = await repo.loadSelectedIds();

      expect(ids, {'drive-1'});
    });

    test('saveSelectedIds stores one selected id', () async {
      await repo.saveSelectedIds({'drive-1'});

      final ids = await repo.loadSelectedIds();

      expect(ids, {'drive-1'});
    });

    test('saveSelectedIds stores multiple selected ids', () async {
      await repo.saveSelectedIds({
        'drive-1',
        'drive-2',
        'drive-3',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {'drive-1', 'drive-2', 'drive-3'});
    });

    test('saveSelectedIds clears existing rows before inserting new selection', () async {
      await repo.saveSelectedIds({
        'drive-1',
        'drive-2',
      });

      await repo.saveSelectedIds({
        'drive-3',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {'drive-3'});
    });

    test('saveSelectedIds with empty set clears all selected ids', () async {
      await repo.saveSelectedIds({
        'drive-1',
        'drive-2',
      });

      await repo.saveSelectedIds({});

      final ids = await repo.loadSelectedIds();

      expect(ids, isEmpty);
    });

    test('saveSelectedIds replaces raw existing rows', () async {
      await insertRawTargetId('old-drive-1');
      await insertRawTargetId('old-drive-2');

      await repo.saveSelectedIds({
        'new-drive-1',
        'new-drive-2',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {'new-drive-1', 'new-drive-2'});
    });

    test('saveSelectedIds does not create duplicate rows from set input', () async {
      final ids = <String>{
        'drive-1',
      };

      await repo.saveSelectedIds(ids);

      final rawRows = await rawTargetIds();

      expect(rawRows.length, 1);
      expect(rawRows.single, 'drive-1');
    });

    test('saveSelectedIds persists Windows drive path style id', () async {
      await repo.saveSelectedIds({
        r'E:\',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {r'E:\'});
    });

    test('saveSelectedIds persists volume identifier style id', () async {
      const targetId = r'\\?\Volume{abc-123}\';

      await repo.saveSelectedIds({
        targetId,
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {targetId});
    });

    test('saveSelectedIds persists ids with spaces', () async {
      await repo.saveSelectedIds({
        'USB Drive One',
        'USB Drive Two',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {'USB Drive One', 'USB Drive Two'});
    });

    test('saveSelectedIds persists unicode ids', () async {
      await repo.saveSelectedIds({
        'unidad-café',
        'disco-niño',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {'unidad-café', 'disco-niño'});
    });

    test('saveSelectedIds persists long ids', () async {
      final longId = 'drive-${'x' * 200}';

      await repo.saveSelectedIds({
        longId,
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {longId});
    });

    test('saveSelectedIds persists empty string id if provided', () async {
      await repo.saveSelectedIds({
        '',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {''});
    });

    test('saveSelectedIds preserves ids exactly', () async {
      const weirdId = '  drive id with spaces  ';

      await repo.saveSelectedIds({
        weirdId,
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {weirdId});
    });

    test('loadSelectedIds returns ids regardless of insertion order', () async {
      await insertRawTargetId('drive-b');
      await insertRawTargetId('drive-a');
      await insertRawTargetId('drive-c');

      final ids = await repo.loadSelectedIds();

      expect(ids, {'drive-a', 'drive-b', 'drive-c'});
    });

    test('saveSelectedIds can be called repeatedly with same set', () async {
      final ids = {
        'drive-1',
        'drive-2',
      };

      await repo.saveSelectedIds(ids);
      await repo.saveSelectedIds(ids);
      await repo.saveSelectedIds(ids);

      final loaded = await repo.loadSelectedIds();
      final rawRows = await rawTargetIds();

      expect(loaded, ids);
      expect(rawRows.length, 2);
    });

    test('saveSelectedIds can transition from empty to non-empty', () async {
      await repo.saveSelectedIds({});

      await repo.saveSelectedIds({
        'drive-1',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {'drive-1'});
    });

    test('saveSelectedIds can transition from non-empty to empty to non-empty', () async {
      await repo.saveSelectedIds({
        'drive-1',
        'drive-2',
      });

      await repo.saveSelectedIds({});

      await repo.saveSelectedIds({
        'drive-3',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {'drive-3'});
    });

    test('saveSelectedIds writes exactly the number of ids provided', () async {
      await repo.saveSelectedIds({
        'drive-1',
        'drive-2',
        'drive-3',
        'drive-4',
      });

      final rawRows = await rawTargetIds();

      expect(rawRows.length, 4);
    });

    test('loadSelectedIds sees data inserted directly into database', () async {
      await insertRawTargetId('direct-drive');

      final ids = await repo.loadSelectedIds();

      expect(ids, {'direct-drive'});
    });

    test('raw database sees data saved through repository', () async {
      await repo.saveSelectedIds({
        'repo-drive',
      });

      final rawRows = await rawTargetIds();

      expect(rawRows, ['repo-drive']);
    });

    test('saveSelectedIds uses transaction-like replacement behavior for normal operation', () async {
      await repo.saveSelectedIds({
        'old-1',
        'old-2',
      });

      await repo.saveSelectedIds({
        'new-1',
        'new-2',
        'new-3',
      });

      final ids = await repo.loadSelectedIds();

      expect(ids, {'new-1', 'new-2', 'new-3'});
      expect(ids.contains('old-1'), isFalse);
      expect(ids.contains('old-2'), isFalse);
    });
  });
}