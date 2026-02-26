// Returns a map of the last 5 catches
List<Map<String, dynamic>> getCatchMap() 
{
  List<Map<String, dynamic>> catches = getCatches();
  
  // pad to 5 with empty maps
  while (catches.length < 5) 
  {
    final Map<String, dynamic> emptyMap = {
      for (int i = 0; i < 8; i++) getColumnName(i): '',
    };
    catches.add(emptyMap);
  }

  return catches;
}

// Get names of columns used for empty map filling
String getColumnName(int index) {
  // replace with real column names from database by getting them from the map
  const columns = ['tag', 'ID_DateTime', 'species', 'T_len', 'F_len', 'weight', 'sex', 'mod'];
  return columns[index];
}

List<Map<String, dynamic>> getCatches()
{
  // replace with logic to get map from database
    List<Map<String, dynamic>> catches = 
  [
    {'tag': 1, 'ID_DateTime': '10:00am', 'species': 'FISH', 'T_len': '150', 'F_len': '15', 'weight': 12.0, 'sex': 'F', 'mod': '0'},
    {'tag': 12, 'ID_DateTime': '10:00am', 'species': 'FISH', 'T_len': '150', 'F_len': '15', 'weight': 12.0, 'sex': 'F', 'mod': '0'},
    {'tag': 123, 'ID_DateTime': '10:00am', 'species': 'FISH', 'T_len': '150', 'F_len': '15', 'weight': 12.0, 'sex': 'F', 'mod': '0'},
    {'tag': 1234, 'ID_DateTime': '10:00am', 'species': 'FISH', 'T_len': '150', 'F_len': '15', 'weight': 12.0, 'sex': 'F', 'mod': '0'},
    {'tag': 12345, 'ID_DateTime': '10:00am', 'species': 'FISH', 'T_len': '150', 'F_len': '15', 'weight': 12.0, 'sex': 'F', 'mod': '0'},
    {'tag': 123456, 'ID_DateTime': '10:00am', 'species': 'FISH', 'T_len': '150', 'F_len': '15', 'weight': 12.0, 'sex': 'F', 'mod': '0'},

  ];
  return catches;
}

double getColumnWidth(int columnIndex) {
  final catches = getCatchMap();
  
  double maxWidth = getColumnName(columnIndex).length.toDouble();
  
  for (final row in catches) {
    final value = row[row.keys.elementAt(columnIndex)].toString();
    final width = value.length.toDouble();
    if (width > maxWidth) maxWidth = width;
  }
  
  final result = (maxWidth * 10.0) + 24;
  return result;
}