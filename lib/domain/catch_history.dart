import 'package:ui_prototype/infrastructure/catch_history.dart';

class HistoryCatch {

  dynamic getValue(int catchIndex, int fieldIndex) {
    final map = getCatchMap()[catchIndex];
    return map[map.keys.elementAt(fieldIndex)];
  }

  String getColumnName(int fieldIndex) {
    final map = getCatchMap()[0];
    return map.keys.elementAt(fieldIndex);
  }
}