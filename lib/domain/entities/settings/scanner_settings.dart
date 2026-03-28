class ScannerSettings {
  final String? targetTable;
  final String? targetColumn;

  const ScannerSettings({this.targetTable, this.targetColumn});

  Map<String, dynamic> toJson() => {
    'targetTable': targetTable,
    'targetColumn': targetColumn,
  };

  factory ScannerSettings.fromJson(Map<String, dynamic> json) {
    return ScannerSettings(
      targetTable: json['targetTable'] as String?,
      targetColumn: json['targetColumn'] as String?,
    );
  }

  ScannerSettings copyWith({
    String? targetTable, 
    String? targetColumn,
    bool clearTargetTable = false,
    bool clearTargetCol = false,
    }) {
    return ScannerSettings(
      targetTable: clearTargetTable ? null : (targetTable ?? this.targetTable),
      targetColumn: clearTargetCol ? null : (targetColumn ?? this.targetColumn),
    );
  }

}