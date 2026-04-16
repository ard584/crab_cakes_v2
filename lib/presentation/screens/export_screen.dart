import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';
import 'package:ui_prototype/infrastructure/providers/export_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {

  String? selectedTable;

  //display name -> actual delimiter value
  final Map<String, String> delimiterOptions = const {
    "Comma Separated": ",",
    "Tab Separated": "\t",
    "Semicolon Separated": ";",
    "Pipe Separated": "|"
  };

  String selectedDelimiterLabel = "Comma Separated";

  @override
  Widget build(BuildContext context) {

    final exportUseCase = ref.watch(exportDataUsecaseProvider);
    final baseTablesAsync = ref.watch(exportBaseTablesProvider);
    final db = ref.watch(activeDatabaseConnectionProvider);

    final delimiter = delimiterOptions[selectedDelimiterLabel]!;

    final canExport = exportUseCase != null && selectedTable != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: <Widget>[

              SimpleTable(
                headers: ['H1', 'H2', 'H3'],
                data: [
                  ['Data1', 'Data2', 'Data3'],
                  ['Data4', 'Data5', 'Data6'],
                  ['Data7', 'Data8', 'Data9'],
                ],
              ),

              const SizedBox(height: 20),

              FloatingActionButton.extended(
                onPressed: !canExport
                    ? null
                    : () async {
                        try {
                          await exportUseCase.execute(selectedTable!, delimiter);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Export complete: $selectedTable',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Export failed: $e'),
                              ),
                            );
                          }
                        }
                      },
                label: const Text('Export to File'),
                icon: const Icon(Icons.file_download),
              ),

              const SizedBox(height: 20),

              // ---------- BASE TABLE DROPDOWN ----------
              baseTablesAsync.when(
                data: (tables) {

                  //auto select the first table if none selected
                  if (tables.isNotEmpty && selectedTable == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          selectedTable = tables.first;
                        });
                      }
                    });
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Base Table",
                      border: OutlineInputBorder(),
                    ),
                    value: tables.contains(selectedTable) ? selectedTable : null,
                    items: tables.map((table) {
                      return DropdownMenuItem<String>(
                        value: table,
                        child: Text(table),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTable = value;
                      });
                    },
                  );
                },

                loading: () => const CircularProgressIndicator(),

                error: (error, stack) => Text("Error loading tables: $error"),
              ),

              const SizedBox(height: 20),

              // ---------- DELIMITER DROPDOWN ----------
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Delimiter",
                  border: OutlineInputBorder(),
                ),
                value: selectedDelimiterLabel,
                items: delimiterOptions.keys.map((label) {
                  return DropdownMenuItem<String>(
                    value: label,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedDelimiterLabel = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> data;

  const SimpleTable({super.key, required this.headers, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        // Set the border style for the entire table
        border: TableBorder.all(
          color: Colors.grey.shade300,
          width: 1.0,
          borderRadius: BorderRadius.circular(8.0),
        ),
        // ColumnWidths can be used to control how columns take space
        columnWidths: const {
          // You can set the first column (index 0) to be a fixed width
          0: IntrinsicColumnWidth(),
          // Or let others flex to take available space
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
        children: [
          // 1. Header Row
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // Light background for the header
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8.0),
              ),
            ),
            children: headers
                .map((header) => _buildTableCell(header, isHeader: true))
                .toList(),
          ),

          // 2. Data Rows
          ...data
              .map(
                (row) => TableRow(
                  children: row
                      .map((cellData) => _buildTableCell(cellData))
                      .toList(),
                ),
              )
        ],
      ),
    );
  }

  // Helper method to build a standardized table cell
  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 16 : 14,
          color: isHeader ? Colors.black : Colors.grey.shade700,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }
}