import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_prototype/application/active_project_repository.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/domain/models/attribute.dart';
import 'package:ui_prototype/domain/models/db_row.dart';
import 'package:ui_prototype/application/catch_history/catch_history.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class MockActiveProjectRepository extends Mock
    implements ActiveProjectRepository<RowIdentifier> {}

class TestRowIdentifier extends RowIdentifier {
  @override
  String get identifier => 'test-id';
}

DbRow<TestRowIdentifier> makeRow(Map<String, dynamic> values) {
  return DbRow(identifier: TestRowIdentifier(), values: values);
}

void main() {
  late MockActiveProjectRepository mockRepo;
  late TableInput table;
  late CatchHistoryViewModel viewModel;

  final attributes = {
    'field_one': AttributeFormField(
      fields: Attribute(
        columnID: 1,
        name: 'field_one',
        dataType: 'TEXT',
        isNotNullable: false,
        isPrimaryKey: false,
      ),
    ),
    'field_two': AttributeFormField(
      fields: Attribute(
        columnID: 2,
        name: 'field_two',
        dataType: 'TEXT',
        isNotNullable: false,
        isPrimaryKey: false,
      ),
    ),
  };

  // Schema without created_at_time
  final schemaWithoutTime = DbTable(
    name: 'test_log',
    columns: [
      DbColumn(name: 'field_one', type: 'TEXT', nullable: true, primaryKey: false),
      DbColumn(name: 'field_two', type: 'TEXT', nullable: true, primaryKey: false),
    ],
  );

  // Schema with __created_at_time
  final schemaWithTime = DbTable(
    name: 'test_log',
    columns: [
      DbColumn(name: 'field_one', type: 'TEXT', nullable: true, primaryKey: false),
      DbColumn(name: 'field_two', type: 'TEXT', nullable: true, primaryKey: false),
      DbColumn(name: '__created_at_time', type: 'TEXT', nullable: true, primaryKey: false),
    ],
  );

  setUp(() {
    mockRepo = MockActiveProjectRepository();
    table = TableInput(name: 'test_log', attributes: attributes);
    viewModel = CatchHistoryViewModel(db: mockRepo, table: table);
  });

  group('CatchHistoryViewModel', () {

    test('getCatches uses rowid when no created_at_time column', () {
      final rows = [makeRow({'field_one': 'a', 'field_two': 'b'})];

      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid')).thenReturn(rows);

      final result = viewModel.getCatches();

      verify(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid')).called(1);
      verifyNever(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'created_at_time'));
      expect(result.length, 1);
    });

    test('getCatches uses created_at_time when column exists', () {
      final rows = [makeRow({'field_one': 'a', 'field_two': 'b', '__created_at_time': '2026-01-01 10:00:00'})];

      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithTime);
      when(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, '__created_at_time')).thenReturn(rows);

      final result = viewModel.getCatches();

      verify(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, '__created_at_time')).called(1);
      verifyNever(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid'));
      expect(result.length, 1);
    });

    test('getCatchMap pads to 5 rows when fewer catches exist', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid')).thenReturn([
        makeRow({'field_one': 'a', 'field_two': 'b'}),
      ]);

      final result = viewModel.getCatchMap();

      expect(result.length, 5);
    });

    test('getCatchMap returns 5 rows when exactly 5 catches exist', () {
      final rows = List.generate(5, (i) => makeRow({'field_one': '$i', 'field_two': '$i'}));

      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid')).thenReturn(rows);

      final result = viewModel.getCatchMap();

      expect(result.length, 5);
    });

    test('getColumnCount returns correct count', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid')).thenReturn([
        makeRow({'field_one': 'a', 'field_two': 'b'}),
      ]);

      expect(viewModel.getColumnCount(), 2);
    });

    test('getColumnCount caps at 8', () {
      final manyColumns = Map.fromEntries(
        List.generate(10, (i) => MapEntry('field_$i', 'value_$i')),
      );

      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid')).thenReturn([
        makeRow(manyColumns),
      ]);

      expect(viewModel.getColumnCount(), 8);
    });

    test('getColumnName returns correct name', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid')).thenReturn([
        makeRow({'field_one': 'a', 'field_two': 'b'}),
      ]);

      expect(viewModel.getColumnName(0), 'field_one');
      expect(viewModel.getColumnName(1), 'field_two');
    });

    test('getColumnName returns unknown for out of bounds index', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid')).thenReturn([
        makeRow({'field_one': 'a'}),
      ]);

      expect(viewModel.getColumnName(99), 'unknown');
    });

    test('getColumnName uses table attributes when no catches exist', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedBy('test_log', 5, 0, 'rowid')).thenReturn([]);

      expect(viewModel.getColumnName(0), 'field_one');
      expect(viewModel.getColumnName(1), 'field_two');
    });
  });
}