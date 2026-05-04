import 'package:flutter/widgets.dart';

class SaveIntent extends Intent {
  const SaveIntent();
}

class TableSwitchIntent extends Intent {
  final int index;
  const TableSwitchIntent(this.index);
}

class CheckDatabaseIntent extends Intent {
  const CheckDatabaseIntent();
}
