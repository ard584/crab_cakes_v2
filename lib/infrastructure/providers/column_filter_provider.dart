import 'package:flutter_riverpod/legacy.dart';

// Constants for column filtering
const String kColumnPrefixToHide = '__';

// Provider for whether to hide columns starting with the prefix
final hideDoubleUnderscoreColumnsProvider = StateProvider<bool>((ref) => true);

// Helper function to filter columns based on provider state
List<String> filterColumnsByPrefix(List<String> columns, bool shouldHide) {
  if (!shouldHide) return columns;
  return columns.where((col) => !col.startsWith(kColumnPrefixToHide)).toList();
}