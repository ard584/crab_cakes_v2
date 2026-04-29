import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/db_mapper/db_mapper.dart';
import 'package:ui_prototype/infrastructure/db_mapper/sqlite_db_mapper.dart';

final dbMapperProvider = Provider<DbMapper>((ref) {
  return SqliteDbMapper();
});