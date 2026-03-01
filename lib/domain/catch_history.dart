import 'package:ui_prototype/infrastructure/catch_history.dart';

class HistoryCatch {
  final CatchHistoryViewModel viewModel;

  HistoryCatch({required this.viewModel});

  dynamic getValue(int catchIndex, int fieldIndex) {
    final map = viewModel.getCatchMap()[catchIndex];
    return map[map.keys.elementAt(fieldIndex)];
  }

  String getColumnName(int fieldIndex) {
    final map = viewModel.getCatchMap()[0];
    return map.keys.elementAt(fieldIndex);
  }
}