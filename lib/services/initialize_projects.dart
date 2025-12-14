import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/v7.dart';

// Define constants
const int EXPECTED_VERSION = 1;

class Projects extends Table {
  BlobColumn get id => 
    blob().customConstraint('CHECK(length(id) = 16)')();

  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BlobColumn get createdByDevice => 
    blob().customConstraint('CHECK(length(created_by_device) = 16)')();
  BlobColumn get updatedByDevice => 
    blob().customConstraint('CHECK(length(updated_by_device) = 16)')();
  TextColumn get dbPath => text().unique()();

  @override
  Set<Column> get primaryKey => {id};

}
