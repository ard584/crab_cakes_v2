class ExportSettings {
  final String? baseTable;
  final String? delimiter;

  ExportSettings({
    this.baseTable,
    this.delimiter,
  });

  Map<String, dynamic> toJson() => {
    'baseTable': baseTable,
    'delimiter': delimiter,
  };

  factory ExportSettings.fromJson(Map<String, dynamic> json) {
    return ExportSettings(
      baseTable: json['baseTable'] as String?,
      delimiter: json['delimiter'] as String?,
    );
  }

  ExportSettings copyWith({
    String? baseTable,
    String? delimiter,
    bool clearBaseTable=false,
    bool clearDelimiter=false,
  }) {
    return ExportSettings(
      baseTable: clearBaseTable ? null : (baseTable ?? this.baseTable),
      delimiter: clearDelimiter ? null : (delimiter ?? this.delimiter),
    );
  }

  factory ExportSettings.empty() {
    return ExportSettings(baseTable: null, delimiter: null);
  }
}