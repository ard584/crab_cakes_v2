import 'package:flutter_riverpod/legacy.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';

final plutoEditedRowsProvider = StateProvider<Map<String, Map<RowIdentifier, PlutoRow>>>(
  (ref) => {},
);
