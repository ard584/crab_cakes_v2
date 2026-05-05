import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:crab_cakes/application/project/use_cases/save_table.dart';
import 'package:crab_cakes/application/active_project_repository.dart';
import 'package:crab_cakes/domain/models/attribute.dart';
import 'package:crab_cakes/domain/models/db_row.dart';
import 'package:crab_cakes/presentation/view_models/project_input.dart';

class MockActiveProjectRepository extends Mock
    implements ActiveProjectRepository {}

class MockTableInput extends Mock implements TableInput {}

void main() {
  late MockActiveProjectRepository mockRepo;
  late SaveTable useCase;

  setUp(() {
    mockRepo = MockActiveProjectRepository();
    useCase = SaveTable(mockRepo);
  });

  group('SaveTable Use Case', () {
    final attributes = {
      "id": AttributeFormField(
        fields: Attribute(
          columnID: 1,
          name: "id",
          dataType: "INTEGER",
          isNotNullable: false,
          isPrimaryKey: true,
        ),
      ),

      "name": AttributeFormField(
        fields: Attribute(
          columnID: 2,
          name: "name",
          dataType: "TEXT",
          isNotNullable: true,
          isPrimaryKey: false,
        ),
      ),
    };

    final testValues = {"id": 1, "name": "maria"};

    test('should call insertRow and return null when no limit is provided', () {
      final tableInput = TableInput(name: 'users', attributes: attributes);
      final result = useCase.call(tableInput);

      // Verify insertRow was called once with correct params
      verify(
        () => mockRepo.insertRow(
          tableName: 'users',
          values: any(named: 'values'),
        ),
      ).called(1);

      // Verify the getRows is never called when no limit passed
      verifyNever(() {
        mockRepo.getRows("users", 0, 0);
      });

      expect(result, isNull);
    });

    test('should call insertRow and return DbRow when limit is provided', () {
      final tableInput = TableInput(name: 'users', attributes: attributes);
      final expectedRows = [DbRow(values: testValues)];

      when(() => mockRepo.getRows("users", 1, 0)).thenReturn(expectedRows);
      final result = useCase.call(tableInput, limit: 1);

      verify(
        () => mockRepo.insertRow(
          tableName: 'users',
          values: any(named: 'values'),
        ),
      ).called(1);

      expect(result, equals(expectedRows));
    });

    test('should call insertRow and return null when offset exceeds rows', () {
      final tableInput = TableInput(name: 'users', attributes: attributes);

      when(() => mockRepo.getRows("users", 1, 1)).thenReturn([]);
      final result = useCase.call(tableInput, limit: 1, offset: 1);

      verify(
        () => mockRepo.insertRow(
          tableName: 'users',
          values: any(named: 'values'),
        ),
      ).called(1);

      expect(result, isEmpty);
    });
  });
}
