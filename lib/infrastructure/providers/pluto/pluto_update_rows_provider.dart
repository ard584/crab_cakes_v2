import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/pluto/pluto_update_rows_controller.dart';
import 'package:ui_prototype/infrastructure/providers/update_rows_provider.dart';

final plutoUpdateRowsProvider = Provider(
  (ref) => PlutoUpdateRowsController(useCase: ref.watch(updateRowsProvider)),
);
