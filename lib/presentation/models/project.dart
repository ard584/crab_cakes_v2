import 'dart:typed_data';

class ProjectModel {
  final Uint8List id;
  final String title;
  final String? description;
  final String dbPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
    required this.id,
    required this.title,
    this.description,
    required this.dbPath,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  String toString() {

    final str = '''
    ID: $id
    Title: $title
    Description: $description
    CreatedAt: $createdAt, UpdatedAt: $updatedAt
    DbPath: $dbPath
    ''';

    return str;
  }
}
