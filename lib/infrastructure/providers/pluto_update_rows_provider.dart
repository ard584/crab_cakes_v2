import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/infrastructure/pluto/pluto_update_rows_controller.dart';
import 'package:crab_cakes/infrastructure/providers/update_rows_provider.dart';

final plutoUpdateRowsProvider = Provider(
  (ref) => PlutoUpdateRowsController(useCase: ref.read(updateRowsProvider)),
);
