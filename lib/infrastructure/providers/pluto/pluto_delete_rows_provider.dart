import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/pluto/pluto_delete_rows_controller.dart';
import 'package:ui_prototype/infrastructure/providers/delete_rows_provider.dart';

final plutoDeleteRowsProvider = Provider(
  (ref) => PlutoDeleteRowsController(useCase: ref.watch(deleteRowsProvider)),
);
