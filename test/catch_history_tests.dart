import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_prototype/application/active_project_repository.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/domain/models/attribute.dart';
import 'package:ui_prototype/domain/models/db_row.dart';
import 'package:ui_prototype/infrastructure/catch_history.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class MockActiveProjectRepository extends Mock
    implements ActiveProjectRepository {}

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

  // Schema with created_at_time
  final schemaWithTime = DbTable(
    name: 'test_log',
    columns: [
      DbColumn(name: 'field_one', type: 'TEXT', nullable: true, primaryKey: false),
      DbColumn(name: 'field_two', type: 'TEXT', nullable: true, primaryKey: false),
      DbColumn(name: 'created_at_time', type: 'TEXT', nullable: true, primaryKey: false),
    ],
  );

  setUp(() {
    mockRepo = MockActiveProjectRepository();
    table = TableInput(name: 'test_log', attributes: attributes);
    viewModel = CatchHistoryViewModel(db: mockRepo, table: table);
  });

  group('CatchHistoryViewModel', () {

    test('getCatches uses getRows when no created_at_time column', () {
      final rows = [DbRow(values: {'field_one': 'a', 'field_two': 'b'})];

      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedId('test_log', 5, 0)).thenReturn(rows);

      final result = viewModel.getCatches();

      verify(() => mockRepo.getRowsOrderedId('test_log', 5, 0)).called(1);
      verifyNever(() => mockRepo.getRowsOrdered('test_log', 5, 0));
      expect(result.length, 1);
    });

    test('getCatches uses getRowsOrdered when created_at_time column exists', () {
      final rows = [DbRow(values: {'field_one': 'a', 'field_two': 'b', 'created_at_time': '2026-01-01 10:00:00'})];

      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithTime);
      when(() => mockRepo.getRowsOrdered('test_log', 5, 0)).thenReturn(rows);

      final result = viewModel.getCatches();

      verify(() => mockRepo.getRowsOrdered('test_log', 5, 0)).called(1);
      verifyNever(() => mockRepo.getRowsOrderedId('test_log', 5, 0));
      expect(result.length, 1);
    });

    test('getCatchMap pads to 5 rows when fewer catches exist', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedId('test_log', 5, 0)).thenReturn([
        DbRow(values: {'field_one': 'a', 'field_two': 'b'}),
      ]);

      final result = viewModel.getCatchMap();

      expect(result.length, 5);
    });

    test('getCatchMap returns 5 rows when exactly 5 catches exist', () {
      final rows = List.generate(5, (i) => DbRow(values: {'field_one': '$i', 'field_two': '$i'}));

      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedId('test_log', 5, 0)).thenReturn(rows);

      final result = viewModel.getCatchMap();

      expect(result.length, 5);
    });

    test('getColumnCount returns correct count', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedId('test_log', 5, 0)).thenReturn([
        DbRow(values: {'field_one': 'a', 'field_two': 'b'}),
      ]);

      expect(viewModel.getColumnCount(), 2);
    });

    test('getColumnCount caps at 8', () {
      final manyColumns = Map.fromEntries(
        List.generate(10, (i) => MapEntry('field_$i', 'value_$i')),
      );

      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedId('test_log', 5, 0)).thenReturn([
        DbRow(values: manyColumns),
      ]);

      expect(viewModel.getColumnCount(), 8);
    });

    test('getColumnName returns correct name', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedId('test_log', 5, 0)).thenReturn([
        DbRow(values: {'field_one': 'a', 'field_two': 'b'}),
      ]);

      expect(viewModel.getColumnName(0), 'field_one');
      expect(viewModel.getColumnName(1), 'field_two');
    });

    test('getColumnName returns unknown for out of bounds index', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedId('test_log', 5, 0)).thenReturn([
        DbRow(values: {'field_one': 'a'}),
      ]);

      expect(viewModel.getColumnName(99), 'unknown');
    });

    test('getColumnName uses table attributes when no catches exist', () {
      when(() => mockRepo.getTableSchema('test_log')).thenReturn(schemaWithoutTime);
      when(() => mockRepo.getRowsOrderedId('test_log', 5, 0)).thenReturn([]);

      expect(viewModel.getColumnName(0), 'field_one');
      expect(viewModel.getColumnName(1), 'field_two');
    });
  });
}